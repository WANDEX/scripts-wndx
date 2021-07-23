#!/bin/sh
# create new file with clipboard content in $DIR

DIR="$1" # use $1 as dir for frames
[ -z "$DIR" ] && echo "provide \$1 dir. exit." && exit 1
total_files="$(find "$DIR" -type f | wc -l | sed "s/[ ]\+//g")" # remove whitespace from number
[ -z "$total_files" ] && notify-send -u critical "ERROR: empty $total_files" "exit." && exit 2
n=$((total_files+1))
new_name="f_${n}"
# write to new file_n
xsel -o --clipboard > "$DIR/$new_name"
