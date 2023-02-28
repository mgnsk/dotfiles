FROM archlinux:base-devel


RUN pacman -Syyu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
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
	npm \
	go \
	python \
	brotli \
	direnv \
	luarocks \
	pgformatter \
	rtmidi \
	&& bash -c "yes | pacman -Scc"

ARG uid
ARG gid
ARG user
ARG group

RUN if grep -q "${group}:" /etc/group; then \
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
	&& echo "%wheel      ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/01-user \
	&& gpasswd -a ${user} wheel

USER ${user}

RUN for pkg in \
	fish-fzf \
	neovim-git \
	; do \
	mkdir -p "/home/${user}/.cache/$pkg" \
	&& cd "/home/${user}/.cache/$pkg" \
	&& git clone "https://aur.archlinux.org/$pkg.git" . \
	&& makepkg -si --syncdeps --noconfirm \
	; done \
	&& cd \
	&& rm -rf ~/.cache \
	&& sudo gpasswd -d ${user} wheel \
	&& sudo rm /etc/sudoers.d/01-user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}

RUN bash ~/install_tools.sh \
	&& go clean -modcache \
	&& npm cache clean --force \
	&& rm -rf \
	/tmp/* \
	~/.cache \
	~/.cargo/registry \
	&& mkdir -p \
	~/.cache \
	~/.cargo \
	~/.local \
	~/go

WORKDIR /workspaces
