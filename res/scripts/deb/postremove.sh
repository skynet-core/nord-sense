#!/bin/sh

set -e
set -x

echo "Nord Sense Linux postremove.sh script"

root="/opt/nsense"
share="/usr/share"
executable=$(readlink /proc/1/exe)
bin=${executable##*/}

if [ "$bin" = "systemd" ]; then
    if [ -d $root ]; then
        rm -rf $root
    fi
else
    echo "ERROR: your init system seems isn't supported" 1>&2
    exit 1
fi

echo "INFO: Nord Sense was sucessfully removed"
