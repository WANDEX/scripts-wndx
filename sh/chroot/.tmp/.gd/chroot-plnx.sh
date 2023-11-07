#!/usr/bin/env bash

schroot -c bionic_amd64 -- /usr/bin/env bash --init-file \
<(echo "source $HOME/.bashrc;" \
"source ~/hdd/Xilinx/Petalinux/2019.1_chrt/settings.sh")

