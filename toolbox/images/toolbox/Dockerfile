FROM toolbox_build

ARG user
ARG group

RUN dnf install --setopt=install_weak_deps=False -y \
	bind-utils \
	diffutils \
	tmux \
	bash-completion \
	procps \
	earlyoom \
	tree \
	ShellCheck \
	tidy \
	rubygems \
	ruby-devel \
	perl \
	ansible \
	python-pip \
	python-devel \
	clang-tools-extra \
	npm \
	lua-devel \
	luarocks \
	go \
	ripgrep \
	most \
	direnv \
	hadolint \
	ctags \
	gzip \
	brotli \
	&& dnf clean all

COPY --from=toolbox_neovim /neovim /homedir/neovim
COPY --from=toolbox_rust --chown=${user}:${group} /cargo.tar.gz /homedir/cargo.tar.gz
COPY --from=toolbox_rust --chown=${user}:${group} /rustup.tar.gz /homedir/rustup.tar.gz
ADD --chown=${user}:${group} /dotfiles.tar.gz /homedir

USER ${user}

ENV USER=${user}

WORKDIR /homedir

RUN mkdir -p .cargo .rustup \
	&& tar -zxf cargo.tar.gz -C . \
	&& tar -zxf rustup.tar.gz -C . \
	&& rm -rf cargo.tar.gz rustup.tar.gz \
	&& bash ~/setup.sh \
	&& rm -rf ~/.cache \
	&& mkdir -p \
	~/.cache \
	~/.local/share/nvim \
	~/.local/share/direnv \
	~/.tmux/resurrect \
	~/.composer \
	~/.npm-global \
	~/go \
	~/.cargo \
	~/.local/bin \
	~/.local/lib \
	&& touch ~/.bash_history

WORKDIR /workspace

ENTRYPOINT ["/homedir/toolbox/entrypoint.sh"]
