#!/bin/bash
# download via youtube-dl video playlist or single video

# change main executable: youtube-dl, yt-dlp
ytdl_exec="yt-dlp"

bname=$(basename "$0")
USAGE=$(printf "%s" "\
Usage: $bname [OPTION...]
OPTIONS
    -B, --best          Toggle using of simple 'best' format
    -b, --begin         Start from the playlist index (default:1)
    -e, --end           If url is playlist - how many items to download (default:1) (full:-1)
    -f, --file          Read urls from the file, and download each specified on its own line
    -h, --help          Display help
    -i, --interactive   Explicit interactive playlist end mode
    -p, --path          Destination path where to download
    -P, --progress      Toggle showing of download progress in notification (only if started from terminal)
    -o, --oscr          Toggle using of out path script for composing path
    -q, --quality       Quality of video/stream
    -r, --restrict      Restrict filenames to only ASCII characters, and avoid '&' and spaces in filenames
    -u, --url           URL of the video
    -y, --ytdl          Any other ytdl native options (specify only inside \"\")
EXAMPLES:
    $bname -u \"\$URL\" -y '--simulate --get-duration' -y '--playlist-items 1-3'
")

get_opt() {
    # Parse and read OPTIONS command-line options
    SHORT=Bb:e:f:hip:Porq:u:y:
    LONG=best,begin:,end:,file:,help,interactive,path:,progress,oscr,restrict,quality:,url:,ytdl:
    OPTIONS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
    # PLACE FOR OPTION DEFAULTS
    OUT_DIR="$HOME/Films/.yt"
    START=1     # ytdl --playlist-start > start from the playlist index
    END=1       # ytdl --playlist-end > get first N items from playlist (full:-1)
    ENDOPT=0
    ## video quality prerequisites for the specific EXT
    EXT='webm'  # prefer specific extension over fallback
    UQLT='1080' # upper bound video height cap, specific for the extension EXT
    LQLT='720'  # lower bound -//- [hardcoded] (if unavailable for the EXT -> fallback)
    URL=$(xclip -selection clipboard -out)
    restr=()
    YTDLOPTS=()
    PROGRESS=0
    BESTFORMAT=0
    OUT_PATH_SCRIPT=1
    eval set -- "$OPTIONS"
    while true; do
        case "$1" in
        -B|--best)
            [ "$BESTFORMAT" -eq 1 ] && BESTFORMAT=0 || BESTFORMAT=1 # toggle behavior of value
            ;;
        -b|--begin)
            shift
            case $1 in
                -1) START=1 ;;
                0*)
                    printf "(%s)\n^ unsupported number! exit.\n" "$1"
                    exit 1
                    ;;
                ''|*[!0-9]*)
                    printf "(%s)\n^ IS NOT A NUMBER OF INT! exit.\n" "$1"
                    exit 1
                    ;;
                *) START=$1 ;;
            esac
            ;;
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
        -f|--file)
            shift
            file="$1"
            if [ ! -r "$file" ]; then
                printf "%s\n%s\n" "$file" "^file not found or not readable. exit."
                exit 1
            fi
            # remove everything after # character and empty lines with/without spaces
            URLS=$(sed "s/[[:space:]]*#.*$//g; /^[[:space:]]*$/d" "$file")
            # return total number of lines (trimming whitespaces)
            URLL=$(echo "$URLS" | wc -l | sed "s/[ ]\+//g" )
            ;;
        -h|--help)
            echo "$USAGE"
            exit 0
            ;;
        -i|--interactive)
            [ "$ENDOPT" -eq 1 ] && ENDOPT=0 || ENDOPT=1 # toggle behavior of value
            ;;
        -p|--path)
            shift
            # also trim any number of trailing slashes (if any)
            OUT_DIR="${1%%+(/)}"
            ;;
        -P|--progress)
            [ "$PROGRESS" -eq 1 ] && PROGRESS=0 || PROGRESS=1 # toggle behavior of value
            ;;
        -o|--oscr)
            [ "$OUT_PATH_SCRIPT" -eq 1 ] && OUT_PATH_SCRIPT=0 || OUT_PATH_SCRIPT=1 # toggle behavior of value
            ;;
        -r|--restrict)
            restr=( --restrict-filenames )
            ;;
        -q|--quality)
            shift
            UQLT="$1"
            ;;
        -y|--ytdl)
            shift
            # convert spaces in argument into individual args if any
            # -> so here we split arg string "$1" to array and arguments
            IFS=' ' read -ra yargs <<< "$1"
            # + to join all previously specified -y options into one array as in EXAMPLES
            YTDLOPTS+=( "${yargs[@]}" )
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

