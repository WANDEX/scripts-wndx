#!/bin/sh

OUT0="HDMI-0"
# OUT1="VGA-0"
OUT2="DVI-D-0"

if [ "$1" = hi ]; then
nvidia-settings --assign CurrentMetaMode="$OUT0: 3840x2160_60 +0+0, $OUT2: 1920x1080_60 +3840+0"
xrandr --output "$OUT2" --primary
else
nvidia-settings --assign CurrentMetaMode="$OUT0: 1920x1080_60 +0+0, $OUT2: 1920x1080_60 +1920+0"
xrandr --output "$OUT2" --primary
fi

# xrandr --output "$OUT0" --pos 0x0    --rate 60
# xrandr --output "$OUT2" --pos 3840x0 --rate 60 --primary

