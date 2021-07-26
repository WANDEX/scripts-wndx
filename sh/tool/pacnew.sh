#!/bin/sh
# find all files in /etc/ dir with filename *.pacnew
# show diff and rename pacnew file to original name if all is ok
pacnew=".pacnew"
pacold=".pacold"
arrow="${YEL}->${END}"
pacnew_files="$(sudo find /etc/ -name "*$pacnew")"
num_of_files="$(echo "$pacnew_files" | wc -l)"

at_path() { hash "$1" >/dev/null 2>&1 ;} # if $1 is found at $PATH -> return 0

showdiff() {
    if at_path nvim; then
        nvim -d "$1" "$2"
    elif at_path vim; then
        vimdiff "$1" "$2"
    else
        width="$(tput cols)"
        diff --color=always --width="$width" --side-by-side --suppress-common-lines "$1" "$2"
    fi
}

show_diff_question() {
    while true; do
        echo "${CYN}Show diff for each file?${END} [Y/n/q]:"
        read -n 1 -r
        echo # new line
        case "$REPLY" in
            [Yy]) SDQ=1 ; break ;;
            [Nn]) SDQ=0 ; break ;;
            [Qq]) echo "${MAG}Quit.${END}" ; exit 0 ;;
            *) printf "${YEL}%s${END}\n" "I don't get it." ;;
        esac
        echo # new line
    done
}

action() {
    U="${UND}"
    E="${END}"
    printf " %s: " "[${U}D${E}iff/${U}Q${E}uit/Y/N]"
    read -n 1 -r
    echo # new line
    case "$REPLY" in
        [Dd])
            showdiff "$original_file" "$file"
            action # recursively run this function again, to decide what action to do
            ;;
        [Yy])
            if [ -f "$original_file" ]; then
                sudo mv -f "$original_file" "$pacold_file"
                sudo mv -f "$file" "$original_file"
            else
                sudo mv -f "$file" "$original_file"
            fi
            ;;
        [Nn]) echo "${YEL}OK, i'll SKIP these files.${END}" ;;
        [Qq]) echo "${MAG}Quit.${END}" ; exit 0 ;;
        *) printf "${YEL}%s${END}\n" "I don't get it. SKIP" ;;
    esac
    echo # new line
}

printf "[${YEL}%s${END}] ${BLD}$pacnew files found:${END}\n%s\n" "$num_of_files" "$pacnew_files"
show_diff_question

for file in $pacnew_files; do
    original_file="$(echo "$file" | sed "s/$pacnew//")"
    pacold_file="${original_file}${pacold}"
    if [ -f "$original_file" ]; then
        printf "${BLD}old:${END} %s\n" "$original_file"
        printf "${BLD}${GRN}new:${END} %s\n" "$file"
        [ "$SDQ" -eq 1 ] && showdiff "$original_file" "$file"
        echo "${YEL}^files will be renamed:${END}"
        echo "${BLD}original${END}: '$original_file' ${arrow} '$pacold_file'"
        echo "${GRN}pacnew${END}  : '$file' ${arrow} '$original_file'"
        printf "%s " "${RED}Rename files?${END}"
    else
        printf "${BLD}${GRN}new:${END} %s\n" "$file"
        echo "${YEL}^could be simply renamed. (file without $pacnew does not exist)${END}"
        echo "pacnew  : '$file' ${arrow} '$original_file'"
        printf "%s " "${RED}Rename file?${END}"
    fi
    action
done
