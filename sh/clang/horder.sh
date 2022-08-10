#!/bin/sh
# header order - print a memo-note about the correct order of #include headers
printf "%s" "\
To maximize the chance that missing includes will be flagged by compiler:
1. The paired header file
2. Other headers from your project
3. 3rd party library headers
4. Standard library headers
-- The headers for each grouping should be sorted alphabetically.
"
