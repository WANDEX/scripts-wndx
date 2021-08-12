#!/bin/sh
# qemu arch test system, specify additional options as arguments
# for first installing specify: -cdrom iso_image -boot menu=on etc.
#
# (to have access to all removable block devices -> define udev rule:
# example: $ cat 55-removable-block-devices.rules
# SUBSYSTEM=="block", ATTR{removable}=="1", OWNER="user"
# do not forget: $ sudo udevadm control --reload && sudo udevadm trigger
#
# to mount usb-flash: -hdd /dev/sde1 ||
# -drive file=/dev/sde1,cache=none,if=virtio ||
# -usb -device usb-host,hostbus=1,hostaddr=4 ||
# -device usb-ehci,id=ehci -device usb-host,bus=ehci.0,vendorid=0x1307,productid=0x0165
#
# to find in list of usb devices (vendorid:productid,etc.) $ lsusb
#
# to mount usb-flash:
# sudo mount -o defaults,uid=1000,gid=998 -v UUID=C0AB-9DEE "/mnt/usb_qemu" >/dev/null 2>&1

img="$HOME/Downloads/QEMU_IMAGES/arch/overlays/arch-basic-auto-wssh.cow"

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
qemu-system-x86_64 $@ -m 4G -enable-kvm -cpu host -usbdevice tablet \
-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:9001-:22 \
-device usb-ehci,id=ehci -device usb-host,bus=ehci.0,vendorid=0x1307,productid=0x0165 \
"$img"
