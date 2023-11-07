#!/usr/bin/env bash

source chroot-genboot.sh

cp "images/linux/BOOT.BIN" "/media/$(whoami)/BOOT/"
cp "images/linux/image.ub" "/media/$(whoami)/BOOT/"

