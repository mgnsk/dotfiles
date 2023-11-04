# Base image for system.
FROM archlinux:base-devel AS build-base

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Syyu --noconfirm \
    && pacman -S --noconfirm --needed \
    git \
    go \
    rustup \
    composer \
    npm \
    && bash -c "yes | pacman -Scc" \
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


# Go packages.
FROM build-base AS go-tools

ARG user
USER ${user}

RUN go install -v github.com/rliebz/tusk@latest \
    && go install -v github.com/goccmack/gocc@latest


# Rust installation and packages.
FROM build-base AS rust-tools

ARG user
USER ${user}

RUN rustup default nightly \
    && rustup component add rustfmt rust-src clippy rust-analyzer-preview


# PHP packages.
FROM build-base AS php-tools

ARG user
USER ${user}
WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.json /home/${user}/.tools/composer.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.lock /home/${user}/.tools/composer.lock

RUN composer install --no-dev --no-cache --no-interaction --optimize-autoloader


# Javascript packages.
FROM build-base AS js-tools

ARG user
USER ${user}
WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/package.json /home/${user}/.tools/package.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/package-lock.json /home/${user}/.tools/package-lock.json

RUN npm ci


# Toolbox system base.
FROM build-base AS toolbox-base

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.config/pacman/makepkg.conf /home/${user}/.config/pacman/makepkg.conf

RUN sudo pacman -S --noconfirm --needed \
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
    tidy \
    prettier \
    typescript-language-server \
    vscode-html-languageserver \
    vscode-css-languageserver \
    svelte-language-server \
    npm \
    npm-check-updates \
    eslint \
    go \
    gopls \
    go-tools \
    revive \
    buf \
    yamllint \
    shfmt \
    bash-language-server \
    brotli \
    direnv \
    luarocks \
    lua-language-server \
    luacheck \
    stylua \
    rtmidi \
    php \
    php-sqlite \
    composer \
    man \
    && sudo bash -c "yes | pacman -Scc" \
    && sudo bash -c 'echo "extension=pdo_sqlite" > /etc/php/conf.d/01-pdo_sqlite.ini' \
    && mkdir -p /home/${user}/.cache/aur \
    && cd /home/${user}/.cache/aur \
    && ls -la \
    && git clone https://aur.archlinux.org/fish-fzf.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && git clone https://aur.archlinux.org/hadolint-bin.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && git clone https://aur.archlinux.org/shellcheck-bin.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && git clone https://aur.archlinux.org/lscolors-git.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && git clone https://aur.archlinux.org/phpactor.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    # gpg: key 51C67305FFC2E5C0: public key "PHPStan Bot <ondrej+phpstanbot@mirtes.cz>"
    && gpg --keyserver keys.openpgp.org --recv-keys CA7C2C7A30C8E8E1274A847651C67305FFC2E5C0 \
    && git clone https://aur.archlinux.org/phpstan-bin.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && git clone https://aur.archlinux.org/neovim-nightly-bin.git . \
    && makepkg --noconfirm --needed --syncdeps --install --clean --rmdeps \
    && find -mindepth 1 -delete \
    && rm -rf /home/${user}/.cache/aur


# Final image.
FROM toolbox-base

ARG uid
ARG gid
ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY --from=go-tools --chown=${uid}:${gid} /home/${user}/go/bin /home/${user}/go/bin
COPY --from=rust-tools /home/${user}/.rustup /home/${user}/.rustup
COPY --from=php-tools /home/${user}/.tools/vendor /home/${user}/.tools/vendor
COPY --from=js-tools /home/${user}/.tools/node_modules /home/${user}/.tools/node_modules

RUN nvim --headless -u NORC \
    -c 'lua if not require("lazy_setup") then os.exit(1) end' \
    -c 'lua local ok, result = pcall(vim.cmd, "Lazy! restore"); if not ok then print(result); os.exit(1) end' \
    -c 'lua os.exit(0)' \
    && fish -c "fish_update_completions" \
    && sudo gpasswd -d ${user} wheel \
    && sudo rm /etc/sudoers.d/01-wheel \
    && mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.cargo \
    /home/${user}/.local/share/fish \
    /home/${user}/.local/state \
    /home/${user}/go \
    /home/${user}/.rustup
