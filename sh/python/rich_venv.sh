#!/bin/sh
# enable rich traceback & pprint() in venv without installing rich into that venv
# venv should be deactivated - to be able to find globally installed module location
# (located outside of venv)

venv_dir_name="${1:-venv}"

find_module() {
    _site_packages="$(python3 -m pip show "$1" | sed -n "0,/Location: /s///p")"
    module_dir="${_site_packages}/$1"
    if [ ! -d "$module_dir" ]; then
        echo "$1: module not found, exit."
        exit 2
    fi
    echo "$module_dir"
}

symlink_module() {
    ln -s "$1" "$2"
}

if [ ! -d "venv" ]; then
    printf "${BLD}%s${END} ${RED}%s${END}\n%s\n" "$venv_dir_name" \
        "dir not found in current dir!" \
        "cd to dir with '$venv_dir_name' dir and run me again!"
    exit 1
fi

rich="$(find_module "rich")"
pygments="$(find_module "pygments")"

venv_lib="$venv_dir_name/lib"
# find first found site-packages dir
site_packages="$(find "$venv_lib" -type d -name "site-packages" | head -n1)"
# create symlinks on pygments and rich in venv project
symlink_module "$rich" "$site_packages"
symlink_module "$pygments" "$site_packages"

file="$site_packages/sitecustomize.py"
touch "$file"
printf "%s\n%s\n%s\n" \
    "from rich.pretty import pprint" \
    "from rich.traceback import install" \
    "install(show_locals=False)" >> "$file"
