ARG uid=3000
ARG gid=3000
ARG user=dev
ARG group=dev


FROM archlinux:base-devel AS toolbox-base

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
	php-sqlite \
	composer \
	rust \
	rust-src \
	rust-analyzer \
	neovim \
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
	&& echo "%wheel      ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/01-wheel \
	&& gpasswd -a ${user} wheel

USER ${user}


FROM toolbox-base AS toolbox-aur

RUN git clone https://aur.archlinux.org/paru-bin.git ~/.cache/paru-bin \
	&& cd ~/.cache/paru-bin \
	&& makepkg --noconfirm --syncdeps --install --clean \
	&& rm -rf ~/.cache

RUN paru -S --noconfirm --needed --batchinstall --removemake --cleanafter --failfast \
	fish-fzf \
	buf-bin \
	golangci-lint-bin \
	hadolint-bin \
	phpstan \
	phpactor \
	lscolors-git \
	&& rm -rf ~/.cache


FROM toolbox-base AS go-tools

RUN go install -v github.com/rliebz/tusk@latest
RUN go install -v github.com/goccmack/gocc@latest


FROM toolbox-base AS dotfiles

ARG uid
ARG gid
ARG user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}

WORKDIR /home/${user}/.tools

RUN composer install --no-dev --no-cache --no-interaction --optimize-autoloader
RUN nvim --headless -u NORC -c 'lua require("plugins")' -c "Lazy! sync" -c "qa!" \
	&& rm -rf ~/.cache ~/.local/state
RUN fish -c "fish_update_completions"


FROM toolbox-aur

ARG user

COPY --from=dotfiles /home/${user} /home/${user}
COPY --from=go-tools /home/${user}/go/bin /home/${user}/go/bin
COPY ./etc/php /etc/php

RUN sudo gpasswd -d ${user} wheel \
	&& sudo rm /etc/sudoers.d/01-wheel

WORKDIR /workspaces
