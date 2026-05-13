#
# ~/.bash_profile
#

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
			text-scaling-factor "1.2"
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
