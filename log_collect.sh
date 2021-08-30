#!/bin/bash

# lc reads your custom log files in pattern, 
# do some simple analysis and display result
# in console.

[ -z "$COLUMNS" ] && {
    COLUMNS=$(tput cols 2> /dev/null)
}
[ -z "$COLUMNS" ] && {
    COLUMNS=$(stty size 2> /dev/null | awk '{print $2}')
}

_format_table_char_top_left="┌"
_format_table_char_horizontal="─"
_format_table_char_vertical="│"
_format_table_char_bottom_left="└"
_format_table_char_bottom_right="┘"
_format_table_char_top_right="┐"
_format_table_char_vertical_horizontal_left="├"
_format_table_char_vertical_horizontal_right="┤"
_format_table_char_vertical_horizontal_top="┬"
_format_table_char_vertical_horizontal_bottom="┴"
_format_table_char_vertical_horizontal="┼"


function _format_table_prettify_lines() {
    cat - | sed -e "s@^@${_format_table_char_vertical}@;s@\$@	@;s@	@	${_format_table_char_vertical}@g" | tee tpl.log
}

function _format_table_fix_border_lines() {
    echo ${1}
    for i in "$1"
    do
        echo $i
    done
    cat - | tee zz.log | sed -e "1s@ @${_format_table_char_horizontal}@g;3s@ @${_format_table_char_horizontal}@g;\$s@ @${_format_table_char_horizontal}@g;"
}

function _format_table_awk_wrap() {
    cat - | awk -F\│ -v COL=$COLUMNS '{
    ROWS=NR
    if(NF==1){
        HOLD_DATA[NR]=$0
        next
    }
    FSL=length(FS)*(NF-1)
    NFL=NF
    for(i=2;i<NF;i++) {
        gsub("\t", " ", $i)
        $i=trim($i)
        LEND[NR,i-1]=length($i)
        DATA[NR,i-1]=$i
        I[NR]
        J[i-1]
    }
}END{
    col_len_aval=COL-FSL
    col_average_len=int(col_len_aval/NFL)
    # calculate max length of every col
    for(j in J) {
        colL[j]=0
        for(i in I) {
            colL[j]=max(colL[j],LEND[i,j])
        }
        # printf "colL[%d], %d, \n", j, colL[j]
    }
    # printf "FS: %s\n", FS
    # printf "col_len_aval: %d\n", col_len_aval
    # sort for analysis which col will be wrapped.
    n=asorti(colL, sortedcolL)
    for(j=1; j<=n; j++) {
        # printf "%d,",col_len_aval
        colL[sortedcolL[j]] = min(colL[sortedcolL[j]], col_average_len)
        col_len_aval = col_len_aval - colL[sortedcolL[j]] - FSL
        if (j < n) {
            col_average_len = int(col_len_aval / (n - j))
        }
        # printf "%d:%d,",sortedcolL[j],colL[sortedcolL[j]]
    }
    # printf "\n"
    
    # printf "fs length: %d, cal: %d, %d,%d,%d\n", FSL, col_average_len,COL,FSL,NFL
    
    split("", line_wrap)
    split("", line_wrap_idx)
    for(i in I) {
        # printf "%d->\n ",i

        idx=1
        for(j in J) {
            fmt=get_wrap_format(n, j)
            # printf "%d\t%d\t",j,LEND[i,j]
            # printf "colL %d, %s\n", colL[sortedcolL[j]], fmt
            fwrap(DATA[i,j], colL[sortedcolL[j]])
        }
    }

    for(i=1;i<=ROWS;i++) {
        if (i in HOLD_DATA) {
            print HOLD_DATA[i]
            continue
        }
        for(k=1;k<=line_wrap_idx[i];k++) {
            nl=FS
            for(j in J) {
                nl=nl""line_wrap[i,j,k]"\t"FS
            }
            print nl
        }
    }
}
function max(a, b) {
    return a > b ? a : b
}
function min(a, b) {
    return a < b ? a : b
}
function get_wrap_format(cols, jj) {
    fmt=FS
    for(ii=1; ii<=cols; ii++) {
        if(ii==jj) {
            fmt=fmt"%s"
        }
        fmt=fmt"\t"FS
    }
    
    return fmt
}
function wrap(str, width, format) {
    len = length(str)
    while (len > width) {
        str = substr(str, width+1)
        len = length(str)
        newstr = newstr""substr(str, 1, width)
    }
    return newstr
}
function fwrap(str, width) {
    idx=1
    if(length(str) > width) {
        r=""
        cmd = "printf %s \"" str "\" | fold -s -w " width
        while ( (cmd | getline line) > 0 ) {
            # line=sprintf(format, line)
            line_wrap[i,j,idx++]=line
            # printf "i: %d, j: %d, idx: %d, line: %s\n", i, j, idx-1, line
            r=r?r"\n"line:line
        }
        close(cmd)
        idx--
        # return r
    } else {
        line_wrap[i,j,idx]=str
        # printf "i: %d, j: %d, idx: %d, line: %s\n", i, j, idx, str
    }
    line_wrap_idx[i]=idx
}
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
'
}



function format_table() {
    local cols="${1}"
    local header_cols=$(echo "${2}" | sed "s/,/ /g")
    local input="$(cat)"
    border_line=()
    local total_lines=$(echo "${input}" | wc -l)
    {
        echo -n "${_format_table_char_top_left}"
        for i in $(seq 2 ${cols}); do
            echo -ne "\t${_format_table_char_vertical_horizontal_top}"
        done
        echo -e "\t${_format_table_char_top_right}"
        border_line+=("1")

        idx=1
        last_line_row=idx
        while read -r line; do
            # wrap line
            wrap_line=$(echo -e "${line}" | _format_table_prettify_lines | _format_table_awk_wrap)
            wrap_line_rows=$(echo "${wrap_line}" | wc -l)
            last_line_row=$((last_line_row+wrap_line_rows))
            echo "${wrap_line}"

            # last line
            if [[ "${idx}" -eq "${total_lines}" ]];then
                break
            fi

            # around line
            if [[ " ${header_cols[*]} " =~ " ${idx} " ]]; then
                echo -n "${_format_table_char_vertical_horizontal_left}"
                for i in $(seq 2 ${cols}); do
                    echo -ne "\t${_format_table_char_vertical_horizontal}"
                done
                echo -e "\t${_format_table_char_vertical_horizontal_right}"
                border_line+=("${last_line_row}")
            fi
            ((idx++))
        done <<< "$input"

        echo -n "${_format_table_char_bottom_left}"
        for i in $(seq 2 ${cols}); do
            echo -ne "\t${_format_table_char_vertical_horizontal_bottom}"
        done
        echo -e "\t${_format_table_char_bottom_right}"
        border_line+=("${last_line_row}")
    } | tee ccc.log | column -t -s $'\t' | _format_table_fix_border_lines "${border_line}"

    echo ${border_line[@]}
}

case $- in
  *i*) ;; # assume being sourced, do nothing
  *) format_table $* ;; # assume being executed as an executable
esac
