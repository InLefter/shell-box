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
    cat - | tee zz.log | sed -e "1s@ @${_format_table_char_horizontal}@g;3s@ @${_format_table_char_horizontal}@g;\$s@ @${_format_table_char_horizontal}@g"
}

function format_table() {
    local cols="${1}"
    local header_cols=${2}
    local input="$(cat)"
    local first_header="$(echo -e "${input}"|head -n1)"
    local body="$(echo -e "${input}"|tail -n+2)"
    {
        # Top border
        echo -n "${_format_table_char_top_left}"
        for i in $(seq 2 ${cols}); do
            echo -ne "\t${_format_table_char_vertical_horizontal_top}"
        done
        echo -e "\t${_format_table_char_top_right}"

        echo -e "${first_header}" | _format_table_prettify_lines

        echo -n "${_format_table_char_vertical_horizontal_left}"
        for i in $(seq 2 ${cols}); do
            echo -ne "\t${_format_table_char_vertical_horizontal}"
        done
        echo -e "\t${_format_table_char_vertical_horizontal_right}"

        echo -e "${body}" | _format_table_prettify_lines

        echo -n "${_format_table_char_bottom_left}"
        for i in $(seq 2 ${cols}); do
            echo -ne "\t${_format_table_char_vertical_horizontal_bottom}"
        done
        echo -e "\t${_format_table_char_bottom_right}"
    } | tee ccc.log | awk -F\│ -v COL=$COLUMNS '{
    FSL=length(FS)*(NF-1);
    NFL=NF;
    for(i=2;i<NF;i++) {
        gsub("\t", " ", $i);
        $i=trim($i);
        LEND[NR,i-1]=length($i);
        DATA[NR,i-1]=$i;
        I[NR];
        J[i-1];
    }
}END{
    col_len_aval=COL-FSL;
    col_average_len=int(col_len_aval/NFL);
    # calculate max length of every col
    for(j in J) {
        colL[j]=0;
        for(i in I) {
            colL[j]=max(colL[j],LEND[i,j]);
        }
        # printf "colL[%d], %d, \n", j, colL[j];
    }
    # printf "FS: %s\n", FS;
    # printf "col_len_aval: %d\n", col_len_aval;

    # sort for analysis which col will be wrapped.
    n=asorti(colL, sortedcolL);
    for(j=1; j<=n; j++) {
        # printf "%d,",col_len_aval;
        colL[sortedcolL[j]] = min(colL[sortedcolL[j]], col_average_len);
        col_len_aval = col_len_aval - colL[sortedcolL[j]] - FSL - 1;
        if (j < n) {
            col_average_len = int(col_len_aval / (n - j));
        }
        # printf "%d:%d,",sortedcolL[j],colL[sortedcolL[j]];
    }
    # printf "\n";
    
    # printf "fs length: %d, cal: %d, %d,%d,%d\n", FSL, col_average_len,COL,FSL,NFL;
    for(i in I) {
        # printf "%d->\n ",i;
        for(j in J) {
            fmt=get_wrap_format(n, j);
            # printf "%d\t%d\t",j,LEND[i,j];
            # printf "colL %d, %s\n", colL[sortedcolL[j]], fmt;
            print fwrap(DATA[i,j], colL[sortedcolL[j]], fmt);
        }
    }
}
function max(a, b) {
    return a > b ? a : b;
}
function min(a, b) {
    return a < b ? a : b;
}
function get_wrap_format(cols, jj) {
    fmt=FS
    for(ii=1; ii<=cols; ii++) {
        if(ii==jj) {
            fmt=fmt"%s";
        }
        fmt=fmt"\t"FS;
    }
    
    return fmt;
}
function wrap(str, width, format) {
    len = length(str);
    while (len > width) {
        str = substr(str, width+1);
        len = length(str);
        newstr = newstr""substr(str, 1, width);
    }
    return newstr;
}
function fwrap(str, width, format) {
    if(length(str) > width) {
        r="";
        cmd = "printf %s \"" str "\" | fold -s -w " width;
        while ( (cmd | getline line) > 0 ) {
            line=sprintf(format, line);
            r=r?r"\n"line:line;
        }
        close(cmd);
        return r;
    } else {
        return sprintf(format, str);
    }
}
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
' | column -t -s $'\t' | _format_table_fix_border_lines
}

case $- in
  *i*) ;; # assume being sourced, do nothing
  *) format_table $* ;; # assume being executed as an executable
esac
