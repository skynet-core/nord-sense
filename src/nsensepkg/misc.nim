import argparse, os, strutils ,parseutils, posix, bitops
import tables, yaml

import config, state

const 
  dbFileName = "settings.db"
  shareConfigsDir = "/usr/share/configs"
  configFileName = "config"
  configFileFolder = "/etc/nsense"
  replacements = [(" ",""),("_",""),("-", "")]


proc loadConfig*(path: string): Config = 
    if not fileExists(path):
        stderr.writeLine("error: config file '" & path & "' doesn't exist")
        quit(1)

    let s = newFileStream(path,fmRead)
    result = Config()
    load(s, result)
    s.close()
    result.normalize()

proc defaultConfig*(name: string): Config =
    result = Config(name: name, pollTickMs: 500, reaction: 7)
    result.config.maxTemp = 0x64
    result.normalize()


proc killService*(pid: uint): void = 
  discard kill(cint(pid), SIGKILL)
  var res: cint
  discard waitpid(Pid(pid), res, bitor(WUNTRACED, WCONTINUED))

proc readPid*(filePath: string): uint {. gcsafe .} =
    let raw = readFile(filePath)
    result = parseUInt(raw.strip())

proc initZones*(zones: seq[Zone]): seq[ZoneState] = 
  result = newSeq[ZoneState](zones.len)
    # initial zone config
  for i in 0..zones.high:
    result[i] = initZoneState(zones[i].fans.len)

proc resolveConfig*(wd: string, model: string, configFile: string): string =
    if fileExists(configFile):
        return configFile

    let configDir = splitFile(configFile).dir
    if dirExists(configDir):
      for file in walkDir(configDir):
        if file.path.splitPath().tail.split('.')[0] == configFileName:
          return file.path
    else:
      try:
        # create dir for config file
        createDir(configDir)
      except OSError:
        quit("failed to create '" & configDir & "' :" & getCurrentExceptionMsg(),-1)
      # try to find something from ready to use shared configs
      let
        match = model.multiReplace(replacements).toUpper()
      for file in walkDir(joinPath(wd, shareConfigsDir)):
        let configFile = file.path.splitFile.name.
            split('.')[0].multiReplace(replacements).toUpper()
        if configFile == match:
          let dest = joinPath(configDir, configFileName)
          try:
            copyFile(file.path, dest)
            return dest
          except OSError:
            quit("failed to copy '" & configFile & "' into '" & dest & "': " & getCurrentExceptionMsg(),-1)
    return ""

proc configFilePath*(wd: string): string =
    result = joinPath(wd, configFileFolder, configFileName)

proc dbFilePath*(wd: string): string =
    result = joinPath(wd, dbFileName)