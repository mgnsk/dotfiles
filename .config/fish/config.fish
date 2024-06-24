fish_add_path ~/.local/bin
fish_add_path ~/.bin
fish_add_path ~/go/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin
fish_add_path ~/.luarocks/bin
fish_add_path ~/.tools/vendor/bin
fish_add_path ~/.tools/node_modules/.bin
fish_add_path ~/toolbox/bin

set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8

set -gx SHELL /usr/bin/fish

set -gx GOFLAGS -modcacherw
set -gx GOPATH "$HOME/go"

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER "less -R"
set -gx MANPAGER "nvim +Man!"

set -gx FZF_DEFAULT_OPTS "--layout=reverse --marker='>' --pointer='>'"
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude '.git'"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude '.git'"

set -gx LIBRARY_PATH "$HOME/.local/lib"

set -gx ANSIBLE_NOCOWS 1

set -gx GPG_TTY (tty)


set -g fish_color_autosuggestion 585858
set -g fish_color_command a1b56c
set -g fish_color_comment f7ca88
set -g fish_color_param d8d8d8

if status is-login
    # Start sway at login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        set -gx XDG_CURRENT_DESKTOP sway
        set -gx XDG_DATA_DIRS "/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$XDG_DATA_HOME/flatpak/exports/share"
        set -gx XDG_SESSION_TYPE wayland
        set -gx BEMENU_BACKEND wayland

        export $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)

        exec sway
    end
end

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
