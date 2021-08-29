#!/bin/bash

[ -z "$COLUMNS" ] && {
    COLUMNS=$(tput cols 2> /dev/null)
}
[ -z "$COLUMNS" ] && {
    COLUMNS=$(stty size 2> /dev/null | awk '{print $2}')
}
echo $COLUMNS
