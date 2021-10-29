#!/bin/sh
# move mouse to the lower right corner of active window

awin="$(xdotool getactivewindow)"
# sed get first found match and print without match pattern
geometry="$(xdotool getwindowgeometry "$awin" | sed -n "0,/  Geometry: /s///p")"
gx="$(echo "$geometry" | cut -dx -f1)"
gy="$(echo "$geometry" | cut -dx -f2)"
new_x="$((gx-24))"
new_y="$((gy-24))"
xdotool mousemove --window "$awin" "$new_x" "$new_y"
