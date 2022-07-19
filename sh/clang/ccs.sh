#!/bin/sh
# clang compile
# supports any clang options as trailing args

iext="" # in extension
case "$1" in
    *.c)
        iext=".c"
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

"clang${pp}" "$std" -pedantic -Wall -Wextra -Wabi -static "$@"
