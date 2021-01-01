import sequtils
import tables
import strutils
# Package

version       = "0.6.0"
author        = "Skynet Core"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nsense","nsensepkg/cli/nsensectl"]


# Dependencies

requires "nim >= 1.4.0"
requires "yaml#head"
requires "argparse >= 2.0.0"
requires "https://github.com/skynet-core/nim-smbios#0.1.3"

task nsense, "Run nsense service":
    exec "nim --out:/tmp/nsense r src/nsense.nim -p /tmp/nsense.pid -f"

task static, "Build static musl binaries":
    let dir = getCurrentDir()
    exec "docker run --rm -v " & dir &
        ":/home/nim/nord-sense smartcoder/nim:v1.4 bash -c '" &
        "sudo apk update && sudo apk upgrade && sudo apk add sqlite-static &&" &
        " cd /home/nim/nord-sense && nimble build --gcc.exe:gcc --gcc.linkerexe:gcc" &
        " --passL:-static --dynlibOverride:libsqlite3.so --passL:/usr/lib/libsqlite3.a -d:release --opt:size -y'"

task package, "Create packages":
    let dir = getCurrentDir()
    staticTask()
    let (tag, exitCode) = gorgeEx("sh","git describe --tags `git rev-list --tags --max-count=1` | tr -d 'v'")
    if exitCode != 0:
        quit("failed to get last git tag",exitCode)
    exec "cat ./nfpm.template.yaml | sed 's|@version|" & tag & "|g' > nfpm.yaml"
    exec "rm -f *.deb"
    exec "docker run --rm -v " & dir & ":/home/nim/nord-sense smartcoder/nfpm:v1.5 'cd /home/nim/nord-sense && nfpm pkg -f ./nfpm.yaml -p deb'"
    exec "rm -f *.rpm"
    exec "docker run --rm -v " & dir & ":/home/nim/nord-sense smartcoder/nfpm:v1.5 'cd /home/nim/nord-sense && nfpm pkg -f ./nfpm.yaml -p rpm'"
    echo "packages were successfully created"
    exec "rm ./nfpm.yaml"


task setup, "Install nsense service":
    
    let dir = getCurrentDir()
    var 
        keys = newSeq[string]()
        vals = newSeq[string]()
    for i in countup(0, paramCount(), 1):
        let parts = paramStr(i).split(":")
        keys.add(parts[0])
        if parts.len > 1:
            vals.add(parts[1])
        else:
            vals.add("") 
    let argsTable = zip(keys,vals).toTable
    if not argsTable.contains("--configName"):
        echo "Error: --configName missed"
        quit(1)

    if argsTable.getOrDefault("--configName").strip().len == 0:
        echo "Error: --configName value is empty string"
        quit(1)

    exec selfExe() & " " & dir & "/res/install/" & hostOS & ".nims " & argsTable["--configName"]

task purge, "Removing service from system":
    let dir = getCurrentDir()
    exec selfExe() & " " & dir & "/res/uninstall/" & hostOS & ".nims"

task clean, "clean artifacts":
    exec "rm -rf nsensepkg nsense tests/test1 here.pid"
    echo "Done"
