#!/bin/bash

function call_func()
{
    echo "===>${1}:[arg:${@:2}]"
    "$@"
    ret=$?
    echo "<===${1}:[ret:${ret}]"
    return $ret
}

cat *.tar.gz | tar -zxf - -i --to-command='grep -Hn --label="$TAR_ARCHIVE/$TAR_FILENAME" -E "regex_pattern" || true'
