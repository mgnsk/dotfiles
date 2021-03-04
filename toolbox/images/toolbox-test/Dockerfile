FROM archlinux:base-devel

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Sy --noconfirm fish

RUN groupadd -g ${gid} ${group} \
	&& useradd \
	-m \
	-s /usr/bin/fish \
	-g ${group} \
	--uid ${uid} \
	${user} \
	&& passwd -d ${user} \
	&& echo "${user} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers.d/01-user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}

USER ${user}

WORKDIR /workspace
