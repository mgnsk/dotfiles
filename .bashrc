# If not running interactively, don't do anything
[[ $- != *i* ]] && return
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.env ]] && . ~/.env

. "$HOME/.local/share/lscolors.sh"

eval "$(direnv hook bash)"

function nonzero_return() {
	RETVAL=$?
	[ $RETVAL -ne 0 ] && echo " $RETVAL "
}

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
PS1+="\[\e[31m\]\`nonzero_return\`\[\e[m\]"
PS1+='\$ '

source /usr/share/fzf/key-bindings.bash
source /usr/share/fzf/completion.bash
