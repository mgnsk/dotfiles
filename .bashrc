# If not running interactively, don't do anything
[[ $- != *i* ]] && return
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.tools/js/node_modules/.bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.gem/ruby/2.7.0/bin:$PATH"

export GOFLAGS="-modcacherw"

export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"

export EDITOR=/usr/bin/nvim
export VIM_UNDO_DIR="$HOME/.local/share/nvim/undo"
export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket

export PAGER="most"

. "$HOME/.local/share/lscolors.sh"

eval "$(direnv hook bash)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
	xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

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

function nonzero_return() {
	RETVAL=$?
	[ $RETVAL -ne 0 ] && echo " $RETVAL "
}

if [ "$color_prompt" = yes ]; then
	PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
	PS1+="\[\e[31m\]\`nonzero_return\`\[\e[m\]"
	PS1+='\$ '
else
	PS1='\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
	xterm*|rxvt*)
		PS1="\[\e]0;\u@\h: \w\a\]$PS1"
		;;
	*)
		;;
esac

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
