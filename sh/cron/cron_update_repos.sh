#!/bin/sh
# cron script that pushes to the repo output of repos script
# .git dir should exist at $DIR for git commands!

cd ~ || exit # cd to home dir

name="repos"

CSCRDIR="${CSCRDIR:-"$HOME/.cache/cscripts"}"
SCRIPTS="${SCRIPTS:-"$HOME/source/scripts"}"

BN="$(basename "$0")"
DIR="$CSCRDIR/cron/packages"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
CACHE="$DIR/$name"

# find full path of executable script (required for cron)
script="$(find "$SCRIPTS" -type f -executable -name "$name")"
[ -z "$script" ] && echo "[$BN] ERROR: FNF. exit." && exit 3

output="$("$script" -aur)" # -aur to exclude aur repos from output
[ -z "$output" ] && echo "[$BN] ERROR: output is empty. exit." && exit 4

# Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.
changes="$(echo "$output" | diff -N "$CACHE" -)"
case "$?" in
    0) exit 0 ;;
    1)
        cd "$DIR" || exit
        [ ! -d .git ] && exit # exit if current dir doesn't have .git dir
        time="$(date "+%T")"
        message="$(printf "%s\n\n%s\n" "repos auto commit at: $time" "$changes")"
        echo "$output" > "$CACHE" # save output to cache
        git add repos # add only repos file!
        git commit -m "$message"
        git push origin
        ;;
    2) exit 2 ;;
esac
