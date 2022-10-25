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
	shellcheck \
	tidy \
	npm \
	go \
	gopls \
	go-tools \
	brotli \
	rustup \
	yamllint \
	ansible-lint \
	vint \
	direnv \
	delve \
	revive \
	shfmt \
	bash-language-server \
	stylelint \
	stylelint-config-standard \
	typescript \
	typescript-language-server \
	yaml-language-server \
	eslint \
	luarocks \
	luacheck \
	lua-language-server \
	stylua \
	prettier \
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

RUN git clone https://aur.archlinux.org/yay.git ~/.cache/yay \
	&& cd ~/.cache/yay \
	&& makepkg -si --noconfirm \
	&& yay -S --noconfirm --needed \
	fish-fzf \
	hadolint-bin \
	buf \
	protoc-gen-go \
	protoc-gen-go-grpc \
	golangci-lint \
	nodejs-markdownlint-cli \
	nodejs-dockerfile-utils \
	vscode-langservers-extracted \
	dockerfile-language-server \
	ruby-sqlint \
	&& yay -c --noconfirm \
	&& bash -c "yes | yay -Scc" \
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
	~/.local/bin \
	~/.local/lib

WORKDIR /workspaces
