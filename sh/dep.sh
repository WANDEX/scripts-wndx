#!/bin/sh
# check which dependency libs are not installed for given binary as first parameter.
# $1 binary, $2 is optional: 'p' to just print libs

if [ -z "$1" ]; then
    echo "Provide binary as argument, exit."
    exit 4
fi

# list libs required by provided binary
LIBS=$(objdump -p "$1" | grep NEEDED | awk '{ $1=""; print substr($0,2) }')
case "$2" in
    p|s|print|show)
        # just print libs of the binary
        echo "$LIBS"
        exit 0
    ;;
esac

for lib in $LIBS; do
    ## Exit codes: 0 = match found; 1 = no match found; 2 = error;
    pacman -F "$lib" | grep -q installed
    case "$?" in
        0) statusMsg="${CYN}[installed]${END}...";;
        1) statusMsg="${RED}[REQUIRED]${END}....";;
        2) statusMsg="${RED}[ERROR]${END}.......";;
        *) statusMsg="${RED}[??? WTF ???]${END}." && exit 1 ;;
    esac >/dev/null
    printf "%s %s\n" "$statusMsg" "$lib"
done

printf "\nTo find out in which Repo & Package lib exists:\n"
printf "%s\n" "${CYN}pacman -F${END} ..."
