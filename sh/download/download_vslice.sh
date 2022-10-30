#!/bin/sh
# download only specific part of video between the two time positions.
# by using mostly ffmpeg and just a little of youtube-dl.

ss="$1" # "04:34:00"
to="$2" # "11:16:11"
url="$3"

bname=$(basename "$0")
USAGE=$(printf "%s" "\
Usage:
    $bname ss_pos to_pos video_url
(The ffmpeg -args but positional):
    ss  - start  from (06:06:06)
    to  - to the time (13:37:00)
    url - of the video to download
")

case "$*" in
    -h|--help|'') echo "$USAGE" && exit 3 ;;
esac

throw_error_position() {
    msg="position must be a time duration specification! Exit."
    printf "\$1:ss & \$2:to\n%s\n" "$msg"
    exit 2
}

verify_time_arg() {
    case "$1" in
        *[0-9]:[0-9][0-9]*) ;; # pass
        *) throw_error_position ;;
    esac
}

verify_time_arg "$ss"
verify_time_arg "$to"

# convert seconds to HH:MM (<24H else the wrap around!)
sec_to_hm() { date --date="@$1" -u +%R ;}
sec_since_epoch() { date +%s ;}

sse_start=$(sec_since_epoch)

input_source=$(youtube-dl -g "$url")
path_end=$(youtube-dl --dump-json --no-warnings --playlist-end=1 "$url" | ytdl_out_path.sh --real)

path_base="${HOME}/Films/.yt/"
out_path="${path_base}${path_end}"

parent_dirs=$(dirname "$out_path")
# create all required parent dirs
[ -d "$parent_dirs" ] || mkdir -p "$parent_dirs"

ffmpeg_cmd() {
    ffmpeg -y -ss "$ss" -to "$to" -i "$input_source" -r 30 "$out_path"
    ffmpeg_exit_code="$?" # exit code
}

ffmpeg_cmd

sse_end=$(sec_since_epoch)
sec_spent=$((sse_end-sse_start))
spent_time=$(sec_to_hm "$sec_spent")
aft_sws="after ${spent_time} were spent!"

if [ "$ffmpeg_exit_code" != "0" ]; then # -ne less safe (by my opinion)
    summary="[$bname] ffmpeg ERROR[$ffmpeg_exit_code]:"
    msg="\nTERMINATED ${aft_sws}\n${out_path}\n"
    notify-send -t 0 -u critical "$summary" "$msg" &
    exit "$ffmpeg_exit_code"
else
    summary="[$bname] finished ${aft_sws}:"
    msg="\n${out_path}\n"
    notify-send -t 0 "$summary" "$msg" &
    exit 0
fi
