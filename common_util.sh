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


function tgrep()
{
    export PATTERN="${1?}"
    shift
    for file do
      tar --to-command='
        grep -aPH --label="$TAR_ARCHIVE[$TAR_FILENAME]" -e "$PATTERN" || true
      ' -xf "$file"
    done
}
