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

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-go.sh /home/${user}/.tools/install-go.sh

WORKDIR /home/${user}/.tools

RUN bash install-go.sh \
    && sudo rm -rf /home/${user}/go/pkg \
    && rm -rf /home/${user}/.cache


# Rust packages.
FROM build-base AS rust-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-rust.sh /home/${user}/.tools/install-rust.sh

WORKDIR /home/${user}/.tools

RUN bash install-rust.sh

RUN bash install-rust.sh \
    && rm -rf \
    /home/${user}/.cargo/git \
    /home/${user}/.cargo/registry


# PHP packages.
FROM build-base AS php-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.json /home/${user}/.tools/composer.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.lock /home/${user}/.tools/composer.lock
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-php.sh /home/${user}/.tools/install-php.sh

WORKDIR /home/${user}/.tools

RUN bash install-php.sh \
    && rm -rf /home/${user}/.cache


# Javascript packages.
FROM build-base AS js-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/package.json /home/${user}/.tools/package.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/package-lock.json /home/${user}/.tools/package-lock.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-js.sh /home/${user}/.tools/install-js.sh

WORKDIR /home/${user}/.tools

RUN bash install-js.sh \
    && rm -rf /home/${user}/.npm


# System packages.
FROM build-base AS toolbox-base-system

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/install-system.sh /home/${user}/.tools/install-system.sh

WORKDIR /home/${user}/.tools

RUN bash install-system.sh \
    && rm -rf /home/${user}/.cache \
    && sudo bash -c "yes | pacman -Scc"


# Neovim packages.
FROM toolbox-base-system AS nvim-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.config/nvim /home/${user}/.config/nvim
COPY --chown=${uid}:${gid} /dotfiles/.tools/install-nvim.sh /home/${user}/.tools/install-nvim.sh

WORKDIR /home/${user}/.tools

RUN bash install-nvim.sh \
    && rm -rf /home/${user}/.cache


# Final image.
FROM toolbox-base-system

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

WORKDIR /home/${user}/.tools

RUN bash install-fish.sh \
    && sudo gpasswd -d ${user} wheel \
    && sudo rm /etc/sudoers.d/01-wheel \
    && mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.local/share/fish \
    /home/${user}/.local/state \
    /home/${user}/go/pkg \
    /home/${user}/.rustup
