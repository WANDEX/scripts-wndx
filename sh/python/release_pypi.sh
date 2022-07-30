#!/bin/sh
# clean build & publish python package to PyPI

# exit if current dir does not have setup.py file
[ -f ./setup.py ] || exit 1

if [ -n "$PYPIRC" ]; then
    pypirc_path="$PYPIRC"
else
    pypirc_path="$HOME/.pypirc"
fi

input_validation() {
    # exit if $1 arg is not a simple argument (should be repository name in .pypirc)
    err_txt="First arg should be arg for option --repository \$1 , exit."
    case "$1" in
        ''|--|-) # empty option
            printf "%s\n" "$err_txt"
            exit 2
            ;;
        --*|-*)
            printf "%s\n" "$err_txt"
            exit 3
            ;;
    esac
}

cdirname=$(basename "$(realpath ./)")

if grep -qs "\[$cdirname\]" "$pypirc_path"; then
    # .pypirc has repository entry with the exact current dir name (project name)
    pypi_repo="$cdirname"
else
    input_validation "$1" # --repository $1
    pypi_repo="" # NOTE: no need for assignment -> already the first arg of $@
fi

# get egg dir name, -d doesn't work with globs * (SC2144)
egg_dir="$(find . -type d -path "./*.egg-info" | head -n1)"

# clean - remove old dirs
[ -d "$egg_dir" ] && rm -rf "$egg_dir"
[ -d ./dist/ ] && rm -rf ./dist/
[ -d ./build/ ] && rm -rf ./build/
printf "%s\n\n" "clean" && sleep 2

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements
# build => upload
python setup.py sdist bdist_wheel &&
printf "\n%s\n\n" "BUILT" && sleep 2 &&
twine upload --repository "$pypi_repo" $@ --config-file "$pypirc_path" dist/* &&
echo "DONE"
