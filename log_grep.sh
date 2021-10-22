#!/bin/bash

read -r -d '' log_config <<-'EOF'
component:
  - 
    name: dns
    dir:
      - "/var/log"
      - "/var/log/xx"
    pattern:
      - "refresh ip"
      - "xst"
    regex:
      - "[0-9]"
  - 
    name: ls
    dir:
      - "/var/log"
      - "/var/log/xx"
    pattern:
      - "w ip"
      - "xst ls"
    regex:
      - "[a-z]"
      - "[b-z]"
EOF

# source: https://github.com/mrbaseman/parse_yaml.git
function parse_yaml {
   local prefix=$2
   local separator=${3:-_}

   local indexfix
   # Detect awk flavor
   if awk --version 2>&1 | grep -q "GNU Awk" ; then
      # GNU Awk detected
      indexfix=-1
   elif awk -Wv 2>&1 | grep -q "mawk" ; then
      # mawk detected
      indexfix=0
   fi

   local s='[[:space:]]*' sm='[ \t]*' w='[a-zA-Z0-9_]*' fs=${fs:-$(echo @|tr @ '\034')} i=${i:-  }
   echo "$1" | \
   awk -F$fs "{multi=0; 
       if(match(\$0,/$sm\|$sm$/)){multi=1; sub(/$sm\|$sm$/,\"\");}
       if(match(\$0,/$sm>$sm$/)){multi=2; sub(/$sm>$sm$/,\"\");}
       while(multi>0){
           str=\$0; gsub(/^$sm/,\"\", str);
           indent=index(\$0,str);
           indentstr=substr(\$0, 0, indent+$indexfix) \"$i\";
           obuf=\$0;
           getline;
           while(index(\$0,indentstr)){
               obuf=obuf substr(\$0, length(indentstr)+1);
               if (multi==1){obuf=obuf \"\\\\n\";}
               if (multi==2){
                   if(match(\$0,/^$sm$/))
                       obuf=obuf \"\\\\n\";
                       else obuf=obuf \" \";
               }
               getline;
           }
           sub(/$sm$/,\"\",obuf);
           print obuf;
           multi=0;
           if(match(\$0,/$sm\|$sm$/)){multi=1; sub(/$sm\|$sm$/,\"\");}
           if(match(\$0,/$sm>$sm$/)){multi=2; sub(/$sm>$sm$/,\"\");}
       }
   print}" | \
   sed  -e "s|^\($s\)?|\1-|" \
       -ne "s|^$s#.*||;s|$s#[^\"']*$||;s|^\([^\"'#]*\)#.*|\1|;t1;t;:1;s|^$s\$||;t2;p;:2;d" | \
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\(&$w\)\?$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: \3[\4]\n\1$i- \5|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\(&$w\)\?$s\[$s\(.*\)$s\]|\1\2: \3\n\1$i- \4|;" \
        -e ":2;s|^\($s\)-$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1- [\2]\n\1$i- \3|;t2" \
        -e "s|^\($s\)-$s\[$s\(.*\)$s\]|\1-\n\1$i- \2|;p" | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1$i\3: \4|;t1" \
        -e "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1$i\2|;" \
        -e ":2;s|^\($s\)\($w\)$s:$s\(&$w\)\?$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1\2: \3 {\4}\n\1$i\5: \6|;t2" \
        -e "s|^\($s\)\($w\)$s:$s\(&$w\)\?$s{$s\(.*\)$s}|\1\2: \3\n\1$i\4|;p" | \
   sed  -e "s|^\($s\)\($w\)$s:$s\(&$w\)\(.*\)|\1\2:\4\n\3|" \
        -e "s|^\($s\)-$s\(&$w\)\(.*\)|\1- \3\n\2|" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\(---\)\($s\)||" \
        -e "s|^\($s\)\(\.\.\.\)\($s\)||" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p;t" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p;t" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\?\(.*\)$s\$|\1$fs\2$fs\3|" \
        -e "s|^\($s\)[\"']\?\([^&][^$fs]\+\)[\"']$s\$|\1$fs$fs$fs\2|" \
        -e "s|^\($s\)[\"']\?\([^&][^$fs]\+\)$s\$|\1$fs$fs$fs\2|" \
        -e "s|$s\$||p" | \
   awk -F$fs "{
      gsub(/\t/,\"        \",\$1);
      if(NF>3){if(value!=\"\"){value = value \" \";}value = value  \$4;}
      else {
        if(match(\$1,/^&/)){anchor[substr(\$1,2)]=full_vn;getline};
        indent = length(\$1)/length(\"$i\");
        vname[indent] = \$2;
        value= \$3;
        for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
        if(length(\$2)== 0){  vname[indent]= ++idx[indent] };
        vn=\"\"; for (i=0; i<indent; i++) { vn=(vn)(vname[i])(\"$separator\")}
        vn=\"$prefix\" vn;
        full_vn=vn vname[indent];
        if(vn==\"$prefix\")vn=\"$prefix$separator\";
        if(vn==\"_\")vn=\"__\";
      }
      assignment[full_vn]=value;
      if(!match(assignment[vn], full_vn))assignment[vn]=assignment[vn] \" \" full_vn;
      if(match(value,/^\*/)){
         ref=anchor[substr(value,2)];
         if(length(ref)==0){
           printf(\"%s=\\\"%s\\\"\n\", full_vn, value);
         } else {
           for(val in assignment){
              if((length(ref)>0)&&index(val, ref)==1){
                 tmpval=assignment[val];
                 sub(ref,full_vn,val);
                 if(match(val,\"$separator\$\")){
                    gsub(ref,full_vn,tmpval);
                 } else if (length(tmpval) > 0) {
                    printf(\"%s=\\\"%s\\\"\n\", val, tmpval);
                 }
                 assignment[val]=tmpval;
              }
           }
         }
      } else if (length(value) > 0) {
         printf(\"%s=\\\"%s\\\"\n\", full_vn, value);
      }
   }END{
      for(val in assignment){
         if(match(val,\"$separator\$\"))
            printf(\"%s=\\\"%s\\\"\n\", val, assignment[val]);
      }
   }"
}

# $1 key [search key in text or regex]
# $2 dir [search dir]
# $3 mode [search mode: text|regex]
# $4 is recursive [true|false, default is false]
# $5 is ignose case [true|false, default is false]
function _grep {
    ARG=""
    if [[ "$3" == "regex" ]];then
        ARG="${ARG} -E"
    fi
    if [[ "$4" == "true" ]];then
        ARG="${ARG} -r"
    fi
    if [[ "$5" == "true" ]];then
        ARG="${ARG} -i"
    fi
    zgrep -a ${ARG} "$1" $2
}

# ^ ^
function collect() {
    local target_comp=$1
    # load config of log component
    eval $(parse_yaml "${log_config}")

    for _comp in $component_
    do
        local _comp_name=$(eval echo \$${_comp}_name)
        if [[ -z "${target_comp}" || "${_comp_name}" == "${target_comp}" ]];then
            # load text pattern
            local _comp_pattern=""
            for _pattern in $(eval echo \$${_comp}_pattern_)
            do
                _eval_pattern="$(eval echo \$${_pattern})"
                if [[ -z "${_comp_pattern}" ]];then
                    _comp_pattern="${_eval_pattern}"
                else
                    _comp_pattern="${_comp_pattern}\|${_eval_pattern}"
                fi
            done
            
            # load regex pattern
            local _comp_regex=""
            for _regex in $(eval echo \$${_comp}_regex_)
            do
                _eval_regex="$(eval echo \$${_regex})"
                if [[ -z "${_comp_regex}" ]];then
                    _comp_regex="${_eval_regex}"
                else
                    _comp_regex="${_comp_regex}|${_eval_regex}"
                fi
            done

            local _pattern_grep=""
            local _regex_grep=""
            for _comp_dir in $(eval echo \$${_comp}_dir_)
            do
                _eval_dir="$(eval echo \$${_comp_dir})"
                if [[ -z "${_regex_grep}" ]];then
                    _regex_grep=$(_grep "${_comp_regex}" "${_eval_dir}" "regex" "false" "false")
                else
                    _regex_grep="${_regex_grep}
${_pattern}"
                fi
                if [[ -z "${_pattern_grep}" ]];then
                    _pattern_grep=$(_grep "${_comp_pattern}" "${_eval_dir}" "text" "false" "false")
                else
                    _pattern_grep="${_pattern_grep}
${_pattern}"
                fi
            done
        fi
    done
}

collect
