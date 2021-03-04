FROM archlinux:base-devel

RUN pacman -Syu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
	unzip \
	wget \
	bind \
	tmux \
	bash-completion \
	fish \
	tree \
	ripgrep \
	most \
	fd \
	bat \
	fzf \
	parallel \
	moreutils \
	cmake \
	ninja \
	earlyoom \
	shellcheck \
	tidy \
	rubygems \
	ansible \
	python-pip \
	clang \
	npm \
	luarocks \
	go \
	ctags \
	brotli \
	rustup \
	sccache \
	rust-analyzer \
	&& bash -c "yes | pacman -Scc"
