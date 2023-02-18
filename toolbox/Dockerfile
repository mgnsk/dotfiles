FROM archlinux:base-devel


RUN pacman -Syyu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
	unzip \
	wget \
	tmux \
	vim \
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
	brotli \
	rustup \
	direnv \
	luarocks \
	neovim \
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

RUN mkdir -p ~/.cache && cd ~/.cache \
	&& for pkg in fish-fzf ruby-google-protobuf ruby-pg-query ruby-sqlint; do \
	git clone "https://aur.archlinux.org/$pkg.git" "$pkg" && cd "$pkg" && makepkg -si --syncdeps --noconfirm; done \
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
