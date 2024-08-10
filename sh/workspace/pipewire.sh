#!/bin/sh
# script for pipewire/pulse-audio -> combined sink creation and defaults
# aplay -lL
# pw-jack jack_lsp -c
# ? check for device availability
# fuser -v /dev/snd/*
# fuser -v /dev/dsp

# shellcheck disable=SC1091 # does not exist (No such file or directory)

# ENVD defined in /etc/environment
[ -z "$ENVDIR" ] && ENVDIR="$ENVD"
# source env variables if not defined at the exec time (for .xinitrc etc.)
[ -z "$SINK0" ] && . "$ENVDIR/scripts/get_dflt_sink"
[ -z "$SINK1" ] && . "$ENVDIR/scripts/get_hdmi_sink"

# source even if $SINK0 & $SINK1 defined at the exec time (overrides above)
. "$ENVDIR/scripts/get_dflt_sink"
. "$ENVDIR/scripts/get_hdmi_sink"

#pw-jack jack_control start
#pw-jack jack_control ds alsa
#pw-jack jack_control dps device hw:PCH
#pw-jack jack_control dps rate 48000

# or should be this?
#pw-jack jack_control dps device hw:PCH,0

# port names for jack_connect
dflt_port="Built-in Audio Analog Stereo"
comb_port="combined Audio/Sink sink"
# get hdmi port name (varies between the updates/machines)
hdmi_port=$(pw-jack jack_lsp -c | grep "HDMI.*:playback_FL" | tail -n1 | sed "s/:playback_FL//")

# create combined sink
if ! pactl list sinks short | grep -q "combined"; then
    pactl load-module module-null-sink object.linger=1 media.class=Audio/Sink sink_name=combined channel_map=stereo
fi

# connect (always reconnect as default sink name sometimes changes)
pw-jack jack_connect "$comb_port:monitor_FL" "$dflt_port:playback_FL"
pw-jack jack_connect "$comb_port:monitor_FR" "$dflt_port:playback_FR"

pw-jack jack_connect "$comb_port:monitor_FL" "$hdmi_port:playback_FL"
pw-jack jack_connect "$comb_port:monitor_FR" "$hdmi_port:playback_FR"

# set
# pactl set-default-sink combined
# pactl set-default-source combined.monitor


# >>> hex(32768) 0x8000  -  50%
# >>> hex(45875) 0xb333  -  70%
# >>> hex(65536) 0x10000 - 100%
# >>> hex(78643) 0x13333 - 120%
# >>> hex(98304) 0x18000 = 150%

# volume: 32768=50%, 45875=70%, 65536=100%, 78642=120%

pactl set-sink-volume "$SINK0" 0x10000
pactl set-sink-volume "$SINK1" 0x18000

# pactl set-sink-volume "$SINK0" 0xb333
# pactl set-sink-volume "$SINK1" 0x8000
# pactl set-sink-mute "$SINK1" true # mute at boot sink N

