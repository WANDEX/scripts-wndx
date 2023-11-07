#!/usr/bin/env bash

set -e

mnt_part_rootfs="/media/$(whoami)/ROOTFS/"
mountpoint -q "$mnt_part_rootfs" || exit 21

rootfs="./images/linux/rootfs.tar.gz"
[ -f "$rootfs" ] || exit 12

sudo tar -zxf "$rootfs" -C "$mnt_part_rootfs" &&
echo "[ OK ] rootfs.tar.gz extracted"

