#!/bin/sh
# this version is specific for the 'GoodGame.ru stream notifications' extension:
# 'https://addons.mozilla.org/en-US/firefox/addon/goodgame-notifications/'
# I moved to this extension because goodgame stopped sending me notifications. :(
#
# change notification text that stream is started with full stream path at body
# and add ACTION into notification

set -e
bname=$(basename "$0")

# shellcheck disable=SC2034 # appears unused
{ # {} to apply these ^ rules to the nested:
appname="$1"
summary="$2"
body="$3"
icon="$4"
urgency="$5"
}

DST="string:x-dunst-stack-tag"
bg="string:bgcolor:#32393A"
fg="string:fgcolor:#EFEFF1"

## original notification format at the time of writing the script:
## s: 'KinoKrabick запустил стрим'
## b: 'Игра: Movie
## The Last of Us Сезон 1 Серия 4+5'

dump_vars() {
    printf "s: '%s'\nb: '%s'\n\n" "$summary" "$body" >> ~/dump_gg_log.txt
}

## uncomment for debug (if you suspect that notification format has been changed)
# dump_vars

# extract channel name
# remove all unprintable characters & spaces (just in case)
gg_channel=$(echo "$summary" | awk '{print $1}' | tr -cd "[:print:]")

# handle case when $gg_channel is empty
if [ -z "$gg_channel" ]; then
    dunstify -u critical "[$bname] ERROR: empty channel name" "\nvars dumped into the log file." &
    dump_vars
    exit 4
fi

# fix: for weird channel names where the actual channel name in url is different
case "$gg_channel" in
    "h3lldemon") gg_channel="maddyson";;
esac

category_n_title=$(echo "$body" | sed "s/Игра: //")


url="https://goodgame.ru/channel/${gg_channel}/"
summary="🔴 $gg_channel LIVE:"
body="\n$category_n_title\n$url\n"

# automatically open stream if channel is found in the auto_file (each on its own line)
auto_file="$CSCRDIR/dunst_goodgame"
[ ! -f "$auto_file" ] && touch "$auto_file"
if grep -iqx "$gg_channel" "$auto_file"; then
    dunstify -h "$DST:hi" -h "$bg" -h "$fg" "[$bname] (AUTO) mpvu:" "$gg_channel\n" &
    setsid -f mpvu -u "$url"
fi

ACTION=$(dunstify -u "$urgency" -h "$bg" -h "$fg" -A "default,mpvu" -A "clip,url" "$summary" "$body")

case "$ACTION" in
"default")
    setsid -f mpvu -u "$url"
    ;;
"clip")
    clipargs "$url"
    ;;
esac
