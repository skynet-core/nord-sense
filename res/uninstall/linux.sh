#!/bin/sh

set -e
set -x

echo "nsense Linux uninstaller script"

executable=$(readlink /proc/1/exe)
bin=${executable##*/}

if [ "$bin" = "systemd" ]; then
    if systemctl is-active nsense 2>&1 1>/dev/null; then
        systemctl stop nsense
    fi
    systemctl disable nsense
    systemctl disable nsense-sleep

    rm -f /etc/systemd/system/nsense*
else

    echo "ERROR: your init system seems isn't supported" 1>&2
    exit 1
fi

if [ -d /opt/nsense ]; then
    rm -rf /opt/nsense
fi

systemctl daemon-reload
