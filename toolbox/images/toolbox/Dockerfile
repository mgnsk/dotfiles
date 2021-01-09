FROM fedora:33

ARG uid
ARG gid
ARG user
ARG group

RUN dnf upgrade -y \
	&& dnf groupinstall -y "C Development Tools and Libraries" \
	&& dnf install --setopt=install_weak_deps=False -y \
	git \
	cmake \
	ninja-build \
	unzip \
	gettext \
	wget \
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
	fd-find \
	bat \
	fzf \
	&& dnf clean all \
	&& groupadd -g ${gid} ${group} \
	&& useradd \
	--home-dir /homedir \
	-g ${group} \
	--uid ${uid} \
	${user} \
	&& rm -rf /root \
	&& ln -s /homedir /root

COPY --chown=${uid}:${gid} /dotfiles /homedir
COPY /dotfiles/toolbox/entrypoint.sh /entrypoint.sh

USER ${user}

WORKDIR /homedir

RUN bash -c "set -euo pipefail; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" \
	&& bash -c $'\
set -e\n\
source .env\n\
bash setup.sh\n\
go clean -modcache\n\
rm -rf .cache\n\
mkdir -p \
.cache \
.local/share/direnv \
.tmux/resurrect \
.npm-global \
.local/bin \
.local/lib'

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
