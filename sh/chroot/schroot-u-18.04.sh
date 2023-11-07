#!/bin/bash

user="${1:-wndx}" # or root

schroot -c u-18.04 -u "$user"

