FROM archlinux:base-devel

RUN pacman -Syyu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
	unzip \
	wget \
	tmux \
	vim \
	bash-completion \
	fish \
	tree \
	ripgrep \
	fd \
	bat \
	fzf \
	skim \
	the_silver_searcher \
	parallel \
	moreutils \
	cmake \
	ninja \
	earlyoom \
	shellcheck \
	tidy \
	rubygems \
	python-pip \
	clang \
	npm \
	luarocks \
	go \
	ctags \
	brotli \
	rustup \
	sccache \
	yamllint \
	ansible-lint \
	vint \
	direnv \
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
	fish-fzf-git \
	hadolint-bin \
	neovim-git \
	&& yay -c --noconfirm \
	&& bash -c "yes | yay -Scc" \
	&& cd \
	&& rm -rf ~/.cache \
	&& sudo gpasswd -d ${user} wheel \
	&& sudo rm /etc/sudoers.d/01-user

ARG cachebust=1
RUN git clone --recurse-submodules --separate-git-dir=/home/${user}/.dotfiles https://github.com/mgnsk/dotfiles.git /home/${user}/dotfiles-tmp \
	&& rm -r ~/dotfiles-tmp \
	&& git --git-dir=/home/${user}/.dotfiles/ --work-tree=/home/${user} reset --hard origin/master \
	&& bash ~/install_tools.sh \
	&& go clean -modcache \
	&& npm cache clean --force \
	&& rm -rf \
	/tmp/* \
	~/.cache \
	~/.cargo/registry \
	&& mkdir -p \
	~/.cache \
	~/.local/share/direnv \
	~/.tmux/resurrect \
	~/.local/bin \
	~/.local/lib

WORKDIR /workspaces
