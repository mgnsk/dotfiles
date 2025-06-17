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

function gset {
	key="$1"
	value="$2"

	gnome_schema="org.gnome.desktop.interface"
	gsettings set "$gnome_schema" "$key" "$value"
}

gset gtk-theme 'Adwaita'
gset icon-theme 'Adwaita'
gset font-name 'Cantarell 11'
gset monospace-font-name 'Monospace 11'
gset document-font-name 'Adwaita Sans 11'
gset font-antialiasing 'grayscale'
gset font-hinting 'slight'
# Note: only used when font-antialiasing is set to 'rgba'
# gset font-rgba-order 'rgb'
gset text-scaling-factor '1.2'

# TTY1: start sway at login if available.
if test -z "$DISPLAY" -a "$XDG_VTNR" = 1; then
	if command -v sway &>/dev/null; then
		export XDG_CURRENT_DESKTOP=sway
		exec sway
	fi
fi

# TTY2: start openbox at login if available.
if test -z "$DISPLAY" -a "$XDG_VTNR" = 2; then
	if command -v openbox-session &>/dev/null; then
		export XDG_CURRENT_DESKTOP=openbox
		exec startx
	fi
fi
