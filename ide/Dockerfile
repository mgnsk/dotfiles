# Base image for system.
FROM archlinux:base-devel@sha256:61b9b05cf6a7a42aa1a32f0b00c92dcfc0b6acf3af2db1b86ab29f6605b21401 AS build-base

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Syy \
    && pacman -S --noconfirm --needed archlinux-keyring \
    && pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
    git \
    go \
    rustup \
    composer \
    npm \
    neovim \
    && bash -c "yes | pacman -Scc" \
    && if grep -q "${group}:" /etc/group; then \
    groupmod -o -g ${gid} ${group}; \
    else \
    groupadd -f -g ${gid} ${group}; \
    fi \
    && useradd \
    -m \
    -s /usr/bin/bash \
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

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/go.mod ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/go.sum ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-go.sh ./

RUN bash install-go.sh \
    && sudo rm -rf /home/${user}/go/pkg \
    && rm -rf /home/${user}/.cache


# Rust packages.
FROM build-base AS rust-tools

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-rust.sh ./

RUN bash install-rust.sh \
    && rm -rf \
    /home/${user}/.cargo/git \
    /home/${user}/.cargo/registry


# PHP packages.
FROM build-base AS php-tools

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.json ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.lock ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-php.sh ./

RUN bash install-php.sh \
    && rm -rf /home/${user}/.cache


# Javascript packages.
FROM build-base AS js-tools

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/package.json ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/package-lock.json ./
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-js.sh ./

RUN bash install-js.sh \
    && rm -rf /home/${user}/.npm


# Neovim packages.
FROM build-base AS nvim-tools

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.config/nvim /home/${user}/.config/nvim
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-nvim.sh ./

RUN bash install-nvim.sh \
    && rm -rf /home/${user}/.cache


# System packages.
FROM build-base AS system-packages

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-system.sh ./

RUN bash install-system.sh \
    && rm -rf /home/${user}/.cache \
    && sudo bash -c "yes | pacman -Scc"


# AUR packages.
FROM system-packages AS aur-packages

ARG user
USER ${user}

WORKDIR /home/${user}/.tools

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-aur.sh ./

RUN bash install-aur.sh \
    && rm -rf /home/${user}/.cache \
    && sudo bash -c "yes | pacman -Scc"


# Final image.
FROM aur-packages

ARG uid
ARG gid
ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY --from=go-tools --chown=${uid}:${gid} /home/${user}/go/bin /home/${user}/go/bin
COPY --from=rust-tools --chown=${uid}:${gid} /home/${user}/.rustup /home/${user}/.rustup
COPY --from=php-tools --chown=${uid}:${gid} /home/${user}/.tools/vendor /home/${user}/.tools/vendor
COPY --from=php-tools /etc/php/conf.d /etc/php/conf.d
COPY --from=js-tools --chown=${uid}:${gid} /home/${user}/.tools/node_modules /home/${user}/.tools/node_modules
COPY --from=nvim-tools --chown=${uid}:${gid} /home/${user}/.local/share/nvim /home/${user}/.local/share/nvim
COPY --chown=${uid}:${gid} /dotfiles/.tools/configure-system.sh /home/${user}/.tools/

WORKDIR /home/${user}/.tools

RUN bash configure-system.sh \
    && sudo gpasswd -d ${user} wheel \
    && sudo rm /etc/sudoers.d/01-wheel \
    && mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.cargo \
    /home/${user}/.local/share \
    /home/${user}/.local/state \
    /home/${user}/go/pkg \
    /home/${user}/.rustup
