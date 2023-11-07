#!/usr/bin/env bash

set -e

. /opt/Xilinx/19.1/Vivado/2019.1/settings64.sh

petalinux-package --boot --force --fsbl --fpga --u-boot

