#
# ~/.bash_profile
#

# light or dark
style="light"

text_scaling_factor="1.2"

export THEME="$style"
export GLAMOUR_STYLE="$style"
export GLOW_STYLE="$style"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

__prepend_path() {
	PATH="$1${PATH:+":$PATH"}"
}

__prepend_path ~/.npm-packages/node_modules/.bin
__prepend_path ~/go/bin
__prepend_path ~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin
__prepend_path /usr/share/git/diff-highlight
__prepend_path ~/.bin

[[ -f ~/.bashrc ]] && . ~/.bashrc

function pre {
	if command -v gsettings &>/dev/null; then
		gsettings set "org.gnome.desktop.interface" \
			gtk-theme 'Adwaita'

		gsettings set "org.gnome.desktop.interface" \
			icon-theme 'Adwaita'

		gsettings set "org.gnome.desktop.interface" \
			font-name 'Cantarell 11'

		gsettings set "org.gnome.desktop.interface" \
			monospace-font-name 'Monospace 11'

		gsettings set "org.gnome.desktop.interface" \
			document-font-name 'Adwaita Sans 11'

		gsettings set "org.gnome.desktop.interface" \
			font-antialiasing 'grayscale'

		gsettings set "org.gnome.desktop.interface" \
			font-hinting 'slight'

		# Note: only used when font-antialiasing is set to 'rgba'
		# font-rgba-order 'rgb'
		gsettings set "org.gnome.desktop.interface" \
			text-scaling-factor "$text_scaling_factor"
	fi

	if command -v kbuildsycoca6 &>/dev/null; then
		# Updates the KService desktop file configuration cache.
		XDG_MENU_PREFIX=arch- /usr/bin/kbuildsycoca6 --noincremental &>/dev/null
	fi
}

# TTY1: start sway at login if available.
if test -z "$DISPLAY" -a "$XDG_VTNR" = 1; then
	if command -v sway &>/dev/null; then
		export XDG_CURRENT_DESKTOP=sway
		pre
		exec sway
	fi
fi

# TTY2: start openbox at login if available.
if test -z "$DISPLAY" -a "$XDG_VTNR" = 2; then
	if command -v openbox-session &>/dev/null; then
		export XDG_CURRENT_DESKTOP=openbox
		pre
		exec startx
	fi
fi
