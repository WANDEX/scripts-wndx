#!/usr/bin/env bash

set -e

#source schr-genboot.sh

mnt_part_boot="/media/$(whoami)/BOOT/"
mountpoint -q "$mnt_part_boot" || exit 20

bootbin="./images/linux/BOOT.BIN"
imageub="./images/linux/image.ub"
[ -f "$imageub" ] || exit 8
[ -f "$bootbin" ] || exit 9

sudo cp "$bootbin" "$imageub" "$mnt_part_boot" &&
echo "[ OK ] BOOT.BIN copied"

