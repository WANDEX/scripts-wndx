#!/bin/sh
# clang compile into file "basename.out" & run it
# supports any clang options as trailing args after the file name

iext="" # in extension
oext=".out" # out extension
case "$1" in
    *.c)
        iext=".c"
        std="-std=c17"
    ;;
    *.h)
        iext=".h"
        std="-std=c17"
    ;;
    *.cpp)
        iext=".cpp"
        std="-std=c++17"
        pp="++"
    ;;
    *)
        printf "\$1=%s\n" "'$1' does not have supported .ext, exit."
        exit 3  # 3 - stands for Ext
    ;;
esac
[ -z "$iext" ] && exit 2
# out basename replacing .ext on .out
oname=$(basename "$1" | sed "s/$iext$/$oext/")
# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements
"clang${pp}" -Wall "$std" -o "$oname" $@ || exit 1
"./$oname"
