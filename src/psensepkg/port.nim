import ec

type 
    Port* = ref object of RootObj
        controller: EC

proc newPort*(cmdPort: uint8,dataPort: uint8): Port = 
    result = Port(controller: newEc(cmdPort, dataPort))

method send*(port: Port, address: uint8, value: uint8): void {. raises: [ ECPollDefect, ECInitDefect ], base .} =
    port.controller.rwrite(address, value)

method recv*(port: Port, address: uint8): uint8 {. raises: [ ECPollDefect, ECInitDefect ], base .} =
    result = port.controller.rread(address)