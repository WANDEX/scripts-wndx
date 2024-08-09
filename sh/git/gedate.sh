#!/bin/sh
# git edit date of the last preferably unpushed commit

set -e

debug=0

date_default="yesterday"
time_default="23:59:59"

# supports: -1day etc.
date_arg="${1:-$date_default}"
time_arg="${2:-$time_default}"

# mimicking RFC 2822 format (man git-commit) 'DATE FORMATS'
# format strings: date, time, other.
_df="%a, %d %b %Y"
_tf="%T"
_of="%z"
_rfc_fmt="$_df $_tf $_of"

_date=$(date --date="$date_arg" +"$_df")
_time=$(date --date="$time_arg" +"$_tf")
_othr=$(date --date="$date_arg" +"$_of")
_dest="$_date $_time $_othr"

_epoch_cur=$(date --date="now" +%s)
_epoch_dst=$(date --date="$_dest" +%s)

# time traveling allowed only backward from the
# current point in time.
_cpit=$(date --date="@${_epoch_cur}" +"$_rfc_fmt")

print_deb_msg() {
if [ "$debug" -eq 1 ]; then
    echo
    echo "current dt  : $_cpit"
    echo "since epoch : $_epoch_cur"
    echo
    echo "destination : $_dest"
    echo "since epoch : $_epoch_dst"
    echo
fi
}

# forbid traveling forward it time.
if [ "$_epoch_dst" -gt "$_epoch_cur" ]; then
    print_deb_msg
    printf "%s%s%s\n" "${RED_S}" "Time traveling only allowed backward in history!" "${END}"
    printf "%s%s%s\n" "${RED}" "YOU ARE CAUGHT BY THE TIME TRAVEL BUREAU!" "${END}"
    echo "GAME OVER"
    exit 8
fi

printf "%s\n%s" "$_dest" "Set this commit date? [Y/n]: "
read -r REPLY
echo # New Line

ok=0;
case "$REPLY" in
    [Yy]*) ok=1;;
    [Nn]*) exit 7;;
    *) echo "I do not get it. Exit."; exit 5;;
esac
if [ "$ok" -ne 1 ]; then
    echo "${RED}YOU SHOULD NOT BE HERE! EXIT.${END}"
    exit 4
fi

## uncomment -> last chance to stop here, if unsure.
# print_deb_msg ; exit 6

GIT_COMMITTER_DATE="$_dest" git commit --amend --no-edit --date "$_dest"

exit 0

