#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import collections
from operator import itemgetter
from itertools import count

S_PATH = "/home/wndx/Downloads/Pictures/hotline_miami/images/"
l_fullpath = []


def validate_path(s_path):
    if os.path.isdir(s_path):
        print("Provided path is directory:\n{0}".format(str(s_path)))
    else:
        print("Provided path is not directory:\n{0}".format(str(s_path)))
        print("Exiting.")
        quit()


def get_file_paths(s_path):
    d_fullpath = {}
    for (dirpath, dirnames, filenames) in os.walk(s_path):
        for filename in filenames:
            d_fullpath.update({dirpath: filename})
            l_fullpath.extend(d_fullpath.items())
    l_fullpath.sort(key=itemgetter(1))


def line_by_line():
    for line in l_fullpath:
        print("{0}".format(line))


def common_prefix(m):
    """
    Given a list of pathnames, returns the longest common leading component
    """
    if not m:
        return ""
    prefix = m[0]
    for item in m:
        for i in range(len(prefix)):
            if prefix[:i+1] != item[:i+1]:
                prefix = prefix[:i]
                if i == 0:
                    return ""
                break
    return prefix


def main():
    test_list = ["objMonitors_0.png", "objMonitors_1.png", "objMonitors_2.png", "shit"]
    validate_path(S_PATH)
    get_file_paths(S_PATH)
    # print(l_fullpath)
    # line_by_line()
    # print(long_substr())
    # print(l_fullpath.pop(0)[1])
    print(common_prefix(test_list))
    print(len(l_fullpath))


main()
