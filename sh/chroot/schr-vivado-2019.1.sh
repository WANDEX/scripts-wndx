#!/bin/bash
# see here for the useful notes:
# https://wiki.archlinux.org/title/Xilinx_Vivado
# -l option to read env variables from the ~/.profile
# essential env variables defined inside chroot ~/.profile

nolog=""
nojournal=""

## comment or uncomment
nolog="-nolog"
nojournal="-nojournal"

schroot -c u-18.04 -- /bin/bash -l -c "
. /opt/Xilinx/19.1/Vivado/2019.1/settings64.sh &&
exec /opt/Xilinx/19.1/Vivado/2019.1/bin/vivado $nolog $nojournal"

