#!/bin/sh
# clang compile into out file "basename" without extension & run it

ext=""
case "$1" in
    *.c)
        ext=".c"
    ;;
    *)
        printf "%s\n" "'$1' does not have supported .ext, exit."
        exit 3  # 3 - stands for Ext
    ;;
esac
# basename without .ext
bname="$(basename "$1" "$ext")"
clang -o "$bname" "$1" || exit 1
"./$bname"
