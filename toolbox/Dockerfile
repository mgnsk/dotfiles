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
	rustup \
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
	lscolors-git \
	&& rm -rf ~/.cache


FROM toolbox-base AS go-tools

RUN go install -v github.com/rliebz/tusk@latest
RUN go install -v github.com/goccmack/gocc@latest


FROM toolbox-base AS rust-tools

RUN rustup default nightly
RUN rustup component add rustfmt rust-src clippy rust-analyzer-preview


FROM toolbox-base AS php-tools

COPY /dotfiles/.tools/composer.json /home/${user}/.tools/composer.json
COPY /dotfiles/.tools/composer.lock /home/${user}/.tools/composer.lock
RUN composer -d /home/${user}/.tools install --no-dev --no-cache --no-interaction --optimize-autoloader


FROM toolbox-base AS nvim-plugins

ARG user

COPY /dotfiles/.config/nvim/lua/plugins.lua /home/${user}/.config/nvim/lua/plugins.lua
COPY /dotfiles/.config/nvim/lazy-lock.json /home/${user}/.config/nvim/lazy-lock.json
RUN nvim --headless -u NORC \
	-c 'lua if not require("plugins") then os.exit(1) end' \
	-c 'lua local ok, result = pcall(vim.cmd, "Lazy! restore"); if not ok then os.exit(1) end' \
	-c 'lua os.exit(0)'


FROM toolbox-aur

ARG uid
ARG gid
ARG user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
RUN mkdir -p /home/${user}/go /home/${user}/.cargo
COPY --from=go-tools --chown=${uid}:${gid} /home/${user}/go/bin /home/${user}/go/bin
COPY --from=rust-tools /home/${user}/.rustup /home/${user}/.rustup
COPY --from=php-tools /home/${user}/.tools/vendor /home/${user}/.tools/vendor
COPY --from=nvim-plugins /home/${user}/.local/share/nvim /home/${user}/.local/share/nvim
COPY ./etc/php /etc/php

RUN fish -c "fish_update_completions"
RUN sudo gpasswd -d ${user} wheel \
	&& sudo rm /etc/sudoers.d/01-wheel

WORKDIR /workspaces
