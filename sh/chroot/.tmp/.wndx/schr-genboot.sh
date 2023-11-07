#!/usr/bin/env bash

set -e

schroot -c u-18.04 -- /bin/bash -c "
. /opt/Xilinx/19.1/Vivado/2019.1/settings64.sh && \
petalinux-package --boot --force --fsbl --fpga --u-boot"

