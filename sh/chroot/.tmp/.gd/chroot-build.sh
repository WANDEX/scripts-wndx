#!/usr/bin/env bash

schroot -c bionic_amd64 -- /usr/bin/env bash -c \
"source ~/hdd/Xilinx/Petalinux/2019.1_chrt/settings.sh && petalinux-config \
--silentconfig --get-hw-description='../fpga/vivado_project/rfsoc.sdk/' && petalinux-build"

