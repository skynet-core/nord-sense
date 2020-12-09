#!/bin/sh

set -e
set -x

echo "Nord Sense Linux preremove.sh script"
executable=(readlink /proc/1/exe)
bin=${executable##*/}
if [ "$bin" = "systemd" ]; then
    if ! which systemctl 2>&1 1>/dev/null; then
        echo "ERROR: systemctl tool is not in PATH" 1>&2
        exit 1
    fi

    if systemctl status nsense 2>&1 1>/dev/null; then
        systemctl stop nsense
    fi

    rm -f /etc/systemd/system/npsense*.service
    systemctl daemon-reload
    systemctl disable nsense
    systemctl disable nsense-sleep
else
    echo "ERROR: your init system seems isn't supported" 1>&2
    exit 1
fi

echo "INFO: Nord Sense was sucessfully removed"
