import argparse, os, strutils ,parseutils
import tables, yaml

import ./config

proc loadConfig*(path: string): Config = 
    if not fileExists(path):
        stderr.writeLine("error: config file '" & path & "' doesn't exist")
        quit(1)

    let s = newFileStream(path,fmRead)
    result = Config()
    load(s, result)
    s.close()
    result.normalize()