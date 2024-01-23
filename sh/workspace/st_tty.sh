#!/bin/sh
# open device
# to fix access permission
## sudo usermod -a -G tty
## sudo usermod -a -G uucp
## sudo usermod -a -G dialout

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

bn=$(basename "$0")

extra_text="${1:-""}"
baud_rate="${2:-115200}"
[ -n "$extra_text" ] && extra_text="$extra_text " # append extra space char

dev_tty=$(find /dev/tty* | dmenu -i -l 20 -g 8)
[ -z "$dev_tty" ] && exit 0 # exit if none chosen.

font="VictorMono Nerd Font Mono:pixelsize=14"
## also used as the terminal title
line="$dev_tty ${baud_rate}"
title="${extra_text}${line}"

# shellcheck disable=SC2086 # (Double quote to prevent globbing and word splitting)

# FIXME: or just use '&' instead of setsid
# exec setsid st -t "$title" -f "$font" -l "$line"
# st -t "$title" -f "$font" -l $line && $bn

st -t "$title" -f "$font" -l $line \
&& { notify-send -u critical -t 0 "[$bn] DIED $(date +%T)" "$title" ;}


# TODO: find a way to not die completely if device is unplugged

# st -e shell.sh st -t "$title" -f "$font" -l $line \
# || { notify-send -u critical -t 0 "[$bn] DIED $(date +%T)" "$title" ;}


# st -e shell.sh st -t "$title" -f "$font" -l $line ||
# exec shell.sh st -t "$title" -f "$font" -l $line || {

# shell.sh st -t "$title" -f "$font" -l $line || { \
# summary="[$bn] DIED $(date +%T)"; \
# body="$title"; \
# echo "!!! $summary - $body !!!"; \
# notify-send -u critical -t 0 "$summary" "$body" \
# exec $SHELL ;}


