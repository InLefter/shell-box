#!/bin/bash
# |%s\t|%s\t|
# FS%s\tFS
awk -v WIDTH=72 '
{
    gsub("\t"," ")
    print "==>";
    print $0;
    print fwrap($0, 20, "\t%s");
    print "<==";
}

function wrap(str, width) {
    newstr = substr(str, 1, width);
    q = match(newstr, / |$/);
    print q;
    str = substr(str, width+1);
    len = length(str);
    while (len > width) {
        newstr = newstr"\n"substr(str, 1, width);
        str = substr(str, width+1);
        len = length(str);
    }
    return newstr"\n"str;
}

function fwrap(str, width, format) {
    if(length(str) > width) {
        cmd = "printf %s \"" str "\" | fold -s -w " width;
        while ( (cmd | getline line) > 0 ) {
            line=sprintf(format, line);
            r=r?r"\n"line:line;
        }
        close(cmd);
        return r;
    } else {
        return str;
    }
}

function wrapx(text,   q, y, z) {
  while (text) {
    q = match(text, / |$/); y += q
    if (y > 72) {
      z = z RS; y = q - 1
    }
    else if (z) z = z FS
    z = z substr(text, 1, q - 1)
    text = substr(text, q + 1)
  }
  return z
}
'