#!/bin/sh
# cron script that pushes to gist explicitly installed packages
# pacman, aur, pip
# .git dir should exist at $DIR for git commands!

CSCRDIR="${CSCRDIR:-"$HOME/.cache/cscripts"}"

DIR="$CSCRDIR/cron/packages"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
PACMAN_CACHE="$DIR/pacman"
AUR_CACHE="$DIR/aur"
PIP_CACHE="$DIR/pip"

pacman_list="$(pacman -Qqe -n)"
aur_list="$(pacman -Qqe -m)" # AUR and other foreign packages that have been explicitly installed.

# intentionally with two variables to prevent broken pipe error!
pip_list="$(python3 -m pip list --user --not-required)" # user packages without their dependencies
pip_list="$(echo "$pip_list" | tail -n +3 | awk '{print $1}')" # only package name, skip header (first 2 lines)

# tail to skip first 3 lines
diff_lists() { diff -N -U0 "$1" - | tail -n +4 ; }

pchanges="$(echo "$pacman_list" | diff_lists "$PACMAN_CACHE")"
achanges="$(echo "$aur_list" | diff_lists "$AUR_CACHE")"
pipanges="$(echo "$pip_list" | diff_lists "$PIP_CACHE")"

# if not empty it's differ -> update cache file
[ -n "$pchanges" ] && _pac=1; echo "$pacman_list" > "$PACMAN_CACHE"
[ -n "$achanges" ] && _aur=1; echo "$aur_list" > "$AUR_CACHE"
[ -n "$pipanges" ] && _pip=1; echo "$pip_list" > "$PIP_CACHE"

# if any of the following variables defined -> do git commands
if [ "$_pac" ] || [ "$_aur" ] || [ "$_pip" ]; then
    cd "$DIR" || exit
    [ ! -d .git ] && exit # exit if current dir doesn't have .git dir
    time="$(date "+%T")"
    message="$(printf "%s\n\n%s\n\n%s\n\n%s\n" "auto commit at: $time" "$achanges" "$pchanges" "$pipanges")"
    git add .
    git commit -m "$message"
    git push origin
fi
