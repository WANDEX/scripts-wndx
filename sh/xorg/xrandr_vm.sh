#!/bin/sh
# env OUTS can be declared in pam env /etc/environment
# make sure nouveau not blacklisted, usually in /usr/lib/modprobe.d/nvidia.conf
# https://wiki.archlinux.org/index.php/Nouveau
# MEMO: to get specific Modeline: $ cvt 1912 1020 60
OUT0="Virtual-1"
vsync="-vsync" # -vsync or +vsync (do not know if it is right to change it)

# Modeline "1912x1040_60.00"  165.00  1912 2032 2232 2552  1040 1043 1053 1079 -hsync +vsync
# xrandr --newmode "1912x1040_60.00"  165.00  1912 2032 2232 2552  1040 1043 1053 1079 -hsync "$vsync" &&
# xrandr --addmode "$OUT0" "1912x1040_60.00" &&
# xrandr --output "$OUT0" --mode "1912x1040_60.00"

# Modeline "1912x1030_60.00"  163.50  1912 2032 2232 2552  1030 1033 1043 1069 -hsync +vsync
# xrandr --newmode "1912x1030_60.00"  165.00  1912 2032 2232 2552  1040 1043 1053 1079 -hsync "$vsync" &&
# xrandr --addmode "$OUT0" "1912x1030_60.00" &&
# xrandr --output "$OUT0" --mode "1912x1030_60.00"

# Modeline "1912x1020_60.00"  161.75  1912 2032 2232 2552  1020 1023 1033 1058 -hsync +vsync
xrandr --newmode "1912x1020_60.00"  161.75  1912 2032 2232 2552  1020 1023 1033 1058 -hsync "$vsync" &&
xrandr --addmode "$OUT0" "1912x1020_60.00" &&
xrandr --output "$OUT0" --mode "1912x1020_60.00"
