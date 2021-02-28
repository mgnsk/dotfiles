set -gx PATH "$HOME/.local/bin:$PATH"
set -gx PATH "$HOME/.npm-global/bin:$PATH"
set -gx PATH "$HOME/.tools/js/node_modules/.bin:$PATH"
set -gx PATH "$HOME/go/bin:$PATH"
set -gx PATH "$HOME/.cargo/bin:$PATH"
set -gx PATH "$HOME/.bin:$PATH"
set -gx PATH "$HOME/.luarocks/bin:$PATH"
set -gx PATH "$HOME/.gem/ruby/2.7.0/bin:$PATH"
set -gx PATH "/usr/local/bin:$PATH"
set -gx PATH (printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

set -gx SHELL "/usr/bin/fish"

set -gx NPM_CONFIG_PREFIX "$HOME/.npm-global"

set -gx GOFLAGS "-modcacherw"
set -gx GOPATH "$HOME/go"

set -gx VIM_UNDO_DIR "$HOME/.local/share/nvim/undo"

set -gx EDITOR "/usr/bin/nvim"
set -gx VISUAL "/usr/bin/nvim"
set -gx PAGER "most"
set -gx MANPAGER "nvim +Man!"

set -gx FZF_DEFAULT_COMMAND "fd --type f --no-ignore"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --no-ignore"

set -gx LIBRARY_PATH "$HOME/.local/lib"

set -gx ANSIBLE_NOCOWS 1

set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/docker.sock"

direnv hook fish | source
