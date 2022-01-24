#!/bin/sh
# clean build & publish python package to PyPI

# exit if current dir does not have setup.py file
[ -f ./setup.py ] || exit 1

# get egg dir name, -d doesn't work with globs * (SC2144)
egg_dir="$(find . -type d -path "./*.egg-info" | head -n1)"

# clean - remove old dirs
[ -d "$egg_dir" ] && rm -rf "$egg_dir"
[ -d ./dist/ ] && rm -rf ./dist/
[ -d ./build/ ] && rm -rf ./build/
printf "%s\n\n" "clean" && sleep 2

# build => upload
python setup.py sdist bdist_wheel &&
printf "\n%s\n\n" "BUILT" && sleep 2 &&
twine upload dist/* &&
echo "DONE"
