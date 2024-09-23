#!/bin/bash
# double quote text "$1" all other args for figlet options
# if only text given - preview given text in all found fonts

# set env var FIGLET_FONTDIR - path to search for font files
FONTSDIR="${FIGLET_FONTDIR:-"/usr/share/figlet/fonts"}"

TEXT="${1:-$(whoami)}"
othr="${*/$1/}" # remove $1 from all other args
IFS=' ' read -r -a OPTS <<< "$othr" # array of figlet options

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

if [ -z "${OPTS[*]}" ]; then
    [ -d "$FONTSDIR" ] || exit 1
    if at_path fd; then
        FONTS=$(fd --search-path "$FONTSDIR" -tf -e flf -x basename "{/.}" | sort)
    else
        FONTS=$(find "$FONTSDIR" -type f -name '*.flf' -exec basename {} .flf ';' | sort)
    fi
    if [ -z "$FONTS" ]; then
        echo "figlet fonts not found, exit."
        exit 2
    fi

    for font in $FONTS; do
        fout=$(figlet -f "$font" "$TEXT")
        w=$(echo "$fout" | wc --max-line-length)
        font_title=$(printf "%s%s%${w}s\n" "${CYN}${UND}" "$font" ">${END}")
        out=$(printf "%s\n%s\n" "$font_title" "$fout")
        echo "$out"
    done
else
    figlet "${OPTS[@]}" "$TEXT"
fi
