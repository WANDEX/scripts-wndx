#!/bin/sh
DIR="/mnt/usb_qemu/"
mkdir -p "$DIR"
case "$1" in
    [Uu]|[Uu]mount)
        fusermount3 -u "$DIR" &&
        echo "Umounted!"
    ;;
    *)
        sshfs root@localhost:/ "$DIR" -p 9001 &&
        echo "Mounted!"
    ;;
esac
