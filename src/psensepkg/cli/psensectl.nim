import os
import strutils
import strformat
import parseutils
import argparse
import ../port


when isMainModule:
    let ec = newPort(0x66,0x62)
    var p = newParser("psensectl"):
        command("port"):
            flag("-w","--write")
            flag("-r","--read")
            arg("params",nargs = -1)
            run:
                if opts.write:
                    var address, value: uint8
    
                    discard parseHex(opts.params[0], address)
                    discard parseHex(opts.params[1], value)
                    ec.send(address, value)
                elif opts.read:
                    var address: uint8
                    discard parseHex(opts.params[0], address)
                    let val = ec.recv(address)
                    echo fmt"{val:#X}"                   
                else:
                    echo "error: port mode: action unknown"
                    quit(1)

    p.run(commandLineParams())