#!/bin/sh
# script to automatically copy book to book reader and to backup dir with books
# your user of wheel group could be able to run mount,umount commands without a password:
# $ sudo -e /etc/sudoers
# %wheel ALL=(ALL) NOPASSWD: /usr/bin/mount,/usr/bin/umount

BN="$(basename "$0")" # this script's base name
MOUNT_POINT="/mnt/usb" # your mounting point
SRC_DIR="$HOME/Downloads/books/new" # source dir
BR_DIR="$MOUNT_POINT/~My Books" # book reader destination dir
BU_DIR="/mnt/main/UBERMENSCH/bks_1_fb2_epub" # backup destination dir
UUID="50DC-80CA" # book reader device UUID
DST="string:x-dunst-stack-tag" # dunst tag

# initial values
cp_reader=0; cp_backup=0; errors=0
books_caused_errors=""

OLDIFS="$IFS"
NL='
' # New Line

ok() {
    case "$1" in
        reader) cp_reader=1 ;;
        backup) cp_backup=1 ;;
        error) errors=$((errors+1)) # count errors
    esac
    if [ -n "$2" ] && [ "$1" = "error" ]; then
        # incrementally add every book as new line
        books_caused_errors="$(printf "%s\n%s\n" "$books_caused_errors" "$2")"
    fi
}

UUIDExist() { lsblk -o UUID | grep "$UUID" ;}

notify() {
    case "$1" in
        *error*|*ERROR*) urg="critical" ;;
        *warning*|*WARNING*) urg="normal" ;;
        *) urg="low" ;;
    esac
    dunstify -u "$urg" -h "$DST:book" "[$BN]" "$1"
}

errify() {
    # specifically as simple notification without dunst tag
    notify-send -u critical "[$BN] ERRORS:($errors)" "$1"
}

if UUIDExist; then
    if sudo mount -v UUID=$UUID $MOUNT_POINT -o defaults,uid=1000,gid=998; then
        notify "book reader mounted"
    else
        notify "ERROR: during mounting! exit."
        exit 2
    fi
else
    notify "ERROR: book reader UUID not found! exit."
    exit 1
fi

books="$(find "$SRC_DIR" -type f -name "*.epub" -o -name "*.fb2")"
[ -z "$books" ] && notify "no new books found. exit." && exit 0
IFS="$NL"
for book in $books; do
    # every loop iteration we set these variables to zero for each book
    cp_reader=0; cp_backup=0
    cp -np "$book" --target-directory="$BR_DIR" && ok reader
    cp -np "$book" --target-directory="$BU_DIR" && ok backup
    if [ "$cp_reader" -eq 1 ] && [ "$cp_backup" -eq 1 ]; then
        # we successfully copied book to all directories ->
        # now we can safely remove book from new books dir
        rm -f "$book" # remove book from $SRC_DIR
    elif [ "$cp_reader" -eq 1 ]; then
        ok error "$book"
        errify "ERROR: copied only to book reader!\n$book"
    elif [ "$cp_backup" -eq 1 ]; then
        ok error "$book"
        errify "ERROR: copied only to backup dir!\n$book"
    else
        ok error "$book"
        errify "ERROR: can't copy this book!\n$book"
    fi
done
IFS="$OLDIFS"

if [ "$errors" -gt 0 ]; then
    errify "\n$books_caused_errors\n"
fi

if sudo umount -v UUID=$UUID; then
   notify "ALL DONE: book reader umounted. Farewell."
else
   notify "DONE w ERROR: book copied successfully,\n\
   BUT book reader cannot be umounted.\n\
   Do it manually: 'umount $MOUNT_POINT'"
fi
