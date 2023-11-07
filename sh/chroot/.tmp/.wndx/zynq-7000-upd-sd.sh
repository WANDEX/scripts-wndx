#!/usr/bin/env bash
# update partitions on SD card (for the zynq 7000)

set -e

./zynq-7000-copy-boot.sh
./zynq-7000-copy-rootfs.sh

sync && echo "[ OK ] sync complete"

# umount after successfully copying
mnt_part_boot="/media/$(whoami)/BOOT/"
mnt_part_rootfs="/media/$(whoami)/ROOTFS/"
mountpoint -q "$mnt_part_boot"   && sudo umount "$mnt_part_boot"   && echo "[ OK ] BOOT   umounted!"
mountpoint -q "$mnt_part_rootfs" && sudo umount "$mnt_part_rootfs" && echo "[ OK ] ROOTFS umounted!"

