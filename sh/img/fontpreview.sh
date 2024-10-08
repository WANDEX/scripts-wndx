#!/bin/sh
#
# Author/Maintainer: Siddharth Dushantha 2020
# Modified & Adapted to POSIX sh: WANDEX 2023
#
# Dependencies: sxiv, imagemagick, xdotool, fzf

VERSION=1.0.8

fzf_cmd="${FZF_DEFAULT_COMMAND:-fzf}"

# Default values
SEARCH_PROMPT=""
# SIZE=800x800
SIZE=600x600
POSITION="+0+0"
FONT_SIZE=24
FG_COLOR="#ffffff"
BG_COLOR="#000000"
# extra text via EXT_TEXT_ENV fix file prefix\
EXT_TEXT_ENV="${EXT_TEXT_ENV:-'extra text via EXT_TEXT_ENV'}"
EXT_TEXT_ENV="fix file prefix" # XXX

BOXDC="\
┌─┬─┐ ╔═╦═╗ ┏━┳━┓        ▏ ▕
├─┼─┤ ╠═╬═╣ ┣━╋━┫ ╭───╮ ╱╲ ╱╲
│ │ │ ║ ║ ║ ┃ ┃ ┃ │ x │ ▏▏╳▕▕
└─┴─┘ ╚═╩═╝ ┗━┻━┛ ╰───╯ ▏───▕
░▒▓█▄▀■ [TERMINAL=$TERMINAL]
"

# U+202F   NARROW NO-BREAK SPACE -> ' '
PREVIEW_TEXT="\
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
абвгдеёжзийклмнопрстуфхцчшщъыьэюя
0123456789 ()[]{}<> '' \"\" \`\`
^%%?!@#$&*№ +-=><-_+ \\/| .,:;
> Almost before we knew it,
we had left the ground.
> Алая вспышка осветила
силуэт зазубренного крыла.
$EXT_TEXT_ENV
"


at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

dependencies="xdotool sxiv magick fzf"
for dep in $dependencies; do
    if ! at_path "$dep"; then
        echo "error: Could not find '${dep}', is it installed?" >&2
        exit 1
    fi
done

