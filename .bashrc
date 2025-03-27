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

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

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
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "

export GPG_TTY="$(tty)"

export SHELL="$(which bash)"

PROMPT_COMMAND=__prompt_command # Function to generate PS1 after CMDs

shopt -s histappend

__prompt_command() {
	local EXIT="$?" # This needs to be first
	PS1=""

	history -a

	local RCol='\[\e[0m\]'
	local Red='\[\e[0;31m\]'
	local Gre='\[\e[0;32m\]'
	local BrBlu='\[\e[0;36m\]'

	local userHostColor="${USERHOST_COLOR:-$BrBlu}"
	local customHost="${CUSTOM_HOST:-\h}"

	PS1+="${RCol}[\t] ${userHostColor}\u@${customHost} ${Gre}\w"

	if [ $EXIT != 0 ]; then
		PS1+=" ${Red}[${EXIT}]"
	fi

	PS1+=" ${RCol}\n> "
}

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

source "$HOME/.tools/LS_COLORS/lscolors.sh"

if command -v fzf &>/dev/null; then
	eval "$(fzf --bash)"
fi

if test -f /usr/share/bash-completion/bash_completion; then
	source /usr/share/bash-completion/bash_completion
fi

if test -f "$HOME/.local/share/tusk/tusk-completion.bash"; then
	source "$HOME/.local/share/tusk/tusk-completion.bash"
fi

if command -v direnv &>/dev/null; then
	eval "$(direnv hook bash)"
fi
