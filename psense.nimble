# Package

version       = "0.1.0"
author        = "Skynet Core"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["psense","psensepkg/cli/psensectl"]


# Dependencies

requires "nim >= 1.4.0"
requires "yaml#head"
requires "argparse >= 1.0.0"

task clean, "clean artifacts":
    exec "rm -f psense"
    exec "rm -rf psensepkg"
    echo "Done"