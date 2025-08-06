#!/bin/sh
# qemu win10 image.
# via spice supports host<->guest: copy & paste, drag & drop.
# NOTE: install inside guest system -  Windows SPICE Guest Tools (spice-guest-tools)
# https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe
#
# other conf as a ref: github.com/caxapyk/qemu-win10

img="/mnt/serv1/win/qemu/win10/orig.qcow2"
mac="${MAC:-52:54:98:13:37:10}"
ipv3="${IPV3:-192.168.0}"
netvis="${IP:-${ipv3}.200}"
dhcp="${DHCP:-${ipv3}.210}"
localhost="127.0.0.1"
spice="${SPICE:-5930}"
# shr_dir="${:-$SHR_DIR}"
# shr_dir="$SHR_DIR"

printf "%s\n%s\n%s\n" "$mac" "$netvis" "$dhcp"

# [ -d "$shr_dir" ] || exit 21

## connect for the: c&p, d&d.
spicy -h "$localhost" -p "$spice" &

## shared dir support - spice webdav
# -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel1,id=channel1,name=org.spice-space.webdav.0 \
# -chardev spiceport,name=org.spice-space.webdav.0,id=charchannel1 \

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
qemu-system-x86_64 -enable-kvm -m 8G -cpu host \
-hda "$img" -vga qxl \
-usb -usbdevice tablet -name win10 \
-rtc base=localtime,clock=host \
-nic user,id="net_win10,ipv6=off,model=e1000,mac=${mac},net=${netvis}/24,dhcpstart=${dhcp}" \
-device ich9-intel-hda -device hda-output \
-device virtio-serial-pci -spice port="${spice},addr=${localhost},disable-ticketing=on" \
-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
-chardev spicevmc,id=spicechannel0,name=vdagent -display spice-app \
$@
