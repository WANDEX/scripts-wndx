#!/bin/sh
## diff cmd with the predefined flags.
##
## MEMO: -X ~/exclude_patterns.txt

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements

set -e

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

## if found at path and pipe were not used:
if at_path page && [ -t 1 ]; then
    diff -up -rw --strip-trailing-cr $@ | page -w -t diff
else
    diff -up -rw --strip-trailing-cr $@
fi

