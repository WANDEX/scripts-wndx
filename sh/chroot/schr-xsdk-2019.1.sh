#!/bin/bash
# see here for the useful notes:
# https://wiki.archlinux.org/title/Xilinx_Vivado
# -l option to read env variables from the ~/.profile
# essential env variables defined inside chroot ~/.profile

# exec $SHELL needed to not let application die after forking app to the background
# FIXME: works like this only from the terminal (dies from dmenu)
schroot -c u-18.04 -- /bin/bash -l -c "
. /opt/Xilinx/19.1/SDK/2019.1/settings64.sh &&
/opt/Xilinx/19.1/SDK/2019.1/bin/xsdk && exec $SHELL"


