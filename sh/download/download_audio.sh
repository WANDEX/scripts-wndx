#!/bin/bash
# Download in Music dir audio only stream and convert to audio file format

MUSIC="$HOME/Music/1337"
PODCAST="$MUSIC/podcasts"
YTM="$MUSIC/YTM"

USAGE=$(printf "%s" "\
Usage: $(basename "$0") [OPTION...]
OPTIONS
    -e, --end       If url is playlist - how many items to download (by default all:-1)
    -h, --help      Display help
    -p, --path      Destination path where to download
    -r, --restrict  Restrict filenames to only ASCII characters, and avoid '&' and spaces in filenames
    -u, --url       URL to download
")

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

notify() {
    # use dunstify if available & show notification
    case "$1" in
        *error*|*ERROR*) urg="critical" ;;
        *completed*|*COMPLETED*) urg="normal" ;;
        *) urg="low" ;;
    esac
    if at_path dunstify; then
        DSTT="string:x-dunst-stack-tag:[download_audio.sh]($filename)"
        dunstify -u "$urg" -h "$DSTT" "D[AUDIO] $1" "\n$2\n"
    else
        notify-send -u "$urg" "D[AUDIO] $1" "\n$2\n"
    fi
}

get_opt() {
    # Parse and read OPTIONS command-line options
    SHORT=e:hp:ru:
    LONG=end:,help,path:,restrict,url:
    OPTIONS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
    # PLACE FOR OPTION DEFAULTS
    URL="$(xclip -selection clipboard -out)"
    END=-1
    restr=()
    eval set -- "$OPTIONS"
    while true; do
        case "$1" in
        -e|--end)
            shift
            case $1 in
                -1) END=-1 ;; # get full playlist
                0*)
                    printf "(%s)\n^ unsupported number! exit.\n" "$1"
                    exit 1
                    ;;
                ''|*[!0-9]*)
                    printf "(%s)\n^ IS NOT A NUMBER OF INT! exit.\n" "$1"
                    exit 1
                    ;;
                *) END=$1 ;;
            esac
            ;;
        -h|--help)
            echo "$USAGE"
            exit 0
            ;;
        -p|--path)
            shift
            path="$1"
            ;;
        -r|--restrict)
            restr=( --restrict-filenames )
            ;;
        -u|--url)
            shift
            URL="$1"
            ;;
        --)
            shift
            break
            ;;
        esac
        shift
    done
}

get_opt "$@"

# substring
case "$URL" in
    *"bandcamp"*)
        PD="$MUSIC/bandcamp/"
        OUT="$PD"'%(artist)s/%(playlist)s/%(playlist_index)02d. %(title)s.%(ext)s'
        OPT=( --embed-thumbnail )
    ;;
    *"soundcloud"*"/sets/"*|*"soundcloud"*"/albums"*)
        PD="$MUSIC/soundcloud/"
        OUT="$PD"'%(uploader)s/%(playlist)s/%(playlist_index)02d. %(fulltitle)s.%(ext)s'
        OPT=( --embed-thumbnail )
    ;;
    *"soundcloud"*)
        PD="$MUSIC/soundcloud/"
        OUT="$PD"'%(uploader)s/%(playlist)s/%(fulltitle)s.%(ext)s'
        OPT=( --embed-thumbnail )
    ;;
    *"youtu"*"playlist"*)
        PD="$MUSIC/youtube/"
        OUT="$PD"'%(playlist_title)s/%(playlist_index)02d. %(title)s.%(ext)s'
        OPT=()
    ;;
    *"youtu"*)
        PD="$MUSIC/youtube/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=()
    ;;
    *)
        PD="$MUSIC/other/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=()
    ;;
esac >/dev/null

# substring
case "$path" in
    "kdi"|"Kdi"|"KDI")
        PD="$PODCAST/KDI/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=( --no-playlist )
    ;;
    "koda"|"Koda")
        PD="$PODCAST/Koda-Koda/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=( --no-playlist )
    ;;
    "lt"|"launch")
        PD="$PODCAST/Launch Tomorrow Podcast/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=( --no-playlist )
    ;;
    "podcast"|"Podcast")
        PD="$PODCAST/"
        OUT="$PD"'%(title)s.%(ext)s'
        OPT=( --no-playlist )
    ;;
    "ytm"|"Ytm"|"YTM")
        PD="$YTM/RNDM/"
        OUT="$PD"'%(uploader)s/%(title)s.%(ext)s'
        OPT=( --no-playlist )
    ;;
    *)
        if [ -n "$path" ]; then
            # add/replace 0 or more occurrences of '/' at the end, with one /
            PD="$(echo "$path" | sed "s/[/]*$/\//")"
            OUT="$PD"'%(title)s.%(ext)s'
            OPT=( --no-playlist )
        fi
    ;;
esac >/dev/null

BEST="bestaudio[asr=48000]"
FALLBACK="bestaudio/best"
FORMAT="${BEST}/${FALLBACK}"

notify "STARTED path:" "$OUT"

cmd=(\
youtube-dl --ignore-errors --yes-playlist --playlist-end="$END" \
--format "$FORMAT" --output "$OUT" "${restr[@]}" \
--extract-audio --audio-format "mp3" "${OPT[@]}" \
--add-metadata --no-overwrites --no-post-overwrites \
)

if "${cmd[@]}" "$URL"; then # execute cmd & check exit code
    notify "COMPLETED" "$PD"
else
    notify "ERROR" "Something gone wrong!\n$URL"
    exit 1
fi



