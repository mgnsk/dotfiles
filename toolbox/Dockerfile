# System packages and user.
FROM archlinux:base-devel AS toolbox-base

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Syyu --noconfirm \
    && pacman -S --noconfirm --needed \
    git \
    git-delta \
    unzip \
    wget \
    tmux \
    fish \
    tree \
    ripgrep \
    fd \
    bat \
    fzf \
    skim \
    parallel \
    moreutils \
    earlyoom \
    tidy \
    prettier \
    typescript-language-server \
    vscode-html-languageserver \
    vscode-css-languageserver \
    svelte-language-server \
    npm \
    eslint \
    go \
    gopls \
    go-tools \
    revive \
    yamllint \
    shfmt \
    bash-language-server \
    brotli \
    direnv \
    luarocks \
    lua-language-server \
    luacheck \
    stylua \
    markdownlint \
    rtmidi \
    php \
    php-sqlite \
    composer \
    neovim \
    man \
    && bash -c "yes | pacman -Scc" \
    && echo "extension=pdo_sqlite" > /etc/php/conf.d/01-pdo_sqlite.ini \
    && if grep -q "${group}:" /etc/group; then \
    groupmod -o -g ${gid} ${group}; \
    else \
    groupadd -f -g ${gid} ${group}; \
    fi \
    && useradd \
    -m \
    -s /usr/bin/fish \
    -g ${group} \
    --uid ${uid} \
    ${user} \
    && passwd -d ${user} \
    && echo "%wheel      ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/01-wheel \
    && gpasswd -a ${user} wheel


# AUR packages.
FROM toolbox-base AS toolbox-aur

ARG user
USER ${user}
WORKDIR /home/${user}/.cache/yay-bin

COPY --chown=${uid}:${gid} /dotfiles/.config/pacman/makepkg.conf /home/${user}/.config/pacman/makepkg.conf

RUN git clone https://aur.archlinux.org/yay-bin.git . \
    && makepkg --noconfirm --syncdeps --install --clean \
      # gpg: key 51C67305FFC2E5C0: public key "PHPStan Bot <ondrej+phpstanbot@mirtes.cz>"
    && gpg --keyserver keys.openpgp.org --recv-keys CA7C2C7A30C8E8E1274A847651C67305FFC2E5C0 \
    && yay -S --noconfirm --needed --batchinstall --removemake --cleanafter \
    fish-fzf \
    buf-bin \
    hadolint-bin \
    shellcheck-bin \
    lscolors-git \
    phpactor \
    phpstan-bin \
    && rm -rf ~/.cache


# Go packages.
FROM toolbox-base AS go-tools

ARG user
USER ${user}

RUN go install -v github.com/rliebz/tusk@latest \
    && go install -v github.com/goccmack/gocc@latest


# Rust installation and packages.
FROM toolbox-base AS rust-tools

RUN pacman -S --noconfirm --needed \
    rustup \
    && bash -c "yes | pacman -Scc"

ARG user
USER ${user}

RUN rustup default nightly \
    && rustup component add rustfmt rust-src clippy rust-analyzer-preview


# PHP packages.
FROM toolbox-base AS php-tools

ARG user
USER ${user}
WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.json /home/${user}/.tools/composer.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.lock /home/${user}/.tools/composer.lock

RUN composer install --no-dev --no-cache --no-interaction --optimize-autoloader


# Javascript packages.
FROM toolbox-base AS js-tools

ARG user
USER ${user}
WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/package.json /home/${user}/.tools/package.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/package-lock.json /home/${user}/.tools/package-lock.json

RUN npm ci


# Neovim plugins.
FROM toolbox-base AS nvim-plugins

ARG uid
ARG gid
ARG user
USER ${user}

# TODO: can we keep the lockfile owned by root? https://github.com/folke/lazy.nvim/issues/727
COPY --chown=${uid}:${gid} /dotfiles/.config/nvim /home/${user}/.config/nvim
RUN nvim --headless -u NORC \
    -c 'lua if not require("lazy_setup") then os.exit(1) end' \
    -c 'lua local ok, result = pcall(vim.cmd, "Lazy! restore"); if not ok then print(result); os.exit(1) end' \
    -c 'lua os.exit(0)'


# Final image.
FROM toolbox-aur

ARG uid
ARG gid
ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY --from=go-tools --chown=${uid}:${gid} /home/${user}/go/bin /home/${user}/go/bin
COPY --from=rust-tools /home/${user}/.rustup /home/${user}/.rustup
COPY --from=php-tools /home/${user}/.tools/vendor /home/${user}/.tools/vendor
COPY --from=js-tools /home/${user}/.tools/node_modules /home/${user}/.tools/node_modules
COPY --from=nvim-plugins /home/${user}/.local/share/nvim /home/${user}/.local/share/nvim

RUN fish -c "fish_update_completions" \
    && sudo gpasswd -d ${user} wheel \
    && sudo rm /etc/sudoers.d/01-wheel \
    && mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.cargo \
    /home/${user}/.local/share/fish \
    /home/${user}/.local/state \
    /home/${user}/go \
    /home/${user}/.rustup
