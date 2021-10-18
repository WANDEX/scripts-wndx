#!/bin/bash
# Download in Music dir audio only stream and convert to audio file format

MUSIC="$HOME/Music/1337"
PODCAST="$MUSIC/podcasts"
YTM="$MUSIC/YTM"

OLDIFS="$IFS"
# set variable to a new line, to use later as a value in Internal Field Separator
NLIFS='
'
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

sed_ext() { sed "s/\.[^.]*$/$1/g" ;}

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

clear_tags() {
    # remove from tags: all-comments, user-text-frames:(comment, description)
    at_path eyeD3 || return
    if [ ! -f "$1" ]; then
        # shellcheck disable=SC2153 # Possible misspelling
        printf '%s: "%s"\n' "${RED}FNF${END}" "$1"
        return
    fi
    # suppress output
    eyeD3 --quiet --preserve-file-times --remove-all-comments \
        --user-text-frame "comment:" \
        --user-text-frame "description:" \
        "$1" >/dev/null || echo "not cleared: '$1'"
}

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

# shellcheck disable=SC2059 # Don't use variables in the printf format string.
notify() {
    # use dunstify if available & show notification
    case "$1" in
        *error*|*ERROR*)
            urg="critical"
            CLR="$RED_S"
        ;;
        *warning*|*WARNING*)
            urg="normal"
            CLR="$YEL_S"
        ;;
        *completed*|*COMPLETED*)
            urg="normal"
            CLR="$GRN_S"
        ;;
        *)
            urg="low"
            CLR="$DEF_S"
        ;;
    esac
    if at_path dunstify; then
        DSTT="string:x-dunst-stack-tag:[download_audio.sh]($URL)"
        dunstify -u "$urg" -h "$DSTT" "D[AUDIO] $1" "\n$2\n"
    else
        notify-send -u "$urg" "D[AUDIO] $1" "\n$2\n"
    fi
    [ -n "$1" ] && printf "${CLR}${1}${END}\n"
    [ -n "$2" ] && printf "${CLR}${2}${END}\n"
}

get_opt() {
    # Parse and read OPTIONS command-line options
    SHORT=e:hp:ru:y:
    LONG=end:,help,path:,restrict,url:,ytdl:
    OPTIONS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
    # PLACE FOR OPTION DEFAULTS
    URL="$(xclip -selection clipboard -out)"
    PEND=-1
    restr=()
    YTDLOPTS=()
    eval set -- "$OPTIONS"
    while true; do
        case "$1" in
        -e|--end)
            shift
            case $1 in
                -1) PEND=-1 ;; # get full playlist
                0*)
                    printf "(%s)\n^ unsupported number! exit.\n" "$1"
                    exit 1
                    ;;
                ''|*[!0-9]*)
                    printf "(%s)\n^ IS NOT A NUMBER OF INT! exit.\n" "$1"
                    exit 1
                    ;;
                *) PEND=$1 ;;
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

bst="bestaudio"
asr="[asr=?48000]"
hz="${bst}${asr}"
abr1="[abr>=320]"
abr2="[abr>=256]"
f1="${hz}${abr1}"
f2="${hz}${abr2}"
BEST="$f1/$f2"
FALLBACK="bestaudio/best"
FORMAT="${BEST}/${FALLBACK}"

cmd=(\
youtube-dl --ignore-errors --yes-playlist --playlist-end="$PEND" \
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
    list_files="$(echo "$json" | jq -er '._filename' | sed_ext ".$ext")"
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
OUTREL="$(echo "$json" | ytdl_out_path.sh --real | sed_ext ".$ext")"
reldir="$(echo "$OUTREL" | head -n1 | sed "s|[^/]*$||")" # first file relative path to dir
notify "STARTED - relative path:" "$reldir"

total="$(echo "$OUTREL" | wc -l | sed "s/[ ]\+//g")" # remove whitespace
IFS="$NLIFS"
i=0
for out_template in $OUTRAW; do
    i=$(( i + 1))
    # from line i - get basename without ext
    _notify_name="$(echo "$OUTREL" | awk "NR==$i" | sed "s/^.*[/]//" | sed_ext '')"
    _notify_path="$(echo "$OUTREL" | awk "NR==$i" | sed "s|$HOME|~|; s|[^/]*$||")"
    if "${cmd[@]}" --playlist-items "$i" --output "${PD}${out_template}" "$URL"; then
        notify "[$i/$total] COMPLETED $_notify_path" "$_notify_name"
    else
        notify "ERROR: NOT DOWNLOADED $_notify_path" "$_notify_name\n$URL"
    fi
done
for file_path in $OUTREL; do
    clear_tags "${PD}${file_path}"
done
IFS="$OLDIFS" # restore


