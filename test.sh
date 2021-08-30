#!/bin/bash
[ -z "$COLUMNS" ] && {
    COLUMNS=$(tput cols 2> /dev/null)
}
[ -z "$COLUMNS" ] && {
    COLUMNS=$(stty size 2> /dev/null | awk '{print $2}')
}

{
        cat << EOF
┌       ┬       ┬       ┐
│obs.service.run.tar.gz:    │[2021/09/03 12:44:22] info start to begin  │
├       ┼       ┼       ┤
│obs.service.run.tar.2021.03.04.19.gz:  │[2021/09/03 12:44:22] info start to begin test for example.info start to begin test for example.info start to begin test for example.  │
└       ┴       ┴       ┘
EOF
#     cat << EOF
# │1      │john   │foo bar        │
# │12345678       │someone_with_a_long_name       │blub blib blab bam boom        │
# EOF
} | awk -F\│ -v COL=$COLUMNS '{
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
        col_len_aval = col_len_aval - colL[sortedcolL[j]] - FSL * 8
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
