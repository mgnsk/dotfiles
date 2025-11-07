#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

__prepend_path() {
	PATH="$1${PATH:+":$PATH"}"
}

__prepend_path ~/.npm-packages/node_modules/.bin
__prepend_path ~/.composer-packages/vendor/bin
__prepend_path ~/go/bin
__prepend_path ~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin
__prepend_path ~/.cargo/bin
__prepend_path /usr/share/git/diff-highlight
__prepend_path ~/.local/bin
__prepend_path ~/.bin

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export MANPAGER="less -R"

# Note: duplicated in .gitconfig.
export GIT_LOG_PRETTY_FORMAT='%C(yellow)%h %Cred%cr %Creset%s%C(cyan)%d %Cblue<%an>'

export FZF_DEFAULT_OPTS="--layout=reverse --marker='>' --pointer='>' --style=minimal"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --no-ignore-vcs --exclude '.git/' --exclude 'node_modules/' --exclude 'vendor/'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --no-ignore-vcs --exclude '.git/'"

if [[ "$THEME" == "light" ]]; then
	# https://github.com/Mofiqul/vscode.nvim/blob/main/extra/fzf/vscode-light
	export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"'
  --color=fg:#000000,fg+:#000000,bg:#FFFFFF,bg+:#F3F3F3
  --color=hl:#008000,hl+:#AF00DB,info:#AF00DB,marker:#AF00DB
  --color=prompt:#AF00DB,spinner:#AF00DB,pointer:#AF00DB,header:#008000
  --color=border:#000000,label:#AF00DB,query:#000000'
fi

export LIBRARY_PATH="$HOME/.local/lib"

export ANSIBLE_NOCOWS=1

# Disable makepkg compression.
export PKGEXT=".pkg.tar"

export NODE_OPTIONS="--max_old_space_size=4096"

export HISTFILE="$HOME/.local/state/.bash_history"
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "

GPG_TTY="$(tty)"
export GPG_TTY

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

if command -v vivid &>/dev/null; then
	LS_COLORS="$(vivid generate ayu)"
	export LS_COLORS
fi

if command -v fzf &>/dev/null; then
	eval "$(fzf --bash)"
fi

if command -v direnv &>/dev/null; then
	eval "$(direnv hook bash)"
fi
