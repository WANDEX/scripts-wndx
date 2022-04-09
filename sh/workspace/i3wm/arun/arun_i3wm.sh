#!/bin/sh
# auto run (execute) scripts inside this file dir

task() {
    echo "$1" | xargs -I % -ot sh -c 'sleep 1.0 && % &>/dev/null'
}

abs_dir_path="$(dirname "$(realpath "$0")")"
bname="$(basename "$0")"
# get abs path of all files excluding .dot files and this file itself
scripts="$(find "$abs_dir_path" -type f -executable \( ! -iname "$bname" \))"

for script in $scripts; do
    task "$script"
done

sleep 2 && i3-msg -q workspace "$WS1"
