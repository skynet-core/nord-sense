# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.
import os
import posix
import strutils
import strformat
import parseutils
import sets
import argparse
import bitops
import math
import yaml
import selectors

import psensepkg/port
import psensepkg/config

type 
  Cmd = enum
    Reload, Stop, Timer

proc killService(pid: uint): void = 
  discard kill(cint(pid), SIGKILL)
  var res: cint
  if 0 > waitpid(Pid(pid), res, bitor(WUNTRACED, WCONTINUED)):
    stderr.writeLine("error: failed to kill existent service")
    quit(1)

when isMainModule:
  let pid = getCurrentProcessId()
  var p = newParser("psense"):
    option("-c","--config", default = some("config.yaml"), help = "config file's path")
    option("-p","--pidfile",default = some("/run/psense.pid"), help = "pifile's path")
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
  let s = newFileStream(opts.config,fmRead)
  var cfg = Config()
  load(s, cfg)
  s.close()
  # now we have config read
  
  # register some events handlers
  let 
    sel = newSelector[int]()
    sTerm = sel.registerSignal(SIGTERM,0)
    sHup = sel.registerSignal(SIGHUP,0)
    sTime = sel.registerTimer(1000, oneshot = false,0) # once per second
    ctrl = newPort(cfg.cmdPort, cfg.dataPort)
  
  var zones = newSeq[array[2,int]](cfg.zones.len)
  while true:
    for ev in sel.select(-1):
        if ev.fd == sTerm:
            quit(0)
        if ev.fd == sHup:
            # reload config in main loop and send update to worker
            let s = newFileStream(opts.config, fmRead)
            load(s, cfg)
            s.close()
        if ev.fd == sTime:
            ## iterate through zones and compare temp with level bounds
            for (index, zone) in cfg.zones.pairs:
              let temp = ctrl.recv(zone.address)
              zones[index][1] += int(temp)
              zones[index][0] += 1
              echo fmt"{zone.name}: curr: {temp} avg: {round(zones[index][1]/zones[index][0]):0.2F}"
              # reset at the and
              if zones[index][0] > 3:
                zones[index][1] = 0
                zones[index][0] = 0