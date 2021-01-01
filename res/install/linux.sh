#!/bin/sh

set -e
set -x

echo "nsense Linux installer script"

if [ ! -d /opt/nsense/bin ]; then
    mkdir -p /opt/nsense/bin
fi

if [ ! -d /opt/nsense/etc/nsense ]; then
    mkdir -p /opt/nsense/etc/nsense
fi

if [ ! -d /opt/nsense/usr/share/configs ]; then
    mkdir -p /opt/nsense/usr/share/configs
fi

if systemctl status nsense 2>&1 1>/dev/null; then
    systemctl stop nsense
fi

cp -f ./nsense /opt/nsense/bin/
cp -f ./nsensepkg/cli/nsensectl /opt/nsense/bin/
cp -f ./configs/*.yaml /opt/nsense/usr/share/configs
cp -fr ./res/service /opt/nsense/usr/share/

executable=$(readlink /proc/1/exe)
bin=${executable##*/}

if [ "$bin" = "systemd" ]; then

    if systemctl status nsense 2>&1 1>/dev/null; then
        systemctl stop nsense
    fi

    cp -f ./res/service/systemd/* /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable nsense --now
    systemctl enable nsense-sleep

else
    echo "ERROR: your init system seems isn't supported" 1>&2
    exit 1
fi

echo "INFO: Nord Sense was sucessfully installed"
