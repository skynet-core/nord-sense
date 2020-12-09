import os

var params = commandLineParams()
exec "sudo " & getCurrentDir() & "/res/install/linux.sh " & params[1]