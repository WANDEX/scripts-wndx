#!/bin/bash
# download audio from all urls taken from pipe (each on its own line)
# NOTE: do not use with -r --restrict!
# NOTE to bypass geo restriction:
# -y '--proxy socks5://127.0.0.1:9050/'

DLOG="$HOME/durls_not_downloaded_urls"

if [ ! -t 0 ]; then
    # if something were piped into the script
    PIPE=$(cat)
else
    echo "Usage:"
    echo "cat file_path | $(basename "$0")"
    echo "Nothing were piped! Exit."
    exit 1
fi


pre_process_piped_content() {
    if [ -n "$PIPE" ]; then
        # remove everything after # character and empty lines with/without spaces
        URLS="$(echo "$PIPE" | sed "s/[[:space:]]*#.*$//g; /^[[:space:]]*$/d")"
        # return total number of lines (trimming whitespaces)
        URLL="$(echo "$URLS" | wc -l | sed "s/[ ]\+//g")"
    else
        echo "Empty PIPE. Exit"
        exit 2
    fi

}

statistic() {
    exit_code="$1"
    _url="$2"
    # initial values
    [ -z "$ok" ] && ok=0
    [ -z "$err" ] && err=0
    [ -z "$sum" ] && sum=0
    case "$exit_code" in
        0)
            ok=$((ok + 1))
            printf "[%s/%s]\n" "$ok" "$URLL"
        ;;
        *)
            err=$((err + 1))
            printf "[%s(%s)]\n" "ERROR:" "$exit_code"
            # do not append the same url (line) more than once
            if ! grep -qsF -x "$_url" "$DLOG" >/dev/null 2>&1; then
                # append to the log - urls which failed
                echo "$_url" >> "$DLOG"
            fi
        ;;
    esac
    sum=$((ok + err))
    if [ "$URLL" -eq "$ok" ]; then
        printf "[%s] %s\n" "$ok" "ALL OK, FINISHED."
    elif [ "$URLL" -eq "$sum" ]; then
        printf "%s [%s] %s\n" "FINISHED WITH" "$err" "ERRORS."
    fi
}

pre_process_piped_content
[ -z "$URLS" ] && exit 3

# read line by line
while IFS= read -r url; do
    # support all args of the script
    download_audio.sh -n -u "$url" "$@"
    statistic "$?" "$url"
done <<< "$URLS"
