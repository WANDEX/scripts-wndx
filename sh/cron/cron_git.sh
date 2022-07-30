#!/bin/sh
# generic script for cron that commits & pushes to the repo (all files)
# to exclude certain files/dirs, add them to the .gitignore
# (it is far more easier & robust than using exclude syntax in 'git add')
#
### MEMO - how to exclude with(out) quotes (the same):
##  git add --all -- :^dir/ :^*2021* ':!*2022*' ':!.gitignore'

CSCRDIR="${CSCRDIR:-"$HOME/.cache/cscripts"}"
LOGDIR="$CSCRDIR/logs/" && [ ! -d "$LOGDIR" ] && mkdir -p "$LOGDIR"
bn=$(basename -s ".sh" "$0")
LOG="$LOGDIR/$bn.log"

PROJDIR="$1"

PROJDIR=$(echo "$PROJDIR" | sed "s/\/$//") # remove last slash character if exist
[ -d "$PROJDIR" ]      || exit 1
[ -d "$PROJDIR/.git" ] || exit 2 # exit if dir doesn't have .git sub-dir
  cd "$PROJDIR"        || exit 3

dname=$(basename "$PROJDIR")
date=$(date +%F)
time=$(date +%T)
msg=$(printf "%s [%s] (%s) %s\n" "$date" "$time" "$dname" "repo auto commit")

git add --all

commit_msg=$(git commit -m "$msg")
exit_code="$?"
case "$exit_code" in
    0)  # ok - has something to commit
        git push origin
        echo "$msg" >> "$LOG"
        exit 0
    ;;
    1)  # ok - nothing to commit, working tree clean
        exit 0
    ;;
    *)  # unhandled exit code - log fail with exit code
        echo "$msg" >> "$LOG"
        # also append commit msg (surround with empty lines to easily delete by paragraph later)
        printf "\n^[U:(%s)] commit msg of unhandled exit code:\n%s\n\n" \
            "$exit_code" "$commit_msg" >> "$LOG"
        exit "$exit_code"
    ;;
esac
