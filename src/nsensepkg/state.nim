import math

type
    ZoneState* = ref object
        currentTemp:        uint8
        sumTemp:            int
        sumNum:             int
        fanLevels*:         seq[int]

proc initZoneState*(numFans:int): ZoneState = 
    result = ZoneState(sumTemp: 0, sumNum:0, fanLevels: newSeq[int](numFans))
    for i in 0..result.fanLevels.high:
        result.fanLevels[i] = -1

method `currentTemp=`*(self: var ZoneState, temp: uint8): void  {. base .} =
    # set current temp and updates internal state
    self.currentTemp = temp
    self.sumTemp += int(temp)
    self.sumNum += 1

method currentTemp*(self: ZoneState): uint8 {. base .} =
    # returns current temperature
    result = self.currentTemp   

method averageTemp*(self: ZoneState): uint8 {. base .} =
    # returns average temperature for sumNum ticks
    let avg = uint(round(self.sumTemp/self.sumNum))
    if avg > uint(0xff):
        result = 0xff
    else:
        result = uint8(avg)

method ticks*(self: ZoneState): int {. base .} = 
    result = self.sumNum

method reset*(self: var ZoneState): void {. base .} =
    self.currentTemp = 0
    self.sumNum = 0
    self.sumTemp = 0

method deepReset*(self: var ZoneState): void {. base .} =
    self.reset()
    for i in 0..self.fanLevels.high:
        self.fanLevels[i] = -1


proc resetZones*(zones: var seq[ZoneState]): void =
    for i in 0..zones.high:
        zones[i].reset()


proc resetZonesDeep*(zones: var seq[ZoneState]): void = 
    for i in 0..zones.high:
        zones[i].deepReset()