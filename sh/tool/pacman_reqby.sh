#!/bin/sh
# list installed packages required/optional for the pacman package and it's deps.
# pacman -Sii $1
# pacman -Qq $1 REQUIRED BY OR OPTIONAL FOR THE PACKAGE

set -e

bn=$(basename "$0")

OLDIFS="$IFS"
NL='
' # set variable to a new line, to use later as a value in Internal Field Separator

USAGE="\
Usage: ${bn} pacman_package_name
"

case "$1" in
    h|-h|--help|usage)
        echo "$USAGE"
        exit 0
    ;;
esac

[ -n "$1" ] || exit 11
pac_info=$(pacman -Sii "$1")
req_by_="Required By"
con_wi_="Conflicts With"
opt_fo_="Optional For"
req_by=$(echo "$pac_info" \
| sed -n "/$req_by_/,/$con_wi_/p;" \
| sed "/$con_wi_/d; s/$req_by_ *: //; s/$opt_fo_ *: //")


printf "%b%s%b - " "${GRN}" "$1" "${END}"
printf "%b%s:%b\n%s\n" "${BLU}"  "$req_by_" "${END}" "$req_by"
printf "%b%s%b - %s\n" "${CYN}" "^$opt_fo_" "${END}" "at the end (start from the new line)"


printf "\n%b%s%b - %b%s%b\n" "${GRN}" "$1" "${END}" \
"${YEL}" "=== REQUIRED BY OR OPTIONAL FOR THE PACKAGE ===" "${END}"

printf "\n%b%s%b - %s\n" "${GRN}" "$1" "${END}" \
"pacman -Qqd | --deps | packages installed as dependencies:"
IFS=" "
for package_ in $req_by; do
    pacman -Qqd "$package_" 2>/dev/null || true
done

printf "\n%b%s%b - %s\n" "${GRN}" "$1" "${END}" \
"pacman -Qqe | --explicit | explicitly installed packages:"
IFS=" "
for package_ in $req_by; do
    pacman -Qqe "$package_" 2>/dev/null || true
done

IFS="$OLDIFS" # restore

