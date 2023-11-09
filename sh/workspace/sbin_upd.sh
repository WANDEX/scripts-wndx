#!/bin/sh
# make/update symlinks of all executable files in the sbin dir

set -e

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

OLDIFS="$IFS"
NL='
' # New Line

git rev-parse --is-inside-work-tree  >/dev/null 2>&1 || exit 7 # suppress output & errors


git_root_dir=$(realpath "$(dirname "$(git rev-parse --git-dir)")")

dir_sh="${git_root_dir}/sh"
dir_py="${git_root_dir}/py"
dir_pth="${git_root_dir}/.pth"

[ -d "$dir_sh"   ] || exit 8
[ -d "$dir_py"   ] || exit 9
[ -d "$dir_pth"  ] || exit 10

dir_sbin="${dir_pth}/sbin"
[ -d "$dir_sbin" ] || mkdir -p "$dir_sbin"


if at_path fd; then
    fpaths=$(fd . "$dir_sh" --no-ignore -t x -t l)
else
    fpaths=$(find . "$dir_sh" -type f -type l -executable)
fi

rm -f "${dir_sbin}/*"
printf "%s ${CYN}%s${END}\n" "  cleaned:" "$dir_sbin"

IFS="$NL"
for fpath in $fpaths; do
    ln -sf "$fpath" "$dir_sbin"
done
IFS="$OLDIFS"
printf "%s ${GRN}%s${END}\n" "populated:" "$dir_sbin"

