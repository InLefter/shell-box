#!/bin/bash

function log()
{
    echo "$@"
}

function get_file_format()
{
    local file_path=$1

    local file_format=$(head -c 16 ${file_path} | hexdump -e '16/1 "%02.2x"')
    case "${file_format}" in
    1f8b08*)
        echo "TARGZ"
        ;;
    edabeedb*)
        echo "RMP"
        ;;
    *)
        file_format=$(file ${file_path})
        if [[ $file_format == *"ASCII text"* ]];then
            echo "TEXT"
        else
            log "not support format"
            # exit 1
        fi
        ;;
    esac
}

function main()
{
    ARGS=()

    while [ $# -gt 0 ]; do
        while getopts r: name; do
            case $name in
                r) recursive=true;;
            esac
        done
        [ $? -eq 0 ] || exit 1
        [ $OPTIND -gt $# ] && break

        shift $[$OPTIND - 1]
        OPTIND=1
        ARGS[${#ARGS[*]}]=$1
        shift
    done

    echo "Options: recursive=$recursive"
    echo "Found ${#ARGS[*]} arguments: ${ARGS[*]}"

    # receive src file and dst file
    local src_file=${ARGS[0]}
    local dst_file=${ARGS[1]}

    [[ ! -e ${src_file} ]] && log "${src_file} not exits" && exit 1
    [[ ! -e ${dst_file} ]] && log "${dst_file} not exits" && exit 1
}

main "$@"
