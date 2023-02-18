#!/bin/sh
# this version is specific for the 'Twitch Live Channels' extension:
# 'https://github.com/s4my/TwitchLiveChannels'
# I moved to this extension because twitch stopped sending me notifications. :(
#
# Change notification text that stream is started with full stream path at body
# and add ACTION into notification.
#
## MEMO:
## TLC sends notification for each new appearing live channel from the user's followings.
## -> mimic behavior when notifications are sent for only specific channels.
## => show notification only for channels listed in the file (each channel name on its own line).
##
##
## NOTE: to get list of channels, for which you enabled notifications:
## open: 'https://www.twitch.tv/settings/notifications'
## following is the JS code to paste into the web developer console on the page (F12):
## ``` // JS BEG
# // to get list of the channels for which notifications are disabled (just for reference)
# // var disabled = document.querySelectorAll("[checked=''][disabled='']")
# var enabled = document.querySelectorAll("[checked='']:not([disabled=''])")
# array = []
# for (var i = 0; i < enabled.length; i++) {
#     // .textContent & .innerText gives the same result.
#     array.push(enabled.item(i).labels.item(0).textContent)
# }
# var mulstr = array.join("\n") // each on its own line
# mulstr // to copy/paste into the file
## ``` // JS END

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
bg="string:bgcolor:#9147FF"
fg="string:fgcolor:#EFEFF1"

# toggle behavior of showing notifications (ALL/ONLY LISTED)
# 1 - show all, otherwise suppress notifications of the not listed channels.
TLC_SHOW_ALL="${TLC_SHOW_ALL:-0}"

## HACK: Extension sends channel name, not channel login.
##       Channel login is the actual thing used in construction of the channel $url.
##       Considering this, script cannot work properly for channels which login is different.
##       Case is ignored, but this is all.
##       To workaround this go to: 'HACK ALIAS'
##
## original notification format at the time of writing the script:
## s: 'Twitch Live Channels'
## b: '<b>LIRIK</b> is Live streaming Just Chatting'

dump_vars() {
    printf "s: '%s'\nb: '%s'\n\n" "$summary" "$body" >> ~/dump_tlc_log.txt
}

## uncomment for debug (if you suspect that notification format has been changed)
# dump_vars

# sed get only channel name inside surrounding: <b> </b>
twitch_channel=$(echo "$body" | sed -n "s/^.*>\(.*\)<.*$/\1/p")
_raw_non_ascii="$twitch_channel"
# remove all unprintable characters & spaces (to have only Latin characters, else empty)
twitch_channel=$(echo "$twitch_channel" | tr -cd "[:print:]")

# HACK ALIAS: channel name to the channel login via predefined alias from the file,
# to construct valid twitch channel url etc.
## NOTE: how to define alias (the example line format of the file):
## v-(channel login for the url construction, manually predefined alias)
## v        v-(columns are split by the ':' character)
## v        v  v-(channel name, in this specific case it is in the Korean)
## juliday97: '줄리님'
if [ -z "$twitch_channel" ]; then
    ntl_alias="$CSCRDIR/dunst_twitch_name_to_login"
    [ ! -f "$ntl_alias" ] && touch "$ntl_alias"
    twitch_login=$(grep -Fiw "$_raw_non_ascii" "$ntl_alias" | cut -d: -f1)
    # if alias is defined -> override with the alias
    [ -n "$twitch_login" ] && twitch_channel="$twitch_login"
    # NOTE: defining twitch login alias is a workaround
    # for the channels which name and login differ. (to construct proper channel url)
fi

# handle case when $twitch_channel is empty
if [ -z "$twitch_channel" ]; then
    dunstify -u critical "[$bname] ERROR: empty channel name" "\nvars dumped into the log file." &
    dump_vars
    exit 4
fi

category=$(echo "$body" | sed "s/^.*is Live streaming //")


url="https://www.twitch.tv/${twitch_channel}"
summary="🔴 $twitch_channel LIVE:"
body="\n[TLC]: $category\n$url\n"

# automatically open stream if channel is found in the auto_file (each on its own line)
auto_file="$CSCRDIR/dunst_twitch"
[ ! -f "$auto_file" ] && touch "$auto_file"
if grep -iqx "$twitch_channel" "$auto_file"; then
    dunstify -h "$DST:hi" -h "$bg" -h "$fg" "[$bname] (AUTO) mpvu:" "$twitch_channel\n" &
    setsid -f mpvu -u "$url"
fi

if [ -n "$TLC_SHOW_ALL" ] && [ "$TLC_SHOW_ALL" != 1 ]; then
    # HACK: (without this, the notifications will be shown for each channel which goes live)
    # do not show notification if channel is not found in the notify_file (each on its own line)
    notify_file="$CSCRDIR/dunst_twitch_notify_list"
    [ ! -f "$notify_file" ] && touch "$notify_file"
    if ! grep -iqx "$twitch_channel" "$notify_file"; then
        # do not show notification, this channel is not that important.
        # => channel (channel_login) is not found in notify_file, just silently exit.
        exit 0
    fi
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
