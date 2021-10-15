#!/bin/bash
# Download in Music dir audio only stream and convert to audio file format

MUSIC="$HOME/Music/1337"
PODCAST="$MUSIC/podcasts"
YTM="$MUSIC/YTM"

ext="mp3"

USAGE=$(printf "%s" "\
Usage: $(basename "$0") [OPTION...]
OPTIONS
    -e, --end       If url is playlist - how many items to download (by default all:-1)
    -h, --help      Display help
    -p, --path      Destination path where to download
    -r, --restrict  Restrict filenames to only ASCII characters, and avoid '&' and spaces in filenames
    -u, --url       URL to download
    -y, --ytdl      Any other youtube-dl native options (specify only inside \"\")
EXAMPLES:
    $(basename "$0") -u \"\$URL\" -y '--simulate --get-duration' -y '--playlist-items 1-3'
")

sed_ext() { sed "s/\.[^.]*$/\.$ext/g" ;}

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

find_filepath() {
    # find & return full path of the file by $1 filename
    [ -z "$1" ] && echo "${RED}no filename provided, exit.${END}" && exit 4
    if at_path fd; then
        # use fd to find file (instead of slow 'find')
        _filepath="$(fd --search-path "$MUSIC" -F1t f "$1")"
    else
        _filepath="$(find "$MUSIC" -type f -name "$1" | head -n1)"
    fi
    realpath -q "$_filepath"
}

notify() {
    # use dunstify if available & show notification
    case "$1" in
        *error*|*ERROR*) urg="critical" ;;
        *warning*|*WARNING*) urg="normal" ;;
        *completed*|*COMPLETED*) urg="normal" ;;
        *) urg="low" ;;
    esac
    if at_path dunstify; then
        DSTT="string:x-dunst-stack-tag:[download_audio.sh]($URL)"
        dunstify -u "$urg" -h "$DSTT" "D[AUDIO] $1" "\n$2\n"
    else
        notify-send -u "$urg" "D[AUDIO] $1" "\n$2\n"
    fi
}

get_opt() {
    # Parse and read OPTIONS command-line options
    SHORT=e:hp:ru:y:
    LONG=end:,help,path:,restrict,url:,ytdl:
    OPTIONS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
    # PLACE FOR OPTION DEFAULTS
    URL="$(xclip -selection clipboard -out)"
    END=-1
    restr=()
    YTDLOPTS=()
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
        -y|--ytdl)
            shift
            # convert spaces in argument into individual args if any
            # -> so here we split arg string "$1" to array and arguments
            IFS=' ' read -ra yargs <<< "$1"
            # + to join all previously specified -y options into one array as in EXAMPLES
            YTDLOPTS+=( "${yargs[@]}" )
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
        OPT=( --embed-thumbnail )
    ;;
    *"soundcloud"*"/sets/"*|*"soundcloud"*"/albums"*)
        PD="$MUSIC/soundcloud/"
        OPT=( --embed-thumbnail )
    ;;
    *"soundcloud"*)
        PD="$MUSIC/soundcloud/"
        OPT=( --embed-thumbnail )
    ;;
    *"youtu"*"playlist"*)
        PD="$MUSIC/youtube/"
        OPT=()
    ;;
    *"youtu"*)
        PD="$MUSIC/youtube/"
        OPT=()
    ;;
    *)
        PD="$MUSIC/other/"
        OPT=()
    ;;
esac >/dev/null

# substring
case "$path" in
    "kdi"|"Kdi"|"KDI")
        PD="$PODCAST/KDI/"
        OPT=( --no-playlist )
    ;;
    "koda"|"Koda")
        PD="$PODCAST/Koda-Koda/"
        OPT=( --no-playlist )
    ;;
    "lt"|"launch")
        PD="$PODCAST/Launch Tomorrow Podcast/"
        OPT=( --no-playlist )
    ;;
    "podcast"|"Podcast")
        PD="$PODCAST/"
        OPT=( --no-playlist )
    ;;
    "ytm"|"Ytm"|"YTM")
        PD="$YTM/RNDM/"
        OPT=( --no-playlist )
    ;;
    *)
        if [ -n "$path" ]; then
            # add/replace 0 or more occurrences of '/' at the end, with one /
            PD="$(echo "$path" | sed "s/[/]*$/\//")"
            OPT=( --no-playlist )
        fi
    ;;
esac >/dev/null

BEST="bestaudio[asr=48000]"
FALLBACK="bestaudio/best"
FORMAT="${BEST}/${FALLBACK}"

cmd=(\
youtube-dl --ignore-errors --yes-playlist --playlist-end="$END" \
--format "$FORMAT" \
--extract-audio --audio-format "$ext" \
--add-metadata --no-overwrites --no-post-overwrites \
--youtube-skip-dash-manifest \
"${restr[@]}" "${OPT[@]}" "${YTDLOPTS[@]}" \
)

# try to get url info as json & check exit code
if json="$("${cmd[@]}" --dump-json "$URL")"; then
    # get list of all files from url and replace any .ext
    # (because we convert everything to that .ext after downloading)
    list_files="$(echo "$json" | jq -er '._filename' | sed_ext)"
    first_file="$(echo "$list_files" | head -n1)"
    if [ -z "$first_file" ]; then
        notify "ERROR" "[EXIT] No _filename in json data.\n$URL"
        exit 3
    fi
else
    notify "ERROR" "[EXIT] Cannot get url info.\n$URL"
    exit 2
fi

OUTRAW="$(echo "$json" | ytdl_out_path.sh)"
OUTREL="$(echo "$json" | ytdl_out_path.sh --real | sed "s/\.[^.]*$/\.mp3/g")"
OUTPATH="${PD}${OUTRAW}"
OUTREAL="${PD}${OUTREL}"
notify "STARTED - relative path:" "$OUTREL"

# try to download & check exit code
if "${cmd[@]}" --output "$OUTPATH" "$URL"; then
    notify "COMPLETED" "$PD"
else
    notify "ERROR" "[EXIT] CANNOT DOWNLOAD!\n$URL"
    exit 1
fi


if [ -f "$OUTREAL" ]; then
    # remove from tags: all-comments, user-text-frames:(comment, description)
    if at_path eyeD3; then
        eyeD3 --quiet --preserve-file-times --remove-all-comments \
            --user-text-frame "comment:" --user-text-frame "description:" "$OUTREAL" >/dev/null # suppress output
    fi
fi


