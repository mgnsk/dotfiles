FROM archlinux:base-devel AS toolbox-base

RUN pacman -Syyu --noconfirm \
	&& pacman -S --noconfirm --needed git \
	&& bash -c "yes | pacman -Scc"


FROM toolbox-base AS go-tools

ENV GOPATH /go

RUN pacman -S --noconfirm --needed go \
	&& bash -c "yes | pacman -Scc" \
	&& go install -v github.com/rliebz/tusk@latest \
	&& go install -v github.com/goccmack/gocc@latest \
	&& go clean -modcache


FROM toolbox-base AS rust-tools

ENV CARGO_HOME /cargo
ENV PATH=$PATH:/cargo/bin

RUN bash -c "curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y" \
	&& rustup default nightly \
	&& rustup component add rustfmt rust-src clippy rust-analyzer-preview \
	&& rm -rf ~/.cargo/registry


FROM toolbox-base

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
	&& echo "%wheel      ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/01-wheel \
	&& gpasswd -a ${user} wheel

USER ${user}

RUN git clone https://aur.archlinux.org/paru-bin.git ~/.cache/paru-bin \
	&& cd ~/.cache/paru-bin \
	&& makepkg --noconfirm --syncdeps --install --clean \
	&& paru -S --noconfirm --needed --batchinstall --removemake --cleanafter --failfast \
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
	prettier \
	typescript-language-server \
	vscode-html-languageserver \
	vscode-css-languageserver \
	npm \
	eslint \
	go \
	gopls \
	go-tools \
	revive \
	python \
	ansible-lint \
	ansible-language-server \
	yamllint \
	shellcheck \
	shfmt \
	bash-language-server \
	brotli \
	direnv \
	luarocks \
	lua-language-server \
	luacheck \
	stylua \
	pgformatter \
	ruby-mdl \
	rtmidi \
	php \
	composer \
	# AUR packages
	fish-fzf \
	neovim-git \
	buf-bin \
	hadolint-bin \
	phpstan-bin \
	phpactor \
	&& sudo gpasswd -d ${user} wheel \
	&& sudo rm /etc/sudoers.d/01-wheel \
	&& rm -rf /home/${user}/.cache

COPY --from=go-tools --chown=${uid}:${gid} /go /home/${user}/go
COPY --from=rust-tools --chown=${uid}:${gid} /cargo /home/${user}/.cargo
COPY --chown=${uid}:${gid} /dotfiles /home/${user}

ENV IS_CONTAINER "1"

RUN cd /home/${user}/.tools && /home/${user}/go/bin/tusk install

WORKDIR /workspaces
