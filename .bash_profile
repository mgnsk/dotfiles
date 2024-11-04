#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

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

export GPG_TTY="$(tty)"

# Disable makepkg compression.
export PKGEXT=".pkg.tar"

export NODE_OPTIONS="--max_old_space_size=4096"

export HISTFILE="$HOME/.local/state/.bash_history"

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
