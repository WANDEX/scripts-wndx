#!/bin/sh

if [ "$1" = "root" ]; then
    logfile=/var/log/Xorg.0.log
elif [ -z "$1" ]; then
    logfile="${XDG_DATA_HOME}/xorg/Xorg.0.log"
else
    logfile="$1"
fi

loading=$(  grep "Loading"   "$logfile")
unloading=$(grep "Unloading" "$logfile")

printf "%s\n\n%s\n\n" "$loading" "$unloading"

echo "$loading" | sed -n 's@.*/\(.*\)_drv.so@\1@p'
echo # New Line

sed -n 's@.* Loading .*/\(.*\)_drv.so@\1@p' "$logfile" |
    while read -r driver; do
        if ! grep -q "Unloading $driver" "$logfile"; then
            echo "$driver"
            break
        fi
    done

