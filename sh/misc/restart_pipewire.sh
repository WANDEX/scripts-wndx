#!/bin/sh
# restart sound related programs and pipewire itself

pkill easyeffects

# restart pipewire
systemctl --user restart pipewire.service

# run pipewire defaults configuration
pipewire.sh
wait

mpd --kill
mpd
pkill mpdas
mpdas -d
pkill mpdup
setsid -f mpdup
setsid -f easyeffects
printf "\n%s\n" "Use ^C to exit out of junk outputted by easyeffects to terminal."
# WARNINGS etc. dunno how to suppress that...
