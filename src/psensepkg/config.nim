import yaml
import sequtils


type
  Level*     = object
    min*:  uint8
    max*:  uint8
    freq*:   uint8

const defaultLevels = (1..4).toSeq.map(proc (x: int): Level = 
  let m = uint8(x) * 25
  result = Level(min: m - 10 ,max: m, freq: m ))

type
  Settings*  = object
    max* {. defaultVal: 0x64 .}:    uint8
    min* {. defaultVal: 0x00 .}:    uint8
    levels* {. defaultVal: defaultLevels .}:     seq[Level]
  Fan*       = object
    name*:       string
    address*:    uint8
    auto* {. defaultVal: 0x04 .}:       uint8
    manual* {. defaultVal: 0x14 .}:     uint8
    wrReg*:      uint8
    rdReg*:      uint8
    min* {. defaultVal: 0xff .}:        uint8
    max* {. defaultVal: 0x00 .}:        uint8
  Zone*      = object
    name*:       string
    address*:    uint8
    min* {. defaultVal: 0x00 .}:        uint8
    max* {. defaultVal: 0xff .}:        uint8
    fans* {. defaultVal: newSeq[Fan]() .}:       seq[Fan]
  Config*    = object
    name*:       string
    cmdPort*:    uint8
    dataPort*:   uint8 
    zones*:      seq[Zone]
    config*:   Settings

