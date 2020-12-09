# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.
import argparse, os, posix, strutils, strformat
import tables, bitops,yaml ,selectors, times

import nsensepkg/port
import nsensepkg/config
import nsensepkg/misc
import nsensepkg/state

proc killService(pid: uint): void = 
  discard kill(cint(pid), SIGKILL)
  var res: cint
  discard waitpid(Pid(pid), res, bitor(WUNTRACED, WCONTINUED))

proc initZones(zones: seq[Zone]): seq[ZoneState] = 
  result = newSeq[ZoneState](zones.len)
    # initial zone config
  for i in 0..zones.high:
    result[i] = initZoneState(zones[i].fans.len)

when isMainModule:
  let pid = getCurrentProcessId()
  var p = newParser("nsense"):
    option("-c","--config", default = some("config.yaml"), help = "config file's path")
    option("-p","--pidfile",default = some("/run/nsense.pid"), help = "pifile's path")
    flag("-f","--force", help = "force daemon start")

  let opts = p.parse(commandLineParams())
  if not os.fileExists(opts.config):
    stderr.writeLine(fmt"file {opts.config} doesn't exist")
    quit(1)
  if os.fileExists(opts.pidfile):
    if not opts.force:
      stderr.writeLine(fmt"pidfile {opts.pidfile} alredy exists, please kill owner process and remove it before or use --force flag")
      quit(1)
    let raw = readFile(opts.pidfile)
    let spid = parseUInt(raw.strip())
    killService(spid)
    discard truncate(opts.pidfile,0)
  
  # here we can lock
  writeFile(opts.pidfile, $pid & "\n")
  var cfg = loadConfig(opts.config)
  # now we have config read
  
  # register some events handlers
  let 
    sel = newSelector[int]()
    sKill = sel.registerSignal(SIGKILL, 0)
    sTerm = sel.registerSignal(SIGTERM, 0)
    sHup: int = sel.registerSignal(SIGHUP, 0)
    sPause = sel.registerSignal(SIGTSTP, 0)
    sCont = sel.registerSignal(SIGCONT, 0)
    ctrl = newPort(cfg.cmdPort, cfg.dataPort)

  
  var
    sTime = sel.registerTimer(int(cfg.pollTickMs), oneshot = false,0) # once per second 
    zones = initZones(cfg.zones) # initial zone config


  let 
    loadAndReset = proc(): void =
      cfg = loadConfig(opts.config)
      resetZonesDeep(zones)
    unregisterTimerAndReset = proc(): void = 
      sel.unregister(sTime)
      resetZonesDeep(zones)

  var actionSwitch = {
    sHup: (proc(timeStr: string):void = 
      loadAndReset()
      stderr.writeLine(fmt"{timeStr}: SIGHUP received. Updating configuration ...")),

    sCont: (proc(timeStr: string):void = 
      loadAndReset()
      sTime = sel.registerTimer(int(cfg.pollTickMs), oneshot = false,0)
      stderr.writeLine(fmt"{timeStr}: SIGCONT received. Continue watching ...")),
    
    sPause: (proc(timeStr: string):void = 
      unregisterTimerAndReset()
      stderr.writeLine(fmt"{timeStr}: SIGTSTP received. Going idle ...")),

    sTerm: (proc(timeStr: string):void = 
      unregisterTimerAndReset()
      stderr.writeLine(fmt"{timeStr}: SIGTERM received. Quiting ...")
      quit(0)),

    sKill: (proc(timeStr: string):void = 
      unregisterTimerAndReset()
      stderr.writeLine(fmt"{timeStr}: SIGKILL received. Quiting ...")
      quit(0)),
    
    sTime: (proc(timeStr: string): void = 
      ## iterate through zones and compare temp with level bounds
      for (i, zone) in cfg.zones.pairs:
        var state = zones[i]
        state.currentTemp = ctrl.recv(zone.address)
        let avgTemp = state.averageTemp
        if state.ticks > int(cfg.reaction):
          for (j, fan) in zone.fans.pairs:
            #do we need to enable this fan?
            let prevLevel = state.fanLevels[j]
            let cfg: Option[FanConfig] = fan.levelConfig(avgTemp)
            if cfg.isSome():
              if prevLevel != cfg.unsafeGet.index:
                if prevLevel < 0:
                  ctrl.send(fan.address, fan.manual)
                ctrl.send(fan.wrReg, cfg.unsafeGet.rpm)
                state.fanLevels[j] = cfg.unsafeGet.index
                stderr.writeLine(fmt"{timeStr}: [{zone.name} {fan.name}] -> [ {cfg.unsafeGet.info} ]")
            else:
                if prevLevel > 0:
                  ctrl.send(fan.address, fan.auto)
                  stderr.writeLine(fmt"{timeStr}: [{zone.name} {fan.name}] -> [ auto ]")
                state.fanLevels[j] = -1
          state.reset()
      )
    }.toTable

  while true:
      for ev in sel.select(-1):
          if actionSwitch.hasKey(ev.fd):
            let timeStr = now().format("dd-MM-yyyy HH:mm:ss")
            actionSwitch[ev.fd](timeStr)

  stderr.writeLine("quit unexpectedly...")
  quit(1)