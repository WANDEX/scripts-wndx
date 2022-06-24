#!/bin/bash
# NOTE: bash -> with dash jq throws: parse error: Invalid string: control characters
# script for youtube-dl - get from stdin or as $1 arg JSON data from youtube-dl
# and compose output path with optional parts based on their availability in JSON
# SCRIPT OUTPUT EXAMPLES:
# %(uploader)s/%(title)s.%(ext)s
# %(uploader)s/%(playlist_title)s/%(playlist_index)003d. %(title)s.%(ext)s

bname=$(basename "$0")
USAGE=$(printf "%s" "\
Usage:  [OPTION...]
OPTIONS
    -h, --help          Display help
    -r, --real          Get output not as a ytdl template, but with real values
EXAMPLES
# from stdin pipe
    youtube-dl --dump-json --no-warnings --playlist-end=1 \"\$URL\" | $bname
# from \$1 argument
    $bname \"\$JSON_DATA\"
")

[ "$1" = "-h" ] || [ "$1" = "--help" ] && echo "$USAGE" && exit 0
[ "$1" = "-r" ] || [ "$1" = "--real" ] && real=1

if [ $# -gt 2 ]; then
    printf "%s\n" "ERROR: too much arguments provided [$#]"
    printf "%s\n" 'DO NOT FORGET to put variable inside " " double quotation marks'
    printf "%s\n\n%s\n" "to provide as single JSON data variable! exit." "$USAGE"
    exit 1
elif [ -n "$2" ] && [ "$2" != "-r" ] && [ "$2" != "--real" ]; then
    JSON="$2" # argument
elif [ -n "$1" ] && [ "$1" != "-r" ] && [ "$1" != "--real" ]; then
    JSON="$1" # argument
elif test ! -t 0; then
    JSON=$(cat) # /dev/stdin pipe used usually
else
    printf "%s\n\n%s\n" "ERROR: provide JSON data! exit." "$USAGE"
    exit 1
fi

template_dir() {
    if [ -n "$real" ]; then
        printf "%s/" "$part"
    else
        printf "%s" "%($trarg)s/"
    fi
}

template_str() {
    if [ -n "$real" ]; then
        printf "%s" "$part"
    else
        printf "%s" "%($trarg)s"
    fi
}

template_num() {
    _npost=". "
    if [ -n "$real" ]; then
        printf "%03d%s" "$part" "$_npost"
    else
        printf "%s%s" "%($trarg)03d" "$_npost"
    fi
}

make_template() {
    # decide which template to use based on $1
    case "$1" in
        *number*|*playlist_index*) template_num ;;
        */*) template_dir ;;
        *)   template_str ;;
    esac
}

jget() { echo "$JSON" | jq -re "${select}.$1" 2>&1;}

jcheckall() {
    # check multiple args, return first found
    args="${*}"
    for arg in $args; do
        trarg=$(echo "$arg" | sed "s/[/]//") # trim slash to check without it
        part="$(jget "$trarg")"
        if [ "$part" != null ]; then
            make_template "$arg"
            break # prefer found first -> break out of the loop
        fi # else -> don't make template (skip part of output path)
    done
}

compose_output() {
    # get available parts of output path
    o_top=$(jcheckall 'uploader/' 'playlist_uploader/' 'channel/' 'creator/')
    o_mid=$(jcheckall 'artist/' 'series/')
    o_wtr=$(jcheckall 'season_number/' 'season/' 'chapter/')
    o_xtr=$(jcheckall 'album/' 'playlist_title/' 'playlist/')
    o_num=$(jcheckall 'track_number' 'episode_number' 'playlist_index')
    # remove from _filename: -id to the end of the string including .ext
    # (because it actually does not exist in real filename after successful download)
    _filename=$(jget '_filename' | sed "s/-[^-]*$//")
    fulltitle=$(jget 'fulltitle')
    if [ "$_filename" != "$fulltitle" ]; then
        # FIX: when output filename will differ -> use real filename only
        # (because otherwise youtube-dl will newer use our template)
        o_bot="$_filename"
    else
        o_bot=$(jcheckall 'track' 'episode' 'title' 'fulltitle')
    fi
    o_ext=$(jcheckall 'ext') && o_ext=".$o_ext"
    OUT="${o_top}${o_mid}${o_wtr}${o_xtr}${o_num}${o_bot}${o_ext}"
    unset -v o_top o_mid o_wtr o_xtr o_num o_bot o_ext
    echo "$OUT"
}

playlist_indexes="$(echo "$JSON" | jq -re ".playlist_index")"
for index in $playlist_indexes; do
    select="select(.playlist_index==${index}) | "
    playlist_entry="$(compose_output)"
    output="$(printf "%s\n%s\n" "$output" "$playlist_entry")"
done
# remove empty lines (first line always empty)
echo "$output" | sed '/^[[:space:]]*$/d'
