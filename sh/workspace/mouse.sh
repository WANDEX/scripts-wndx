#!/bin/sh
# find mouse id with:
# $ xinput list
# TODO: unhardcode
dev_id="${MOUSE_ID:-10}"
dev_name="A4TECH USB Device " # mouse device name
dev_id=$(xinput list | grep "${dev_name}[ ]\+" | awk '{gsub(/id=/, ""); print $6}')

# enable middle mouse click scrolling
xinput set-prop "$dev_id" "libinput Scroll Method Enabled" 0, 0, 1
# set scrolling to middle mouse button
xinput set-prop "$dev_id" "libinput Button Scrolling Button" 2
