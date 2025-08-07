#!/bin/sh
## qemu win10 image.
##
## https://www.spice-space.org/download.html
## https://www.spice-space.org/spice-user-manual.html#_folder_sharing
## Do not forget to enable in WM window: Additional -> Preferences -> enable Share *.
## XXX: Error 0x800700DF: The file size exceeds the limit allowed and cannot be saved.
## while drag & drop of archive file works perfectly. => 'zip -r -0 ./dir.zip ./dir/'
##
## host<->guest: copy & paste, drag & drop.
## NOTE: install inside guest system -  Windows SPICE Guest Tools (spice-guest-tools)
## https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe
##
## NOTE: folder sharing - install inside guest system: spice-webdavd service.
## after install run "C:\Program Files\SPICE webdavd\map-drive.bat"
## https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi
##
## other confs as additional ref:
## github.com/caxapyk/qemu-win10
## github.com/lofyer/spice-webdav
## https://github.com/sej7278/virt-installs/blob/master/win10.sh
## https://bbs.archlinux.org/viewtopic.php?id=203826

img="/mnt/serv1/win/qemu/win10/orig.qcow2"
mac="${MAC:-52:54:98:13:37:10}"
ipv3="${IPV3:-192.168.0}"
netvis="${IP:-${ipv3}.200}"
dhcp="${DHCP:-${ipv3}.210}"
localhost="127.0.0.1"
spc_port="${SPICE:-5930}"

printf "%s\n%s\n%s\n" "$mac" "$netvis" "$dhcp"

## connect for the: c&p, d&d.
# spicy -h "$localhost" -p "$spice" &

bus_name="virtio-serial-bus.0"
spc_name="org.spice-space.webdav.0"
cch_name="charchannel1"

# -device "virtserialport,bus=$bus_name,nr=2,chardev=$cch_name,id=channel1,name=$spc_name" \

# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
qemu-system-x86_64 -enable-kvm -m 8G -cpu host \
-hda "$img" -vga qxl \
-usb -usbdevice tablet -name win10 \
-rtc base=localtime,clock=host \
-nic user,id="net_win10,ipv6=off,model=e1000,mac=${mac},net=${netvis}/24,dhcpstart=${dhcp}" \
-device ich9-intel-hda -device hda-output \
-device virtio-serial-pci -spice port="${spc_port},addr=${localhost},disable-ticketing=on" \
-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
-chardev spicevmc,id=spicechannel0,name=vdagent -display spice-app \
-device "virtserialport,bus=$bus_name,chardev=$cch_name,id=channel1,name=$spc_name" \
-chardev "spiceport,name=$spc_name,id=$cch_name" \
$@
