#!/bin/sh
# check which dependency libs are not installed for given binary as first parameter.
# $1 binary
# $2 is optional:
#   'p' to just print libs
#   's' toggle slow mode (background jobs)

SLOW=0

if [ -z "$1" ]; then
    echo "Provide binary as argument, exit."
    exit 4
fi

# list libs required by provided binary
LIBS=$(objdump -p "$1" | grep NEEDED | awk '{ $1=""; print substr($0,2) }')

case "$2" in
    p|print|show)
        # just print libs of the binary
        echo "$LIBS"
        exit 0
    ;;
    s|slow)
        [ "$SLOW" -eq 1 ] && SLOW=0 || SLOW=1 # toggle behavior of value
    ;;
esac

libcheck() {
    ## Exit codes: 0 = match found; 1 = no match found; 2 = error;
    pacman -F "$1" | grep -q installed
    case "$?" in
        130) exit 130 ;; # ^C interrupted
        0) statusMsg="${CYN}[installed]${END}   ";;
        1) statusMsg="${YEL}[REQUIRED]${END}    ";;
        2) statusMsg="${RED}[ERROR]${END}       ";;
        *) statusMsg="${RED}[WTF IS ($?)?]${END}";;
    esac >/dev/null
    printf "%s %s\n" "$statusMsg" "$1"
}

for lib in $LIBS; do
    if [ "$SLOW" -eq 1 ]; then
        # slowpoke mode
        libcheck "$lib"
    else
        # & - may cause high load (no limit on number of background jobs)
        libcheck "$lib" &
    fi
done
wait # wait till all libs are checked in the background

printf "\nTo find out in which Repo & Package lib exists:\n"
printf "%s\n" "${CYN}pacman -F${END} ..."
