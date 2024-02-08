#!/bin/bash
# requires sudo for updating mirrorlist in '/etc/pacman.d/mirrorlist'

bname="$(basename "$0")"
mlist="/etc/pacman.d/mirrorlist"
mlnew="${mlist}.pacnew"

if sudo reflector -p https --age 24 --fastest 50 --latest 25 --sort rate \
    --download-timeout 5 --save "$mlist"
then
    notify-send -t 0 "🆙[$bname]" "mirrorlist updated"
else
    notify-send -t 0 -u critical "[$bname]" "error"
    exit 1
fi

[ -f "$mlnew" ] || exit 0

if sudo rm -f "$mlnew"
then
    notify-send -t 0 -u low "🆙[$bname]" "rm -f is OK"
else
    notify-send -t 0 -u critical "[$bname]" "rm error"
    exit 2
fi
