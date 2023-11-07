#!/bin/sh

# if $1 is found at $PATH -> return 0
hash "$1" >/dev/null 2>&1

