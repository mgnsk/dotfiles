#
# ~/.bash_profile
#

# light or dark
style="light"

export THEME="$style"
export GLAMOUR_STYLE="$style"
export GLOW_STYLE="$style"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start sway at login if available.
if test -z "$DISPLAY" -a "$XDG_VTNR" = 1; then
	if command -v sway &>/dev/null; then
		export XDG_CURRENT_DESKTOP=sway
		exec sway
	fi
fi
