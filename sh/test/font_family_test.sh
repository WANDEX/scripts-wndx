#!/bin/sh
# show/test all available font family variants
# NOTE: for work sh/fix/any_key.sh script is required!

USAGE=$(printf "%s" "\
Usage: $(basename "$0") [OPTION...]
OPTIONS
    -b, --blacklist Comma-separated list of blacklisted font styles
    -F, --font      Test specified 'font family name' styles
    -f, --family    Get available font family styles for 'font family name' or 'all'
    --families      Get all available font family names
    -h, --help      Display help
    -s, --styles    Get available font family styles for current \$TERMINAL font
")

# read into variable using 'Here Document' code block
# all available font styles presorted
STYLES=$(printf "%s" "\
Thin
Demi
Light
ExtraLight
Condensed
SemiCondensed
Initials
ja
ko
Mono
Book
Regular
Roman
Italic
Oblique
Medium
Extra
Expanded
Semi
SemiBold
Bold
Black
ExtraBold
Heavy
Ultra
")

get_family_styles() {
    if [ "$1" = all ]; then
        arg=":"
    else
        arg="$1"
    fi
    fc-list "$arg" style | sed "s/:style=//g; s/[ ,].*$//g; /^[ ]*$/d" | sort -u
}

font_family=$(font_test.sh --family)
font_typesize=$(font_test.sh --typesize)
font_size=$(font_test.sh --size)
font_style=$(font_test.sh --style)

get_opt() {
    # Parse and read OPTIONS command-line options
    SHORT=b:F:f:hs
    LONG=blacklist:,font:,family:,families,help,style
    OPTIONS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
    # PLACE FOR OPTION DEFAULTS
    otherlist="Italic,Oblique"
    boldlist="Semibold,Bold,Extrabold,Heavy"
    blacklist="$otherlist","$boldlist"
    eval set -- "$OPTIONS"
    while true; do
        case "$1" in
        -b|--blacklist)
            shift
            blacklist="$1"
            ;;
        -F|--font)
            shift
            font_family="$1"
            ;;
        -f|--family)
            shift
            get_family_styles "$1"
            exit 0
            ;;
        --families)
            shift
            fc-list : family | sed "s/[,].*$//g; /^[ ]*$/d" | sort -u
            exit 0
            ;;
        -h|--help)
            echo "$USAGE"
            exit 0
            ;;
        -s|--styles)
            get_family_styles "$font_family"
            exit 0
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

tmpd="${TMPDIR:-/tmp/}$(basename "$0")" && mkdir -p "$tmpd"
tmpf=$(mktemp "$tmpd/XXXX")

font_family_styles=$(get_family_styles "$font_family")
blacklist=$(echo "$blacklist" | sed s/,/\\n/g)
echo "$font_family_styles" > "$tmpf"
blacklisted=$(echo "$blacklist" | grep -Fixvf - "$tmpf")
echo "$blacklisted" > "$tmpf"
common_styles=$(echo "$STYLES" | grep -Fixf "$tmpf" -) # get common lines in predefined sort order

rm -f "$tmpf" # delete the temporary files
rmdir --ignore-fail-on-non-empty "$tmpd"  # delete temporary dir

for font_style in $common_styles; do
    FONT="$font_family:""$font_typesize=""$font_size"":style=""$font_style"
    FONTM="${RED}$font_family${END}:""$font_typesize=""${CYN}$font_size${END}"":style=${YEL}$font_style${END}"
    st -t "ffamily [$font_style]" -f "$FONT" any_key.sh font_test.sh --message="$FONTM" &
    sleep 0.05
done
