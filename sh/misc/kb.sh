#!/bin/sh
# toggle between keyboard layouts & show notification with current layout

DST="string:x-dunst-stack-tag"
CURRENT_VARIANT=$(setxkbmap -query | grep -i 'variant:' | awk '{print $2}' | sed "s/[,].*$//")

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0
notify() {
    if at_path dunstify; then
        dunstify -u low -h "$DST:kb.sh" -h "$DST:hi" "$1"
    else
        notify-send -u low "$1"
    fi
}

if [ "$CURRENT_VARIANT" != "colemak" ]; then
    setxkbmap -model pc104 -layout us,ru -variant colemak, -option grp:caps_toggle,grp_led:scroll
    notify "⌨ COLEMAK"
else
    setxkbmap -model pc104 -layout us,ru -option grp:caps_toggle,grp_led:scroll
    notify "⌨ QWERTY"
fi

xset r rate 200 60
