import yaml,sequtils ,math ,algorithm ,strformat

type
  Level*     = object
    enterTemp*:         float64
    freq*:              float64
  FanConfig* = object
    info*:              string
    index*:             int
    temp*:              uint8 # when enable
    rpm*:               uint8 # fan speed


const defaultLevels = (1..4).toSeq.map(proc (x: int): Level =
  let m = float64(x) * 25
  result = Level(enterTemp: m, freq: m))

type
  Settings*  = object
    maxTemp* {. defaultVal: 0x64 .}:            uint8
    levels* {. defaultVal: defaultLevels .}:    seq[Level]
  Fan*       = object
    name*:                                      string
    address*:                                   uint8
    auto* {. defaultVal: 0x04 .}:               uint8
    manual* {. defaultVal: 0x14 .}:             uint8
    wrReg*:                                     uint8
    rdReg*:                                     uint8
    min* {. defaultVal: 0xff .}:                uint8
    max* {. defaultVal: 0x00 .}:                uint8
    levels* {. defaultVal: newSeq[Level]() .}:  seq[Level] 
    normLevels* {. transient .}:                seq[FanConfig]
  Zone*      = object
    name*:                                      string
    address*:                                   uint8
    min* {. defaultVal: 0x00 .}:                uint8
    max* {. defaultVal: 0xff .}:                uint8
    fans* {. defaultVal: newSeq[Fan]() .}:      seq[Fan]
    levels* {. defaultVal: newSeq[Level]() .}:  seq[Level]
  Config*    = object
    name*:                                      string
    pollTickMs* {. defaultVal: 500 .}:          int
    reaction* {. defaultVal: 7 .}:              int
    cmdPort*:                                   uint8
    dataPort*:                                  uint8 
    zones*:                                     seq[Zone]
    config*:                                    Settings


proc `<`(a,b: FanConfig): bool = 
  result = a.temp < b.temp

proc levelConfig*(fan: Fan, temp: uint8): Option[FanConfig] =
  var 
    foundAt = -1
    levels = fan.normLevels
  levels.sort(Ascending)
  for (index, level) in levels.pairs:
    if level.temp <= temp:
      foundAt = index
    else:
      break

  if foundAt < 0:
    # continue in auto mode
    result = none[FanConfig]()
    return

  result = some[FanConfig](levels[foundAt])
  

proc fanConfig(fan: ptr Fan, zone: Zone, config: Settings): void =
  ## gerates set of calculated values per unique fan
  let 
    zoneTempRange = int16(zone.max) - int16(zone.min)
    rpmRange = int16(fan.max) - int16(fan.min)

  var tempRange = int16(config.maxTemp)
  if tempRange > zoneTempRange:
    tempRange = zoneTempRange

  let 
    rpmPoint = float64(rpmRange) * 1e-2
    tempPoint = float64(tempRange) * 1e-2

  var levels: seq[Level] 
  # if fan has own specialized config use it
  if fan.levels.len > 0:
    levels = fan.levels
  elif zone.levels.len > 0:
    # if zone has its specialized config use it
    levels = zone.levels
  else:
    levels = config.levels

  var list = newSeq[FanConfig](levels.len)
  
  for (index, level) in levels.pairs:
    var 
      rpm: uint8
      temp: uint8
      rpmDirt = level.freq * rpmPoint
      tempDirt = level.enterTemp * tempPoint
    # in case reverse values
    if rpmDirt < 0:
      rpm = uint8(floor(rpmDirt))
    else:
      rpm = uint8(round(rpmDirt))
        # in case reverse values
    if tempDirt < 0:
      temp = uint8(floor(tempDirt))
    else:
      temp = uint8(round(tempDirt))

    list[index].info = fmt"L:{index+1} T:{level.enterTemp:0.1F} F:{level.freq:0.1F} ({temp:#02X} {rpm:#02X})"
    list[index].temp = temp
    list[index].rpm = rpm
    list[index].index = (index + 1)
  # save levels
  fan.normLevels = list

proc normalize*(cfg: var Config): void  =
  for zone in cfg.zones:
    for i in 0..zone.fans.high:
      var fanPtr = zone.fans[i].unsafeAddr
      fanConfig(fanPtr, zone, cfg.config)


proc ready*(cfg: Config): bool =
  return cfg.dataPort != 0 and cfg.cmdPort != 0