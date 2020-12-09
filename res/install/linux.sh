#!/bin/sh

set -e
set -x

echo "nsense Linux installer script"

short=0
if [ ! -f "./configs/$1" ]; then
    if [ ! -f "./configs/$1" ]; then
        echo "Error: neither $1 or $1.yaml were fond in ./configs folder"
        exit 1
    else
        short=1
    fi
fi

if [ ! -d /opt/nsense/bin ]; then
    mkdir -p /opt/nsense/bin
fi

if [ ! -d /opt/nsense/etc ]; then
    mkdir -p /opt/nsense/etc
fi

if systemctl status nsense 2>&1 1>/dev/null; then
    systemctl stop nsense
fi

cp -f ./nsense /opt/nsense/bin/
cp -f ./nsensepkg/cli/nsensectl /opt/nsense/bin/
if $short; then
    cp -f "./configs/$1.yaml" /opt/nsense/etc/config.yaml
else
    cp -f "./configs/$1" /opt/nsense/etc/config.yaml
fi

cp -f ./res/service/systemd/* /etc/systemd/system/

systemctl daemon-reload
systemctl enable nsense --now
systemctl enable nsense-sleep
