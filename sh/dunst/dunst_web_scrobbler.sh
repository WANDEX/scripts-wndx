#!/bin/sh
# get track information from notification, to display it in statusbar
# do not show notification
# Looks like sometimes extension just skips showing it's original notification
# Dunno why, but sometimes extension by itself does not show notification
appname="$1"
summary="$2"
body="$3"
icon="$4"
urgency="$5"
DST="string:x-dunst-stack-tag"
ms=2000

CSCRDIR="${CSCRDIR:-"$HOME/.cache/cscripts"}"
FILE="$CSCRDIR/bar/music-web" # hardcoded, check music-web script!

# -> it's essential because we match notification by 'SoundCloud' to run this script
# replace 'SoundCloud' pattern and '&'
# body="$(echo "$body" | sed "s/SoundCloud//g; s/&amp\;/\&/g")"

# maybe bash string replacement more stable than sed?
body="${body/SoundCloud}" # Remove part of the text.
body="${body//&amp\;/\&}" # Replace all matches in the text

track="$summary"
artist="$(echo "$body" | awk 'NR==3')" # extract artist from line 3

## XXX FOR TESTS ONLY!
# dunstify -u low -t 0 "$track" "$artist"
# dunstify -t 0 "$summary" "$body" && exit 0
# dunstify -t "$ms" -h "$DST:web-scrobbler1" "$summary" "$body"

write_to_file() {
    # write to file in order to display via music-web script
    echo "$1" > "$FILE"
}

refresh_music_web() {
    # hardcoded SIG! to update dwmblocks
    kill -46 "$(pidof dwmblocks)" # refresh music-web
}

# case "$body" in
#     *[Uu]nknown*)
#         # if notification shows that track isn't recognized
#         write_to_file "[X]"
#         refresh_music_web
#         exit 0
#         ;;
# esac

# replace patterns, delete lines with patterns, 4th line, transform into single line string
# artist="$(echo "$body" \
#     | sed "s/SoundCloud//g; s/&amp\;/\&/g" \
#     | sed "/^.* - Single/d; /^Your scrobbles:.*$/d; /$track/d; 4d" \
#     | tr -d '\n')"

composed="${track} - ${artist}"

## XXX FOR TESTS ONLY!
# dunstify -u low -t 0 -h "$DST:web-scrobbler" -h "$DST:hi" "$composed"
# dunstify -u low -t "$ms" -h "$DST:web-scrobbler2" "$composed"

write_to_file "$composed"
refresh_music_web
