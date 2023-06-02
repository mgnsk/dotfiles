fish_add_path ~/.local/bin
fish_add_path ~/.bin
fish_add_path ~/go/bin
fish_add_path ~/toolbox/workspaces/go/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin
fish_add_path ~/.luarocks/bin
fish_add_path ~/.tools/vendor/bin
fish_add_path ~/.tools/node_modules/.bin
fish_add_path ~/toolbox/bin

set -gx SHELL "/usr/bin/fish"

set -gx GOFLAGS "-modcacherw"
set -gx GOPATH "$HOME/go"

set -gx EDITOR "nvim"
set -gx VISUAL "nvim"
set -gx PAGER "less -R"
set -gx MANPAGER "nvim +Man!"

set -gx FZF_DEFAULT_OPTS "--layout=reverse"
set -gx FZF_DEFAULT_COMMAND "fd --type f --no-ignore --hidden --exclude '.git'"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --no-ignore --hidden --exclude '.git'"

set -gx LIBRARY_PATH "$HOME/.local/lib"

set -gx ANSIBLE_NOCOWS 1

set -gx GPG_TTY (tty)

set -gx BEMENU_BACKEND wayland

set -g fish_color_autosuggestion 585858
set -g fish_color_command a1b56c
set -g fish_color_comment f7ca88
set -g fish_color_param d8d8d8

if status --is-interactive
	if test -d /usr/share/fzf/shell
		source /usr/share/fzf/shell/key-bindings.fish
	end

	if test -f /usr/share/LS_COLORS/dircolors.sh
		set colors $(sh -c ". /usr/share/LS_COLORS/dircolors.sh; printenv LS_COLORS")
		set -gx LS_COLORS $colors
	end

	if type -q direnv
		direnv hook fish | source
	end
end

# Start sway at login
if status is-login
	if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
		export $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)
		exec sway
	end
end