# check if script started from terminal emulator
if [ -t 0 ] && [ "$PROGRESS" == "1" ] ; then
    is_term=1
    # get before everything else (to prevent switching to another window)
    fwid=$(xdotool getactivewindow) # get id of the active/focused window
else
    is_term=0
    fwid="empty"
fi

get_index() {
    url="$1"
    # get int index value from url and make array option with it
    case "$url" in
        *"&index="*)
            ndx=$(echo "$url" | grep -o "&index=[[:digit:]]*" | sed "s/&index=//")
            pindex=( --playlist-items "$ndx" )
        ;;
    esac
    echo "$ndx"
}

ytdl_check() {
    # youtube-dl URL verification, verify only first item if many
    # get JSON data for url & OUTPATH as global variables
    url="$1"
    get_index "$url" >/dev/null 2>&1 # suppress output & errors
    case "${YTDLOPTS[*]}" in
        *"--no-playlist"*)
            # fix: for case when we specify '-y --no-playlist'
            # without it, we will get many NA in out path
            np=( --no-playlist )
        ;;
    esac
    JSON=$("$ytdl_exec" --dump-json --no-warnings "${pindex[@]}" --playlist-end=1 "${np[@]}" "$url")
    return_code=$?
    if [ "$return_code" -ne 0 ]; then
        summary="$ytdl_exec ERROR[$return_code]:"
        msg="TERMINATED Invalid URL,\nor first element from the URL"
        notify-send -u critical "$summary" "$msg"
        exit $return_code
    else
        if [ "$OUT_PATH_SCRIPT" -eq 1 ]; then
            RAWOUT=$(echo "$JSON" | ytdl_out_path.sh | head -n1) # use a template based on first file if many
        fi
        OUTPATH="${OUT_DIR}/${RAWOUT}"
    fi
}

statistic() {
    exit_code="$1"
    # initial values
    [ -z "$ok" ] && ok=0
    [ -z "$err" ] && err=0
    [ -z "$sum" ] && sum=0
    case "$exit_code" in
        0)
            ok=$(echo "$ok+1" | bc)
            printf "[%s/%s]\n" "$ok" "$URLL"
        ;;
        *)
            err=$(echo "$err+1" | bc)
            printf "[%s(%s)]\n" "ERROR:" "$exit_code"
        ;;
    esac
    sum=$(echo "$ok+$err" | bc)
    if [ "$URLL" -eq "$ok" ]; then
        printf "[%s] %s\n" "$ok" "ALL OK, FINISHED."
    elif [ "$URLL" -eq "$sum" ]; then
        printf "%s [%s] %s\n" "FINISHED WITH" "$err" "ERRORS."
    fi
}

ytdl_cmd() {
    url="$1"
    "$ytdl_exec" --console-title --ignore-errors --yes-playlist \
        "${pindex[@]}" --playlist-start="$START" --playlist-end="$END" \
        --write-sub --sub-lang en,ru --sub-format "ass/srt/best" --embed-subs \
        --format "$FORMAT" --output "$OUTPATH" "${restr[@]}" "${YTDLOPTS[@]}" "$url"
    exit_code=$?
    [ "$URLL" ] && statistic "$exit_code"
}

add_index() {
    # remove old & add new index to filename, then output new path
    _index="$1"
    _path=$(dirname  "$OUTPATH")
    _base=$(basename "$OUTPATH" | sed "s/^[[:digit:]]\+\. //") # remove old index
    _out="${_path}/${_index}${_base}"
    echo "$_out"
}

loop_over_urls() {
    # read line by line
    while IFS= read -r url; do
        ytdl_check "$url"
        ## XXX:  Not sure if we still need that...
        ##       Feels like it can be useful if url of the video is not based on the playlist.
        ## TODO: Remove later following commented out lines and related funcs when sure about that.
        ##       Because now it feels like a legacy before i wrote OUT_PATH_SCRIPT.
        # case "$url" in
        #     *"&index="*)
        #         # if url contains explicit index, use it as filename prefix
        #         index=$(get_index "$url") # get_index out of url parameters
        #         findex=$(printf "%.3d%s" "$index" ". ") # make index of format
        #         OUTPATH=$(add_index "$findex")
        #     ;;
        # esac
        printf "\n> %s\n" "$url"
        ytdl_cmd "$url"
    done <<< "$URLS"
}

