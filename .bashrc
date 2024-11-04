#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

if test -f /usr/share/LS_COLORS/dircolors.sh; then
	. /usr/share/LS_COLORS/dircolors.sh
fi

if test -d /usr/share/fzf; then
	source /usr/share/fzf/key-bindings.bash
fi

if test -f /usr/share/bash-completion/bash_completion; then
	. /usr/share/bash-completion/bash_completion
fi

# TODO
# if type -p direnv; then
# 	eval "$(direnv hook bash)"
# fi

PROMPT_COMMAND=__prompt_command # Function to generate PS1 after CMDs

shopt -s histappend
PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"

__prompt_command() {
	local EXIT="$?" # This needs to be first
	PS1=""

	local RCol='\[\e[0m\]'
	local Red='\[\e[0;31m\]'
	local Gre='\[\e[0;32m\]'
	local BrBlu='\[\e[0;36m\]'

	PS1+="${RCol}[\t] ${BrBlu}\u@\h ${Gre}\w"

	if [ $EXIT != 0 ]; then
		PS1+=" ${Red}[${EXIT}]"
	fi

	PS1+=" ${RCol}\n> "
}
