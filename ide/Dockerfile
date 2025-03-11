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
    bash \
    git \
    nix \
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
    && echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen \
    && echo "LANG=en_US.UTF-8" >>/etc/locale.conf \
    && locale-gen \
    && gpasswd -a ${user} nix-users \
    && chown -R ${uid}:${gid} /nix


# Final image.
FROM build-base

ARG uid
ARG gid
ARG user
USER ${user}

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable \
    && nix-channel --update \
    && git clone --recurse-submodules --separate-git-dir=/home/${user}/.dotfiles https://github.com/mgnsk/dotfiles.git /home/${user}/dotfiles-tmp \
    && rm -r /home/${user}/dotfiles-tmp/

RUN git --git-dir=/home/${user}/.dotfiles/ --work-tree=/home/${user} config status.showUntrackedFiles no \
    && git --git-dir=/home/${user}/.dotfiles/ --work-tree=/home/${user} reset --hard origin/master

RUN mkdir -p \
    /home/${user}/.cache \
    /home/${user}/.cargo \
    /home/${user}/.local/share \
    /home/${user}/.local/state \
    /home/${user}/go/bin \
    /home/${user}/go/pkg
