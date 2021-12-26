#!/bin/sh
# auto find venv dir of the current project from any pwd
# -> simply echo path to the activate script (to copy paste cmd)
# simple echo because => cannot be sourced from non interactive shell
git rev-parse --is-inside-work-tree  >/dev/null 2>&1 || exit 1 # suppress output & errors
if [ -z "$VIRTUAL_ENV" ]; then
    project_root="$(dirname "$(git rev-parse --git-dir)")"
    activate_path="$(find "$project_root" -type f -path "*venv/bin/activate")"
    if [ -n "$activate_path" ]; then
        relative_path="$(realpath --no-symlinks --relative-to="$PWD" "$activate_path")"
        cmd=". $relative_path"
        if hash "clipargs" >/dev/null 2>&1; then
            # if clipargs is found at $PATH -> also copy to clipboard
            clipargs "$cmd"
        fi
        echo "$cmd"
    else
        exit 3
    fi
else
    echo "venv already active."
    exit 2
fi
