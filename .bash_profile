#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start sway at login
if test -z "$DISPLAY" -a "$XDG_VTNR" = 1; then
	export XDG_CONFIG_HOME="$HOME/.config"
	export XDG_CACHE_HOME="$HOME/.cache"
	export XDG_STATE_HOME="$HOME/.local/state"
	export XDG_DATA_HOME="$HOME/.local/share"
	export XDG_DATA_DIRS="$HOME/.local/bin/$USER:$HOME/.local/bin:$XDG_DATA_DIRS:/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$XDG_DATA_HOME/flatpak/exports/share"
	export XDG_CURRENT_DESKTOP=sway
	export XDG_SESSION_DESKTOP=sway
	export XDG_SESSION_TYPE=wayland

	export BEMENU_BACKEND=wayland
	export MOZ_ENABLE_WAYLAND=1

	export "$(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)"

	exec sway
fi
