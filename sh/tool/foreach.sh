#!/bin/sh
# take input lines from pipe and for each line execute all provided arguments
# provide -h flag to see examples.

bn=$(basename "$0")
f="${BLD}${ITQ}"

OLDIFS="$IFS"
# set variable to a new line, to use later as a value in Internal Field Separator
NLIFS='
'

USAGE="\
Usage: 'pipe any multiline data' | ${bn} | [ARGS...]

USAGE ${BLD}EXAMPLES:${END}

${f}# grep all files with pattern and sed -i replace pattern strings:${END}
grep -l -r '\$BASH_SOURCE' | ${bn} | xargs sed -i 's/\$BASH_SOURCE/\"\$0\"/'
${f}# ^ same but with ripgrep:${END}
rg -l

${f}# grep from each *.diff file in current dir:${END}
find . -type f -name *.diff | ${bn} | xargs grep -i 'Only in'

${f}# sed -i delete lines with pattern strings in all *.diff files at current dir:${END}
find . -type f -name *.diff | ${bn} | xargs sed -i '/Only in/d'

${f}# sed -i replace pattern strings in all *.diff files at current dir:${END}
find . -type f -name *.diff | ${bn} | xargs sed -i 's/Only in/SED_REPLACEMENT/g'

${f}# find all files in current dir except *bad* and *out*, sort, concatenate and redirect into file:${END}
find . -type f -name *.diff \( ! -iname *bad* ! -iname *out* \) | sort -n | ${bn} | xargs cat > bad.diff

${f}# append text with the extra new line to the end of the files:${END}
fd -t f . | ${bn} | xargs sed -i '$ a END_OF_THE_FILE\\\\n'
"

case "$1" in
    h|-h|--help|usage)
        echo "$USAGE"
        exit 0
        ;;
esac

# if tty and something is piped into the script
if [ ! -t 0 ]; then
    pipe=$(cat) # /dev/stdin pipe used usually
else
    exit 1 # silently exit.
fi

IFS="$NLIFS"
# do any provided arguments for each line
for line in $pipe; do
    echo "$line" "$@"
done
IFS="$OLDIFS" # restore

