source /usr/share/gentoo-bashrc/bashrc

export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTTIMEFORMAT="%F %T:"

shopt -s histappend
shopt -s globstar
shopt -s cmdhist
shopt -s dirspell

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set show-all-if-ambiguous on"
bind "set mark-symlinked-directories on"

alias gdb="gdb -q"
alias la="LC_COLLATE=C ls --group-directories-first -lh"
alias ll="LC_COLLATE=C ls -lahF"
alias sl=ls
alias gti=git
alias maek=make
alias gerp=grep
alias grpe=grep
alias mpv="mpv --sub-font-size=20"
alias mpv-hdmi="mpv --audio-device alsa/hdmi:CARD=HDMI,DEV=0 --sub-font-size=30"
alias netstat=ss
alias venv=". .env/bin/activate"
alias ipa="watch ip a"
alias strace="strace -s3000"

greprop() {
    egrep "[^:;]+${1}[^;]+"
}

def() {
    rg "(#define|class|struct|typedef|def |__prototype__).*$1"
}

export PYTHONSTARTUP="$HOME/.pythonstartup"
export PYTHONDONTWRITEBYTECODE=1
export TERM=xterm-256color


__prompt()
{
    local exit_code="$?"
    history -a

    local WHITE="\[\033[1;37m\]"
    local LBLUE="\[\033[1;34m\]"
    local LGREEN="\[\033[1;32m\]"    
    local LRED="\[\033[1;31m\]"
    local LPURPLE="\[\033[1;35m\]"
    local RESET="\[\033[0m\]"
    local BOLD="\[\033[;1m\]"

    local status
    if test "$exit_code" -ne 0
    then
        status="${LRED} ${exit_code} "
    fi

    local branch
    if git branch &>/dev/null
    then
        branch="${LPURPLE}[$(git branch --color=never|awk '/^\* /{print $2}')] "
    fi

    export PS1="${BOLD}${status}${LGREEN}\u@\h ${LBLUE}\w ${branch}${WHITE}\$${RESET} "
}

export PROMPT_COMMAND=__prompt

export PYENV_ROOT="$HOME"/.local/pyenv
export PATH="${PYENV_ROOT}/bin:$PATH"
hash pyenv &>/dev/null && eval "$(pyenv init - | grep -v '^command pyenv rehash')"

_Z_CMD=j
_Z_OWNER=pgy
test -f /usr/share/z/z.sh && source /usr/share/z/z.sh