USAGE="\
usage: fontpreview [-h] [--size \"px\"] [--position \"+x+y\"] [--search-prompt SEARCH_PROMPT]
                   [--font-size \"FONT_SIZE\"] [--bg-color \"BG_COLOR\"] [--fg-color \"FG_COLOR\"]
                   [--preview-text \"PREVIEW_TEXT\"] [-i font.otf] [-o preview.png] [--version]

┌─┐┌─┐┌┐┌┌┬┐┌─┐┬─┐┌─┐┬  ┬┬┌─┐┬ ┬
├┤ │ ││││ │ ├─┘├┬┘├┤ └┐┌┘│├┤ │││
└  └─┘┘└┘ ┴ ┴  ┴└─└─┘ └┘ ┴└─┘└┴┘
Very customizable and minimal font previewer written in POSIX sh

optional arguments:
   -h, --help            show this help message and exit
   -i, --input           filename of the input font (.otf, .ttf, .woff are supported)
   -o, --output          filename of the output preview image (input.png if not set)
   -b, --box             enable preview of the box characters
   --size                size of the font preview window
   --position            the position where the font preview window should be displayed
   --search-prompt       input prompt of fuzzy searcher
   --font-size           font size
   --bg-color            background color of the font preview window
   --fg-color            foreground color of the font preview window
   --preview-text        preview text that should be displayed in the font preview window
   --version             show the version of fontpreview you are using
"

pre_exit() {
    # Get the proccess ID of this script and kill it.
    # We are dumping the output of kill to /dev/null
    # because if the user quits sxiv before they
    # exit this script, an error will be shown
    # from kill and we dont want that
    ## kill -9 "$(cat "$PIDFILE" 2>/dev/null)" &> /dev/null
    # kill -9 "$(cat "$PIDFILE")" >/dev/null 2>&1
    kill -9 "$(cat "$PIDFILE" 2>&1)" >/dev/null 2>&1

    # Delete tempfiles, so we don't leave useless files behind.
    rm -rf "$FONTPREVIEW_DIR"
}

generate_preview() {
    # Credits: https://bit.ly/2UvLVhM
    magick -size "$SIZE" xc:"$BG_COLOR" \
        -gravity NONE \
        -pointsize "$FONT_SIZE" \
        -font "$1" \
        -fill "$FG_COLOR" \
        -annotate +30+50 "$PREVIEW_TEXT" \
        -flatten "$2"
}

main() {
    # Checkig if needed dependencies are installed
    # Checking for enviornment variables which the user might have set.
    # This config file for fontpreview is pretty much the bashrc, zshrc, etc
    # Majority of the variables in fontpreview can changed using the enviornment variables
    # and this makes fontpreview very customizable
    [ -n "$FONTPREVIEW_SEARCH_PROMPT" ] && SEARCH_PROMPT="$FONTPREVIEW_SEARCH_PROMPT"
    [ -n "$FONTPREVIEW_SIZE" ]          && SIZE="$FONTPREVIEW_SIZE"
    [ -n "$FONTPREVIEW_POSITION" ]      && POSITION="$FONTPREVIEW_POSITION"
    [ -n "$FONTPREVIEW_FONT_SIZE" ]     && FONT_SIZE="$FONTPREVIEW_FONT_SIZE"
    [ -n "$FONTPREVIEW_BG_COLOR" ]      && BG_COLOR="$FONTPREVIEW_BG_COLOR"
    [ -n "$FONTPREVIEW_FG_COLOR" ]      && FG_COLOR="$FONTPREVIEW_FG_COLOR"
    [ -n "$FONTPREVIEW_PREVIEW_TEXT" ]  && PREVIEW_TEXT="$FONTPREVIEW_PREVIEW_TEXT"

    # Save the window ID of the terminal window fontpreview is executed in.
    # This is so that when we open up sxiv, we can change the focus back to
    # the terminal window, so that the user can search for the fonts without
    # having to manualy change the focus back to the terminal.
    xdotool getactivewindow > "$TERMWIN_IDFILE"

    # Flag to run some commands only once in the loop
    FIRST_RUN=true

    while true; do
        # List out all the fonts which imagemagick is able to find, extract
        # the font names and then pass them to fzf
        font=$(magick -list font | awk -F: '/^[ ]*Font: /{print substr($NF,2)}' | $fzf_cmd --prompt="$SEARCH_PROMPT")

        # Exit if nothing is returned by fzf, which also means that the user
        # has pressed [ESCAPE]
        [ -z "$font" ] && return

        generate_preview "$font" "$FONT_PREVIEW"

        if [ "$FIRST_RUN" = true ]; then
            FIRST_RUN=false

            # Display the font preview using sxiv
            #sxiv -g "$SIZE$POSITION" "$FONT_PREVIEW" -N "fontpreview" -b &
            sxiv -N "fontpreview" -b -g "$SIZE$POSITION" "$FONT_PREVIEW" &

            # Change focus from sxiv, back to the terminal window
            # so that user can continue to search for fonts without
            # having to manually change focus back to the terminal window
            xdotool windowfocus "$(cat "$TERMWIN_IDFILE")"

            # Save the process ID so that we can kill
            # sxiv when the user exits the script
            echo $! >"$PIDFILE"

        # Check for crashes of sxiv
        elif [ -f "$PIDFILE" ] ; then
            if ! pgrep -F "$PIDFILE" >/dev/null 2>&1; then
            echo "Restart sxiv - You maybe using a obsolete version. " >&2
            # Display the font preview using sxiv
            sxiv -g "$SIZE$POSITION" -N "fontpreview" -b "$FONT_PREVIEW" &

            # Change focus from sxiv, back to the terminal window
            # so that user can continue to search for fonts without
            # having to manually change focus back to the terminal window
            xdotool windowfocus "$(cat "$TERMWIN_IDFILE")"

            # Save the process ID so that we can kill
            # sxiv when the user exits the script
            echo $! >"$PIDFILE"
            fi
        fi
    done
}

# Disable CTRL-Z because if we allowed this key press,
# then the script would exit but, sxiv would still be
# running
trap "" TSTP

trap pre_exit EXIT

# Use mktemp to create a temporary directory that won't
# collide with temporary files of other application.
FONTPREVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fontpreview_dir.XXXXXXXX")" || exit
PIDFILE="$FONTPREVIEW_DIR/fontpreview.pid"
touch "$PIDFILE" || exit
FONT_PREVIEW="$FONTPREVIEW_DIR/fontpreview.png"
touch "$FONT_PREVIEW" || exit
TERMWIN_IDFILE="$FONTPREVIEW_DIR/fontpreview.termpid"
touch "$TERMWIN_IDFILE" || exit

font="$1"


# Parse the arguments
options=$(getopt -o bhi:o: --long box,position:,size:,version,search-prompt:,font-size:,bg-color:,fg-color:,preview-text:,input:,output:,help -- "$@")
eval set -- "$options"
while true; do
case "$1" in
    -b|--box)
        PREVIEW_TEXT="${PREVIEW_TEXT}${BOXDC}"
        ;;
    --size)
        shift
        FONTPREVIEW_SIZE="$2"
        ;;
    --position)
        shift
        FONTPREVIEW_POSITION="$2"
        ;;
    -h|--help)
        echo "$USAGE"
        exit
        ;;
    --version)
        echo "$VERSION"
        exit
        ;;
    -i|--input)
        input_file="$2"
        ;;
    -o|--output)
        output_file="$2"
        ;;
    --search-prompt)
        FONTPREVIEW_SEARCH_PROMPT="$2"
        ;;
    --font-size)
        FONTPREVIEW_FONT_SIZE="$2"
        ;;
    --bg-color)
        FONTPREVIEW_BG_COLOR="$2"
        ;;
    --fg-color)
        FONTPREVIEW_FG_COLOR="$2"
        ;;
    --preview-text)
        FONTPREVIEW_PREVIEW_TEXT="$2"
        ;;
    --)
        shift
        break
        ;;
esac
shift
done


# Point a font file to fontpreview.sh and it will preview it.
# Example:
#   $ fontpreview.sh /path/to/fontFile.ttf
#
# This is useful because people can preview fonts which they have not
# installed onto their system. So if they want to preview a font file that
# is in their Downloads directory, then they can easily preview it.
if [ -f "$font" ]; then
    generate_preview "$font" "$FONT_PREVIEW"

    # Display the font preview using sxiv
    sxiv -g "$SIZE$POSITION" -N "fontpreview.sh" -b "$FONT_PREVIEW" &

    # For some strange reason, sxiv just doesnt have time to read the file
    sleep 0.1
    exit
fi

# Check if the user gave an input file if they did, then create a preview
# and then save the preview to the current working directory
if [ -n "$input_file" ] ; then
    [ -z "$output_file" ] && output_file="${input_file}.png"
    generate_preview "$input_file" "$output_file"
    exit
fi

main

