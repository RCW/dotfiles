# Mitchell Surface's bashrc
# Large parts of this were taken from 
# http://www.memoryhole.net/kyle/2008/03/my_bashrc.html

# A note about Keychain and GPG. gpg-agent forgets the passphrase after a while
# and you have to re-enter it. This may well be a good security feature but
# it's dammed annoying and I don't use GPG enough to make it worthwhile. So
# I've not asked keychain to manage gpg-agent.

# If this isn't an interactive shell, only setup keychain and then finish.
# It's also important to not print anything to the screen or we'll break scp.
if [[ $- != *i* ]] ; then
#	[ -x /usr/bin/keychain ] && keychain --quiet id_rsa FFA72600; \
#	. ${HOME}/.keychain/${HOSTNAME}-sh; \
#	. ${HOME}/.keychain/${HOSTNAME}-sh-gpg
	[ -x /usr/bin/keychain ] && keychain --quiet id_rsa ; \
	. ${HOME}/.keychain/${HOSTNAME}-sh

	return
fi

# function to print debug messages
# It can be turned on like so, 'MLSDEBUG=yes; . bashrc'
MLSDEBUG=${MLSDEBUG:-no}

function dprint {
if [[ "$MLSDEBUG" == "yes" && "$-" == *i* ]]; then
    #date "+%H:%M:%S $*"
    echo $SECONDS $*
fi
}
dprint alive

## Some functions to manipulate paths
# They make sure that
# a) The directory exists
# b) The directory isn't already in the path

# Append a directory
function add_to_path \
{
    local folder="${2%%/}"
    [ -d "$folder" -a -x "$folder" ] || return
    folder=`( cd "$folder" ; \pwd -P )`
    add_to_path_force "$1" "$folder"
}

# Preappend a directory
function add_to_path_first \
{
    local folder="${2%%/}"
    [ -d "$folder" -a -x "$folder" ] || return
    folder=`( cd "$folder" ; \pwd -P )`
    # in the middle, move to front
    if eval '[[' -z "\"\${$1##*:$folder:*}\"" ']]'; then
        eval "$1=\"$folder:\${$1//:\$folder:/:}\""
        # at the end
    elif eval '[[' -z "\"\${$1%%*:\$folder}\"" ']]'; then
        eval "$1=\"$folder:\${$1%%:\$folder}\""
        # no path
    elif eval '[[' -z "\"\$$1\"" ']]'; then
        eval "$1=\"$folder\""
        # not in the path
    elif ! eval '[[' -z "\"\${$1##\$folder:*}\"" '||' \
      "\"\$$1\"" '==' "\"$folder\"" ']]'; then
        eval "export $1=\"$folder:\$$1\""
    fi
}

# Make sure the path is good
function verify_path \
{
    # separating cmd out is stupid, but is compatible
    # with older, buggy, bash versions (2.05b.0(1)-release)
    local cmd="echo \$$1"
    local arg="`eval $cmd`"
    eval "$1=\"\""
    while [[ $arg == *:* ]] ; do
        dir="${arg%:${arg#*:}}"
        arg="${arg#*:}"
        if [ "$dir" != "." -a -d "$dir" -a \
          -x "$dir" -a -r "$dir" ] ; then
            dir=`( \cd "$dir" ; \pwd -P )`
            add_to_path "$1" "$dir"
        fi
    done
    if [ "$arg" != "." -a -d "$arg" -a -x "$arg" -a -r "$arg" ] ;
    then
        arg=`( cd "$arg" ; \pwd -P )`
        add_to_path "$1" "$arg"
    fi
}

# Append a directory even if it doesn't exist
function add_to_path_force \
{
    if eval '[[' -z "\$$1" ']]'; then
        eval "export $1='$2'"
    elif ! eval '[[' \
        -z "\"\${$1##*:\$2:*}\"" '||' \
        -z "\"\${$1%%*:\$2}\"" '||' \
        -z "\"\${$1##\$2:*}\"" '||' \
        "\"\${$1}\"" '==' "\"$2\"" ']]'; then
        eval "export $1=\"\$$1:$2\""
    fi
}

# Make sure a binary exists
function have { type "$1" &>/dev/null ; }

dprint "Setting up the PATH"
verify_path PATH
add_to_path PATH "${HOME}/bin"
add_to_path PATH "${HOME}/.cabal/bin"

## Environment variables
dprint "Setting the environment variables"
[[ -z $GROUPNAME ]] && GROUPNAME="`id -gn`"
[[ -z $USER ]] && USER="`id -un`"
HOST=${OSTYPE%%[[:digit:*}

export USER GROUPNAME HOST

# Use keychain to setup ssh-agent and gpg-agent
dprint "Setting up keychain"
#have keychain && keychain id_rsa FFA72600; \
#	. ${HOME}/.keychain/${HOSTNAME}-sh; \
#	. ${HOME}/.keychain/${HOSTNAME}-sh-gpg
if have keychain ; then
	if [[ -e ${HOME}/.ssh/id_rsa ]]; then
		keychain id_rsa ; . ${HOME}/.keychain/${HOSTNAME}-sh
	else
		keychain ; . ${HOME}/.keychain/${HOSTNAME}-sh
	fi
fi
dprint "Done with keychain"

# Set LEDGER for the ledger accounting program
if [ -r ${HOME}/Documents/ledger.dat ]; then
    export LEDGER=${HOME}/Documents/ledger.dat
fi

# Use Vim if it exists
have vim && export EDITOR=vim || export EDITOR=vi

# Use less
have less && export PAGER=less

# disable XON/XOFF flow control (^s/^q)
stty -ixon

if [ "${BASH_VERSINFO[0]}" -le 2 ]; then
    export HISTCONTROL=ignoreboth
else
    export HISTCONTROL="ignorespace:erasedups"
fi
export HISTIGNORE="&:ls:[bf]g:exit"

## set options
set -o ignoreeof 	# Stop ctrl+d from logging me out

## shopt options
shopt -s cdspell	# Correct minor spelling errors in a cd
shopt -s histappend	# Append to history rather than overwrite
shopt -s checkwinsize	# Check window size after each command

# make less more friendly for non-text input files, see lesspipe(1)
have lesspipe && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Set up aliases
dprint "Set up aliases"
if [ -f ${HOME}/.aliases ]; then
    . ${HOME}/.aliases
fi

# enable color support of ls and also add handy aliases
dprint "Making ls and grep use color"
if [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Set up the prompt
if [ -x ${HOME}/.prompt ]; then
	. ${HOME}/.prompt
fi

## Some handy functions

function extract \
{
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)	tar xjf $1		;;
			*.tar.gz)	tar xzf $1		;;
			*.bz2)		bunzip2 $1		;;
			*.rar)		rar x $1		;;
			*.gz)		gunzip $1		;;
			*.tar)		tar xf $1		;;
			*.tbz2)		tar xjf $1		;;
			*.tgz)		tar xzf $1		;;
			*.zip)		unzip $1		;;
			*.Z)		uncompress $1	;;
			*)			echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

function psgrep \
{
	if [ ! -z $1 ] ; then
		echo "Grepping for processes matching $1..."
		ps aux | grep $1 | grep -v grep
	else
		echo "!! Need name to grep for"
	fi
}


dprint BASHRC_DONE
