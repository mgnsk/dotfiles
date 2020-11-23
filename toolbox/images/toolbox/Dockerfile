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

COPY --chown=${user}:${group} /dotfiles /homedir
COPY --from=toolbox_neovim /neovim /homedir/neovim
COPY --from=toolbox_rust --chown=${user}:${group} /cargo.tar.gz /homedir/cargo.tar.gz
COPY --from=toolbox_rust --chown=${user}:${group} /rustup.tar.gz /homedir/rustup.tar.gz

USER ${user}

ENV USER=${user}

WORKDIR /homedir

RUN bash -c $'\
set -e\n\
mkdir -p .cargo .rustup\n\
tar -zxf cargo.tar.gz -C .\n\
tar -zxf rustup.tar.gz -C .\n\
rm -rf cargo.tar.gz rustup.tar.gz\n\
source .env\n\
bash setup.sh\n\
go clean -modcache\n\
rm -rf .cache\n\
mkdir -p \
.cache \
.local/share/nvim \
.local/share/direnv \
.tmux/resurrect \
.composer \
.npm-global \
go \
.cargo \
.local/bin \
.local/lib'

WORKDIR /workspace

ENTRYPOINT ["/homedir/toolbox/entrypoint.sh"]
