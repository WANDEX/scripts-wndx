#!/bin/sh
# Load PSEye mic preset
# TODO: unhardcode
# DEVPATH="/dev/snd/by-path/pci-0000:00:1a.0-usb-0:1.6:1.1"
DEVPATH="/dev/snd/by-path/pci-0000:00:1d.0-usb-0:1.7:1.1"
if [ -e "$DEVPATH" ]; then
    #pulseaudio -k &&
    #pulseaudio --start
    #pactl load-module module-loopback latency_msec=1
    # pactl unload-module module-loopback
    pactl unload-module module-echo-cancel
    #pactl load-module module-echo-cancel use_master_format=1 aec_method='webrtc' aec_args='"analog_gain_control=0 digital_gain_control=1 voice_detection=1"' source_name=echoCancel_source sink_name=echoCancel_sink
    load-module module-echo-cancel use_master_format=1 aec_method='webrtc' aec_args='"analog_gain_control=0 digital_gain_control=1 voice_detection=1 beamforming=1 mic_geometry=-0.02,0,0,-0.01,0,0,0.01,0,0,0.02,0,0 target_direction=0,0.3,0.7"' source_name=echoCancel_source sink_name=echoCancel_sink
    # pactl load-module module-loopback
    pactl set-default-source echoCancel_source
    #pactl set-default-sink echoCancel_sink
    printf "%s\n%s\n" "$DEVPATH" "EXIST"
else
    # pactl unload-module module-loopback
    pactl unload-module module-echo-cancel
    printf "%s\n%s\n" "$DEVPATH" "DOES NOT EXIST"
fi
