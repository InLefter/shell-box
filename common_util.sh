#!/bin/bash

function call_func()
{
    echo "===>${1}:[arg:${@:2}]"
    "$@"
    ret=$?
    echo "<===${1}:[ret:${ret}]"
    return $ret
}
