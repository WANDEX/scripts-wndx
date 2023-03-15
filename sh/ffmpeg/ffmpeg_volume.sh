#!/bin/sh
# increase volume of the video by re-encoding only audio
# +50% or in dB
# volume=1.5
# volume=+3dB

ffmpeg -i "$1" -vcodec copy -filter:a "volume=1.5" "$2"
