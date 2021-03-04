FROM toolbox_toolbox-base

ARG uid
ARG gid
ARG user
ARG group

RUN groupadd -g ${gid} ${group} \
	&& useradd \
	-m \
	-s /usr/bin/fish \
	-g ${group} \
	--uid ${uid} \
	${user} \
	&& passwd -d ${user} \
	&& echo "${user} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers.d/01-user

USER ${user}

RUN git clone https://aur.archlinux.org/paru-bin.git ~/.cache/paru \
	&& cd ~/.cache/paru \
	&& makepkg -si --noconfirm \
	&& paru -S --noconfirm --needed \
	fish-fzf-git \
	direnv \
	hadolint-bin \
	neovim-git \
	&& paru -c --noconfirm \
	&& bash -c "yes | paru -Scc" \
	&& cd \
	&& rm -rf ~/.cache
