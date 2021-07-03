#!/bin/bash

##################################################
#
# 工具集合，可扩展
#
#
##################################################

LOGGER_LEVEL=${LOGGER_LEVEL:-1} # 0: debug, 1: info, 2: notice, 3: warning, 4: error
ARTHAS_URL=""
_IS_ARM=`uname -a | grep aarch &> /dev/null && echo true || echo false`
if [[ "${_IS_ARM}" == "true" ]];then
    JDK_URL=""
else
    JDK_URL=""
fi

##################################################
# https://github.com/rcmdnk/shell-logger
##################################################
function load_logger()
{
    LOGGER_DATE_FORMAT=${LOGGER_DATE_FORMAT:-'%Y/%m/%d %H:%M:%S'}
    LOGGER_STDERR_LEVEL=${LOGGER_STDERR_LEVEL:-4}
    LOGGER_DEBUG_COLOR=${LOGGER_INFO_COLOR:-"3"}
    LOGGER_INFO_COLOR=${LOGGER_INFO_COLOR:-""}
    LOGGER_NOTICE_COLOR=${LOGGER_INFO_COLOR:-"36"}
    LOGGER_WARNING_COLOR=${LOGGER_INFO_COLOR:-"33"}
    LOGGER_ERROR_COLOR=${LOGGER_INFO_COLOR:-"31"}
    LOGGER_COLOR=${LOGGER_COLOR:-auto}
    LOGGER_COLORS=("$LOGGER_DEBUG_COLOR" "$LOGGER_INFO_COLOR" "$LOGGER_NOTICE_COLOR" "$LOGGER_WARNING_COLOR" "$LOGGER_ERROR_COLOR")
    if [ "${LOGGER_LEVELS}" = "" ];then
    LOGGER_LEVELS=("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR")
    fi
    LOGGER_SHOW_TIME=${LOGGER_SHOW_TIME:-1}
    LOGGER_SHOW_FILE=${LOGGER_SHOW_FILE:-1}
    LOGGER_SHOW_LEVEL=${LOGGER_SHOW_LEVEL:-1}
    LOGGER_ERROR_RETURN_CODE=${LOGGER_ERROR_RETURN_CODE:-100}
    LOGGER_ERROR_TRACE=${LOGGER_ERROR_TRACE:-1}

    _LOGGER_WRAP=0

    _get_level () {
    if [ $# -eq 0 ];then
        local level=1
    else
        local level=$1
    fi
    if ! expr "$level" : '[0-9]*' >/dev/null;then
        [ -z "$ZSH_VERSION" ] || emulate -L ksh
        local i=0
        while [ $i -lt ${#LOGGER_LEVELS[@]} ];do
        if [ "$level" = "${LOGGER_LEVELS[$i]}" ];then
            level=$i
            break
        fi
        ((i++))
        done
    fi
    echo $level
    }

    _logger_level () {
    [ "$LOGGER_SHOW_LEVEL" -ne 1 ] && return
    if [ $# -eq 1 ];then
        local level=$1
    else
        local level=1
    fi
    [ -z "$ZSH_VERSION" ] || emulate -L ksh
    printf "[${LOGGER_LEVELS[$level]}]"
    }

    _logger_time () {
    [ "$LOGGER_SHOW_TIME" -ne 1 ] && return
    printf "[$(date +"$LOGGER_DATE_FORMAT")]"
    }

    _logger_file () {
    [ "$LOGGER_SHOW_FILE" -ne 1 ] && return
    local i=0
    if [ $# -ne 0 ];then
        i=$1
    fi
    if [ -n "$BASH_VERSION" ];then
        printf "[${BASH_SOURCE[$((i+1))]}:${BASH_LINENO[$i]}]"
    else
        emulate -L ksh
        printf "[${funcfiletrace[$i]}]"
    fi
    }

    _logger () {
    ((_LOGGER_WRAP++))
    local wrap=${_LOGGER_WRAP}
    _LOGGER_WRAP=0
    if [ $# -eq 0 ];then
        return
    fi
    local level="$1"
    shift
    if [ "$level" -lt "$(_get_level "$LOGGER_LEVEL")" ];then
        return
    fi
    local msg="$(_logger_time)$(_logger_file "$wrap")$(_logger_level "$level") $*"
    local _logger_printf=printf
    local out=1
    if [ "$level" -ge "$LOGGER_STDERR_LEVEL" ];then
        out=2
        _logger_printf=">&2 printf"
    fi
    if [ "$LOGGER_COLOR" = "always" ] || { test "$LOGGER_COLOR" = "auto"  && test  -t $out ; };then
        [ -z "$ZSH_VERSION" ] || emulate -L ksh
        eval "$_logger_printf \"\\e[${LOGGER_COLORS[$level]}m%s\\e[m\\n\"  \"$msg\""
    else
        eval "$_logger_printf \"%s\\n\" \"$msg\""
    fi
    }

    debug () {
    ((_LOGGER_WRAP++))
    _logger 0 "$*"
    }

    info () {
    ((_LOGGER_WRAP++))
    _logger 1 "$*"
    }

    notice () {
    ((_LOGGER_WRAP++))
    _logger 2 "$*"
    }

    warn () {
    ((_LOGGER_WRAP++))
    _logger 3 "$*"
    }

    error () {
    ((_LOGGER_WRAP++))
    if [ "$LOGGER_ERROR_TRACE" -eq 1 ];then
        {
        [ -z "$ZSH_VERSION" ] || emulate -L ksh
        local first=0
        if [ -n "$BASH_VERSION" ];then
            local current_source=$(echo "${BASH_SOURCE[0]##*/}"|cut -d"." -f1)
            local func="${FUNCNAME[1]}"
            local i=$((${#FUNCNAME[@]}-2))
        else
            local current_source=$(echo "${funcfiletrace[0]##*/}"|cut -d":" -f1|cut -d"." -f1)
            local func="${funcstack[1]}"
            local i=$((${#funcstack[@]}-1))
            local last_source=${funcfiletrace[$i]%:*}
            if [ "$last_source" = zsh ];then
            ((i--))
            fi
        fi
        if [ "$current_source" = "shell-logger" ] && [ "$func" = err ];then
            local first=1
        fi
        if [ $i -ge $first ];then
            echo "Traceback (most recent call last):"
        fi
        while [ $i -ge $first ];do
            if [ -n "$BASH_VERSION" ];then
            local file=${BASH_SOURCE[$((i+1))]}
            local line=${BASH_LINENO[$i]}
            local func=""
            if [ ${BASH_LINENO[$((i+1))]} -ne 0 ];then
                if [ "${FUNCNAME[$((i+1))]}" = "source" ];then
                func=", in ${BASH_SOURCE[$((i+2))]}"
                else
                func=", in ${FUNCNAME[$((i+1))]}"
                fi
            fi
            local func_call="${FUNCNAME[$i]}"
            if [ "$func_call" = "source" ];then
                func_call="${func_call} ${BASH_SOURCE[$i]}"
            else
                func_call="${func_call}()"
            fi
            else
            local file=${funcfiletrace[$i]%:*}
            local line=${funcfiletrace[$i]#*:}
            local func=""
            if [ -n "${funcstack[$((i+1))]}" ];then
                if [ "${funcstack[$((i+1))]}" = "${funcfiletrace[$i]%:*}" ];then
                func=", in ${funcfiletrace[$((i+1))]%:*}"
                else
                func=", in ${funcstack[$((i+1))]}"
                fi
            fi
            local func_call="${funcstack[$i]}"
            if [ "$func_call" = "${funcfiletrace[$((i-1))]%:*}" ];then
                func_call="source ${funcfiletrace[$((i-1))]%:*}"
            else
                func_call="${func_call}()"
            fi
            fi
            echo "  File \"${file}\", line ${line}${func}"
            if [ $i -gt $first ];then
            echo "    $func_call"
            else
            echo ""
            fi
            ((i--))
        done
        } 1>&2
    fi
    _logger 4 "$*"
    return "$LOGGER_ERROR_RETURN_CODE"
    }
}

##################################################
# 设置基本命令别名
##################################################
function load_alias()
{
    -='cd -'
    ...=../..
    ....=../../..
    .....=../../../..
    ......=../../../../..
    1='cd -'
    2='cd -2'
    3='cd -3'
    4='cd -4'
    5='cd -5'
    6='cd -6'
    7='cd -7'
    8='cd -8'
    9='cd -9'
    _='sudo '
    afind='ack -il'
    egrep='egrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
    fgrep='fgrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
    g=git
    ga='git add'
    gaa='git add --all'
    gam='git am'
    gama='git am --abort'
    gamc='git am --continue'
    gams='git am --skip'
    gamscp='git am --show-current-patch'
    gap='git apply'
    gapa='git add --patch'
    gapt='git apply --3way'
    gau='git add --update'
    gav='git add --verbose'
    gb='git branch'
    gbD='git branch -D'
    gba='git branch -a'
    gbd='git branch -d'
    gbda='git branch --no-color --merged | command grep -vE "^(\+|\*|\s*($(git_main_branch)|development|develop|devel|dev)\s*$)" | command xargs -n 1 git branch -d'
    gbl='git blame -b -w'
    gbnm='git branch --no-merged'
    gbr='git branch --remote'
    gbs='git bisect'
    gbsb='git bisect bad'
    gbsg='git bisect good'
    gbsr='git bisect reset'
    gbss='git bisect start'
    gc='git commit -v'
    'gc!'='git commit -v --amend'
    gca='git commit -v -a'
    'gca!'='git commit -v -a --amend'
    gcam='git commit -a -m'
    'gcan!'='git commit -v -a --no-edit --amend'
    'gcans!'='git commit -v -a -s --no-edit --amend'
    gcas='git commit -a -s'
    gcasm='git commit -a -s -m'
    gcb='git checkout -b'
    gcd='git checkout develop'
    gcf='git config --list'
    gcl='git clone --recurse-submodules'
    gclean='git clean -id'
    gcm='git checkout $(git_main_branch)'
    gcmsg='git commit -m'
    'gcn!'='git commit -v --no-edit --amend'
    gco='git checkout'
    gcor='git checkout --recurse-submodules'
    gcount='git shortlog -sn'
    gcp='git cherry-pick'
    gcpa='git cherry-pick --abort'
    gcpc='git cherry-pick --continue'
    gcs='git commit -S'
    gcsm='git commit -s -m'
    gcss='git commit -S -s'
    gcssm='git commit -S -s -m'
    gd='git diff'
    gdca='git diff --cached'
    gdct='git describe --tags $(git rev-list --tags --max-count=1)'
    gdcw='git diff --cached --word-diff'
    gds='git diff --staged'
    gdt='git diff-tree --no-commit-id --name-only -r'
    gdw='git diff --word-diff'
    gf='git fetch'
    gfa='git fetch --all --prune --jobs=10'
    gfg='git ls-files | grep'
    gfo='git fetch origin'
    gg='git gui citool'
    gga='git gui citool --amend'
    ggpull='git pull origin "$(git_current_branch)"'
    ggpur=ggu
    ggpush='git push origin "$(git_current_branch)"'
    ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
    ghh='git help'
    gignore='git update-index --assume-unchanged'
    gignored='git ls-files -v | grep "^[[:lower:]]"'
    git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
    gk='\gitk --all --branches'
    gke='\gitk --all $(git log -g --pretty=%h)'
    gl='git pull'
    glg='git log --stat'
    glgg='git log --graph'
    glgga='git log --graph --decorate --all'
    glgm='git log --graph --max-count=10'
    glgp='git log --stat -p'
    glo='git log --oneline --decorate'
    globurl='noglob urlglobber '
    glod='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'
    glods='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'' --date=short'
    glog='git log --oneline --decorate --graph'
    gloga='git log --oneline --decorate --graph --all'
    glol='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'
    glola='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --all'
    glols='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --stat'
    glp=_git_log_prettily
    glum='git pull upstream $(git_main_branch)'
    gm='git merge'
    gma='git merge --abort'
    gmom='git merge origin/$(git_main_branch)'
    gmt='git mergetool --no-prompt'
    gmtvim='git mergetool --no-prompt --tool=vimdiff'
    gmum='git merge upstream/$(git_main_branch)'
    gp='git push'
    gpd='git push --dry-run'
    gpf='git push --force-with-lease'
    'gpf!'='git push --force'
    gpoat='git push origin --all && git push origin --tags'
    gpr='git pull --rebase'
    gpristine='git reset --hard && git clean -dffx'
    gpsup='git push --set-upstream origin $(git_current_branch)'
    gpu='git push upstream'
    gpv='git push -v'
    gr='git remote'
    gra='git remote add'
    grb='git rebase'
    grba='git rebase --abort'
    grbc='git rebase --continue'
    grbd='git rebase develop'
    grbi='git rebase -i'
    grbm='git rebase $(git_main_branch)'
    grbo='git rebase --onto'
    grbs='git rebase --skip'
    grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
    grev='git revert'
    grh='git reset'
    grhh='git reset --hard'
    grm='git rm'
    grmc='git rm --cached'
    grmv='git remote rename'
    groh='git reset origin/$(git_current_branch) --hard'
    grrm='git remote remove'
    grs='git restore'
    grset='git remote set-url'
    grss='git restore --source'
    grst='git restore --staged'
    grt='cd "$(git rev-parse --show-toplevel || echo .)"'
    gru='git reset --'
    grup='git remote update'
    grv='git remote -v'
    gsb='git status -sb'
    gsd='git svn dcommit'
    gsh='git show'
    gsi='git submodule init'
    gsps='git show --pretty=short --show-signature'
    gsr='git svn rebase'
    gss='git status -s'
    gst='git status'
    gsta='git stash push'
    gstaa='git stash apply'
    gstall='git stash --all'
    gstc='git stash clear'
    gstd='git stash drop'
    gstl='git stash list'
    gstp='git stash pop'
    gsts='git stash show --text'
    gstu='gsta --include-untracked'
    gsu='git submodule update'
    gsw='git switch'
    gswc='git switch -c'
    gtl='gtl(){ git tag --sort=-v:refname -n -l "${1}*" }; noglob gtl'
    gts='git tag -s'
    gtv='git tag | sort -V'
    gunignore='git update-index --no-assume-unchanged'
    gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
    gup='git pull --rebase'
    gupa='git pull --rebase --autostash'
    gupav='git pull --rebase --autostash -v'
    gupv='git pull --rebase -v'
    gwch='git whatchanged -p --abbrev-commit --pretty=medium'
    gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'
    history=omz_history
    l='ls -lah'
    la='ls -lAh'
    ll='ls -lh'
    ls='ls -G'
    lsa='ls -lah'
    md='mkdir -p'
    rd=rmdir
    run-help=man
    which-command=whence
}


##################################################
# 设置对象业务基本别名
##################################################
function load_cus_alias()
{
    
}

##################################################
# 下载
# $1 url
# $2 destFile
##################################################
function download()
{
    info "begin to download [$1] to [$2]"
    curl -k -o $destFile -i $url
    info "success download [$1] in [$2]"
}

##################################################
# 部署arthas
##################################################
function deploy_arthas()
{
    
}

##################################################
# 部署JDK
##################################################
function deploy_jdk()
{
    
}

##################################################
# 开启JDK DEBUG 端口
##################################################
function deploy_jdk()
{
    
}

load_logger

