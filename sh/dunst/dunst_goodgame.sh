#!/bin/sh
# change notification text that stream is started with full stream path at body
# and add ACTION into notification
# shellcheck disable=SC2034 # appears unused
appname="$1"
summary="$2"
body="$3"
icon="$4"
urgency="$5"

DST="string:x-dunst-stack-tag"
bg="string:bgcolor:#32393A"
fg="string:fgcolor:#EFEFF1"

# XXX write to file raw summary and body in order to understand how to get channel name properly
# printf "%s\n%s\n%s\n" "summary:'$summary'" "body:'$body'" "==================" >> \
#     ~/goodgame_dunst_notifications_log.txt

# extract channel name
goodgame_channel=$(echo "$body" | tail -n1 | sed "s/ .*$//")
# fix: for weird channel names where the actual channel name in url is different
case "$goodgame_channel" in
    "h3lldemon") goodgame_channel="maddyson";;
esac

url="https://goodgame.ru/channel/${goodgame_channel}/"
stream_title="$summary"
summary="🔴 $goodgame_channel LIVE:"
body="\n$stream_title\n$url\n"

# automatically open stream if channel name in AUTOFILE
AUTOFILE="$CSCRDIR/dunst_goodgame"
if [ -r "$AUTOFILE" ]; then
    if grep -i "$goodgame_channel" "$AUTOFILE"; then
        dunstify -h "$DST:hi" -h "$bg" -h "$fg" "(AUTO) mpvu:" "$goodgame_channel"
        setsid -f mpvu -u "$url"
    fi
fi

ACTION=$(dunstify -u "$urgency" -h "$bg" -h "$fg" -A "default,mpvu" -A "clip,url" "$summary" "$body\n")

case "$ACTION" in
"default")
    setsid -f mpvu -u "$url"
    ;;
"clip")
    clipargs "$url"
    ;;
esac
