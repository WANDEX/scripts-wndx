#!/bin/sh
# clang compile into file "basename.out" & run it

iext="" # in extension
oext=".out" # out extension
case "$1" in
    *.c)
        iext=".c"
    ;;
    *)
        printf "%s\n" "'$1' does not have supported .ext, exit."
        exit 3  # 3 - stands for Ext
    ;;
esac
[ -z "$iext" ] && exit 2
# basename replacing .ext on .out
bname="$(basename "$1" | sed "s/$iext$/$oext/")"
clang -o "$bname" "$1" || exit 1
"./$bname"
