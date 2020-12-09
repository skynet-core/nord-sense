#!/bin/sh

set -e
set -x

echo "nsense Linux uninstaller script"
systemctl stop nsense
systemctl disable nsense
systemctl disable nsense-sleep
rm -f /etc/systemd/system/nsense*

if [ -d /opt/nsense ]; then
    rm -rf /opt/nsense
fi

systemctl daemon-reload
