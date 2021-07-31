#!/bin/sh
# qemu arch test system, specify additional options as arguments
# for first installing specify: -cdrom iso_image or -boot menu=on etc.
img="$HOME/Downloads/QEMU_IMAGES/arch/arch-test.cow"

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
qemu-system-x86_64 $@ -m 4G -enable-kvm -cpu host -usbdevice tablet "$img"
