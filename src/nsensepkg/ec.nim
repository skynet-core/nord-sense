import posix, bitops
  
const
  EC_SC = 0
  EC_DATA = 1
  OBF = 1 shl 0
  IBF = 1 shl 1
  RD_EC = 0x0080
  WR_EC = 0x0081
  BE_EC = 0x0082
  BD_EC = 0x0083
  QU_EC = 0x0084
  sleepDelayMicroSec = 1_000

type
  IOPermDefect* = 
    object of CatchableError
  ECPollDefect* = 
    object of CatchableError
  ECInitDefect* =
    object of CatchableError
  EC* = 
    object
      init: bool
      port:  array[2,cuint]


proc errnoString(): string = 
  let cs = strerror(errno)
  let cl = cs.len
  result = newString(cl)
  copyMem(addr result[0],cs,cl)
  cs.dealloc

proc ioperm (start: uint32, to: uint32, enable: int16): int16 {. importc, header:"<sys/io.h>" .}

proc inb(port: cuint): cuchar {. importc, header: "<sys/io.h>" .}

proc outb(val: cushort, port: cuint) {. importc, header: "<sys/io.h>" .}
  


proc newEC*(cmdport: uint16, dataport: uint16): EC {.raises: [IOPermDefect] .} =
  result = EC()
  var r = ioperm(cmdport,1,1)
  if r != 0:
    raise IOPermDefect.newException("ioperm cmdport exception: " & errnoString())
  result.port[EC_SC] = cmdport

  r = ioperm(dataport,1,1)
  if r != 0:
    raise IOPermDefect.newException("ioperm cmdport exception: " & errnoString())
  result.port[EC_DATA] = dataport
  result.init = true


method rwait(self: EC, m: uint8, value: uint8): void {. raises: [ECPollDefect], base .} =
  for i in 0..<1000:
    var r = uint8(inb(self.port[EC_SC]))
    if bitand(r, m) == value:
      return
    discard usleep(sleepDelayMicroSec) # 1 microsecond

  raise ECPollDefect.newException("max wait timeout 1ms reached")
    
method rread*(self: EC, address: uint8): uint8 {. raises: [ECPollDefect, ECInitDefect], base .} =
  if not self.init:
      raise ECInitDefect.newException("controller object was not initiated")

  rwait(self, IBF, 0) # wait input buffer clear
  outb(RD_EC, self.port[EC_SC]) # send command
  rwait(self, IBF, 0) # wait it is accpeted
  outb(address, self.port[EC_DATA]) # set address
  rwait(self, OBF, 1) # wait for data come onto register
  result = uint8(inb(self.port[EC_DATA])) # grab data from register
  rwait(self,OBF, 0) # wait register clear


method rwrite*(self: EC, address: uint8, value: uint8): void {. raises: [ ECPollDefect, ECInitDefect ], base .} = 
  if not self.init:
    raise ECInitDefect.newException("controller object was not initiated")
  
  rwait(self, IBF, 0)
  outb(WR_EC, self.port[EC_SC])
  rwait(self, IBF, 0)
  outb(address, self.port[EC_DATA])
  rwait(self, IBF, 0)
  outb(value, self.port[EC_DATA])
  rwait(self, IBF, 0)