ytdl_download() {
    url="$1"
    if [ -n "$URLS" ]; then
        loop_over_urls
    else
        ytdl_check "$url"
        ytdl_cmd "$url"
    fi
}

ytdl_av_format_string() {
    if [ "$BESTFORMAT" -eq 1 ]; then
        FORMAT="best"
        return
    fi
    case "$UQLT" in
        *"1"*)
            UQLT="1080"
        ;;
        *"8"*)
            UQLT="1080"
        ;;
        *"7"*)
            UQLT="720"
        ;;
        *"4"*)
            UQLT="480"
        ;;
    esac
    ## ext specific
    _ext_video_q="bestvideo[ext=${EXT}][height<=${UQLT}][height>=${LQLT}]"
    _ext_audio_q="bestaudio[ext=${EXT}]"
    _ext_specs_q="${_ext_video_q}+${_ext_audio_q}"
    ## fallback
    _fll_video_q="bestvideo[height<=${UQLT}]"
    _fll_audio_q="bestaudio"
    _fll_specs_q="${_fll_video_q}+${_fll_audio_q}"
    ## full audio/video format string with fallbacks split by the '/'
    FORMAT="${_ext_specs_q}/${_fll_specs_q}/best"
}

ytdl() {
    # youtube-dl
    url="$1"
    ytdl_av_format_string

    title=$(echo "$JSON" | jq -r ".title")
    # XXX not sure about the body & fulltitle
    fulltitle=$(echo "$JSON" | jq -r ".fulltitle")
    case "$url" in
        *"playlist?list="*) body="$url" ;;
        *)
            if [ -n "$title" ]; then
                body="$title"
            elif [ -n "$fulltitle" ]; then
                body="$fulltitle"
            else
                body="$url"
            fi
        ;;
    esac
    if [ "$END" = "-1" ]; then
        # last playlist_index num (length)
        lindx=$(echo "$JSON" | jq -r '.playlist_index' | tail -n 1 | sed "s/[ ]*//g")
        case "$lindx" in
            null|''|*[!0-9]*) lindx=1 ;; # this comes if variable contains non int characters
        esac
    else
        lindx="$END"
    fi
    # show this notification only if script started from terminal,
    # to be sure, that we could check console-title in dunst_download_started.sh script.
    if [ $is_term -eq 1 ]; then
        dunstify -h "string:x-dunst-stack-tag:dp_$fwid" \
            "[DOWNLOAD][VIDEO][STARTED]($fwid){$lindx}:" "\n$body\n"
    fi

    ytdl_download "$url"
    if [ "$exit_code" -eq 0 ]; then
        if [ $is_term -eq 1 ]; then
            dunstify -u normal -h "string:x-dunst-stack-tag:dp_$fwid" \
                "[DOWNLOAD][VIDEO][COMPLETED]($fwid)" "\n$body\n"
        else
            dunstify -u normal -h "string:x-dunst-stack-tag:dp_$fwid" \
                "[DOWNLOAD][VIDEO][FINISHED]" "\n$body\n"
        fi
    else
        dunstify -u critical -t 0 -h "string:x-dunst-stack-tag:dp_$fwid" \
            "[DOWNLOAD][VIDEO][ERROR]:[$exit_code]" "\n$body\n$url\n"
        if [ $is_term -eq 1 ]; then
            # here we fake ->
            # to exit out of infinite loop inside dunst_download_started.sh
            xprop -id "$fwid" -set WM_ICON_NAME "DOWNLOAD_COMPLETED"
            sleep 5 # sleep ->
            xdotool set_window --name "$TERMINAL" "$fwid" # set name (because ytdl will leave '...100%...')
            xprop -id "$fwid" -remove WM_ICON_NAME # remove property (as it's default in st)
        fi
        exit "$exit_code"
    fi
}

main() {
    if [ "$ENDOPT" -eq 1 ]; then
        Q="Download all videos [y/n]? "
        while true; do
            read -p "$Q" -n 1 -r
            echo "" # move to a new line
            case "$REPLY" in
                [Yy]*) END=-1; break;;
                [Nn]*) END=1;  break;;
                *) echo "I do not get it.";;
            esac
        done
    fi
    ytdl "$URL"
}

main "$@"
