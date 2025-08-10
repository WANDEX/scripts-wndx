#!/bin/sh
## print all unique file extensions recursively found in a dir.
## all trailing arguments are passed to the fd|find util.

OLDIFS="$IFS"
debug=0

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

printe() {
  at_path printf || exit 63
  if [ "$#" = 1 ]; then
    printf "%s\n" "$*" 1>&2
  else # shellcheck disable=SC2059 # intentional - re-split any amount of arguments.
    printf "$@" 1>&2
  fi
}

deps="fd|find rg|perl sort"
IFS=" " # split arguments by space
for exes in $deps; do
    ok=0
    IFS="|" # split arguments by | alternatives if any
    for exe in $exes; do
        if at_path "$exe"; then
            ok=$((ok+1))
            if [ $debug -eq 1 ]; then
                printe "FOUND [$ok] : $exes '$exe'"
                continue # check all alternatives
            fi
            break # accept first found
        fi
    done
    if [ $ok -eq 0 ]; then
        printe "'$exes' - REQUIRED DEPENDENCY NOT FOUND AT \$PATH! EXIT."
        exit 66
    fi
    IFS=" " # split arguments by space
done
IFS="$OLDIFS" # restore

## main

files=""
if at_path fd; then
    files=$(fd -t f "$@")
elif at_path find; then
    files=$(find . -type f "$@")
fi

exts=""
if at_path rg; then
    exts=$(echo "$files" | rg -or '$1' ".*\.(\w+)$")
elif at_path perl; then
    exts=$(echo "$files" | perl -ne 'print $1 if m/\.([^.\/]+)$/')
fi

echo "$exts" | sort -u
