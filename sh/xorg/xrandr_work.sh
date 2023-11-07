#!/bin/sh
# env OUTS declared in pam env /etc/environment
# make sure nouveau not blacklisted, usually in /usr/lib/modprobe.d/nvidia.conf
# https://wiki.archlinux.org/index.php/Nouveau
OUT0="HDMI1"
OUT1="HDMI2"
xrandr --output "$OUT1" --rate 60 --pos 1600x0 --primary
xrandr --output "$OUT0" --rate 60 --pos 0x0

