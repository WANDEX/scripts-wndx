#!/bin/sh
# select one random element from playlist
# get json data and open url in mpv as audio

# change main executable: youtube-dl, yt-dlp
ytdl_exec="yt-dlp"

url="${1:-$(xclip -selection clipboard -out)}"
case "$url" in
    *"youtu"*"playlist"*|*"youtu"*"videos"*)
        json=$($ytdl_exec -j --flat-playlist "$url" | shuf -n 1 | tr -d '[:cntrl:]')
        ;;
    *) notify-send "[ERROR]: given URL is not youtube playlist" "\n$url" && exit 1 ;;
esac

id=$(     printf "%s" "$json" | jq -r '.id')
url=$(    printf "%s" "$json" | jq -r '.url')
title=$(  printf "%s" "$json" | jq -r '.title')
seconds=$(printf "%s" "$json" | jq -r '.duration')
duration=$(date -d"@${seconds}" -u +%H:%M:%S)

res_url=""
[  "$id" != "null" ] && res_url="https://www.youtube.com/watch?v=${id}"
[ "$url" != "null" ] && res_url="$url"
if [ -z "$res_url" ]; then
    notify-send -u critical -t 0 "$title" \
    "\n[$duration] .id || .url were not found in the json data" &
    exit 4
fi

notify-send "$title" "\n[$duration] $res_url" &
exec mpvu -q audio --quiet --end 1 --url "$res_url"

