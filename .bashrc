#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

__prepend_path() {
	PATH="$1:$PATH"
}

__prepend_path ~/.local/bin
__prepend_path ~/.bin
__prepend_path ~/go/bin
__prepend_path ~/.cargo/bin
__prepend_path ~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin
__prepend_path ~/.luarocks/bin
__prepend_path ~/.tools/vendor/bin
__prepend_path ~/.tools/node_modules/.bin
__prepend_path ~/ide/bin

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

export GOFLAGS="-modcacherw"
export GOPATH="$HOME/go"

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export MANPAGER="nvim +Man!"

export FZF_DEFAULT_OPTS="--layout=reverse --marker='>' --pointer='>'"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude '.git'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude '.git'"

export LIBRARY_PATH="$HOME/.local/lib"

export ANSIBLE_NOCOWS=1

# Disable makepkg compression.
export PKGEXT=".pkg.tar"

export NODE_OPTIONS="--max_old_space_size=4096"

export HISTFILE="$HOME/.local/state/.bash_history"

export GPG_TTY="$(tty)"

export SHELL="$(which bash)"

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

if test -f /usr/share/LS_COLORS/dircolors.sh; then
	. /usr/share/LS_COLORS/dircolors.sh
fi

if test -d /usr/share/fzf; then
	source /usr/share/fzf/completion.bash
	source /usr/share/fzf/key-bindings.bash
fi

if test -f /usr/share/bash-completion/bash_completion; then
	. /usr/share/bash-completion/bash_completion
fi

. ~/.local/share/tusk/tusk-completion.bash

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
