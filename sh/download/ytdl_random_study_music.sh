#!/bin/sh
# play random element from the predefined collection of playlists.
# to select one of the playlists - uncomment one of the url lines.
#
## some playlists/channels with suitable music for learning.
# https://www.youtube.com/@meditations.acepe./playlists
# https://www.youtube.com/c/QuietQuestStudyMusic/playlists

bn=$(basename "$0")

url=""

## acepe. videos:
# url="https://www.youtube.com/@meditations.acepe./videos"
## acepe. playlists:
# url="https://www.youtube.com/playlist?list=PLlI82_5S2US_keE-1ulD1t-BCqa4-Lh5b" # Compilation
# url="https://www.youtube.com/playlist?list=PLlI82_5S2US_Y3KqpAJ51mbEatm3wV7XO" # Stoic Ambience
# url="https://www.youtube.com/playlist?list=PLlI82_5S2US_HQFM5cUBiGscoHzfTeSFA" # Reflect with philosophers, leaders, and artists.
# url="https://www.youtube.com/playlist?list=PLlI82_5S2US9oPPSM2FCwgJZEuAFZZFiK" # Roman Ambiance
# url="https://www.youtube.com/playlist?list=PLlI82_5S2US-YWlPR_kNtoRQL2b_qyh9c" # Ancient Greece Ambience
url="https://www.youtube.com/playlist?list=PLlI82_5S2US8-nNdj9GbPVB4DB1tbQmrN" # Dark Ambience to Reflect Deeply

if [ -z "$url" ]; then
    notify-send -u critical -t 0 "[$bn]" "no uncommented url, EXIT." &
    exit 4
fi

exec ytdl_random_playlist_entry.sh "$url"

