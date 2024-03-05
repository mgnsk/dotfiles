# Base image for system.
FROM archlinux:base-devel AS build-base

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Syyu --noconfirm

RUN pacman -S --noconfirm --needed \
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
    -s /usr/bin/fish \
    -g ${group} \
    --uid ${uid} \
    ${user} \
    && passwd -d ${user} \
    && echo "%wheel      ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/01-wheel \
    && gpasswd -a ${user} wheel

ARG user
USER ${user}

RUN go install -v github.com/rliebz/tusk@latest \
    && sudo rm -rf /home/${user}/go/pkg \
    && rm -rf /home/${user}/.cache

ENV PATH="$PATH:/home/${user}/go/bin"


# Go packages.
FROM build-base AS go-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/go.yml /home/${user}/.tools/.tusk/go.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.go.yml /home/${user}/.tools/tusk.go.yml

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.go.yml install.go \
    && sudo rm -rf /home/${user}/go/pkg \
    && rm -rf /home/${user}/.cache


# Rust packages.
FROM build-base AS rust-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/rust.yml /home/${user}/.tools/.tusk/rust.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.rust.yml /home/${user}/.tools/tusk.rust.yml

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.rust.yml install.rust


# PHP packages.
FROM build-base AS php-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/php.yml /home/${user}/.tools/.tusk/php.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.php.yml /home/${user}/.tools/tusk.php.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.json /home/${user}/.tools/composer.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/composer.lock /home/${user}/.tools/composer.lock

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.php.yml install.php \
    && rm -rf /home/${user}/.cache


# Javascript packages.
FROM build-base AS js-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/js.yml /home/${user}/.tools/.tusk/js.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.js.yml /home/${user}/.tools/tusk.js.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/package.json /home/${user}/.tools/package.json
COPY --chown=${uid}:${gid} /dotfiles/.tools/package-lock.json /home/${user}/.tools/package-lock.json

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.js.yml install.js \
    && rm -rf /home/${user}/.npm


# Neovim packages.
FROM build-base AS nvim-tools

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/nvim.yml /home/${user}/.tools/.tusk/nvim.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.nvim.yml /home/${user}/.tools/tusk.nvim.yml
COPY --chown=${uid}:${gid} /dotfiles/.config/nvim /home/${user}/.config/nvim

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.nvim.yml install.nvim \
    && rm -rf /home/${user}/.cache


# System packages.
FROM build-base AS toolbox-base-system

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/system.yml /home/${user}/.tools/.tusk/system.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.system.yml /home/${user}/.tools/tusk.system.yml

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.system.yml install.system \
    && sudo bash -c "yes | pacman -Scc"


# AUR packages.
FROM toolbox-base-system AS toolbox-base-aur

ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles/.config/pacman/makepkg.conf /home/${user}/.config/pacman/makepkg.conf
COPY --chown=${uid}:${gid} /dotfiles/.tools/.tusk/aur.yml /home/${user}/.tools/.tusk/aur.yml
COPY --chown=${uid}:${gid} /dotfiles/.tools/tusk.aur.yml /home/${user}/.tools/tusk.aur.yml

WORKDIR /home/${user}/.tools

RUN tusk -f tusk.aur.yml install.aur \
    && yay -Scc --noconfirm \
    && rm -rf /home/${user}/.cache


# Final image.
FROM toolbox-base-aur

ARG uid
ARG gid
ARG user
USER ${user}

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY --from=go-tools --chown=${uid}:${gid} /home/${user}/go/bin /home/${user}/go/bin
COPY --from=rust-tools --chown=${uid}:${gid} /home/${user}/.rustup /home/${user}/.rustup
COPY --from=php-tools --chown=${uid}:${gid} /home/${user}/.tools/vendor /home/${user}/.tools/vendor
COPY --from=js-tools --chown=${uid}:${gid} /home/${user}/.tools/node_modules /home/${user}/.tools/node_modules
COPY --from=nvim-tools --chown=${uid}:${gid} /home/${user}/.local/share/nvim /home/${user}/.local/share/nvim

WORKDIR /home/${user}/.tools

RUN tusk install.fish \
    && sudo gpasswd -d ${user} wheel \
    && sudo rm /etc/sudoers.d/01-wheel \
    && mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.cargo \
    /home/${user}/.local/share/fish \
    /home/${user}/.local/state \
    /home/${user}/go \
    /home/${user}/.rustup
