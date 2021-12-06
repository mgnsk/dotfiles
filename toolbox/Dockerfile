FROM archlinux:base-devel

RUN pacman -Syy \
	&& pacman -S --noconfirm --needed reflector \
	&& reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist \
	&& pacman -Syu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
	unzip \
	wget \
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
	&& passwd -d ${user}

USER ${user}

RUN git clone https://aur.archlinux.org/yay.git ~/.cache/yay \
	&& cd ~/.cache/yay \
	&& makepkg -si --noconfirm \
	&& yay -S --noconfirm --needed \
	fish-fzf-git \
	direnv \
	hadolint-bin \
	neovim-git \
	&& yay -c --noconfirm \
	&& bash -c "yes | yay -Scc" \
	&& cd \
	&& rm -rf ~/.cache

RUN git clone --recurse-submodules --separate-git-dir=/home/${user}/.dotfiles https://github.com/mgnsk/dotfiles.git /home/${user}/dotfiles-tmp \
	&& rm -r ~/dotfiles-tmp \
	&& alias config="/usr/bin/git --git-dir=/home/${user}/.dotfiles/ --work-tree=/home/${user}" \
	&& config config status.showUntrackedFiles no \
	&& config reset --hard origin/master \
	&& bash ~/install_tools.sh \
	&& go clean -modcache \
	&& ~/.npm-global/bin/yarn cache clean --all \
	&& npm cache clean --force \
	&& rm -rf \
	/tmp/* \
	~/.cache \
	~/.cargo/registry \
	&& mkdir -p \
	~/.cache \
	~/.local/share/direnv \
	~/.tmux/resurrect \
	~/.npm-global \
	~/.local/bin \
	~/.local/lib

WORKDIR /workspaces
