FROM archlinux:base-devel

ARG uid
ARG gid
ARG user
ARG group

RUN pacman -Syu --noconfirm \
	&& pacman -S --noconfirm --needed \
	git \
	cmake \
	ninja \
	unzip \
	wget \
	bind \
	tmux \
	bash-completion \
	earlyoom \
	tree \
	shellcheck \
	tidy \
	rubygems \
	ansible \
	python-pip \
	clang \
	npm \
	luarocks \
	go \
	ripgrep \
	most \
	ctags \
	brotli \
	fd \
	bat \
	fzf \
	rustup \
	sccache \
	parallel \
	moreutils \
	&& bash -c "yes | pacman -Scc"

RUN groupadd -g ${gid} ${group} \
	&& useradd \
	--home-dir /homedir \
	-g ${group} \
	--uid ${uid} \
	${user} \
	&& passwd -d ${user} \
	&& echo "${user} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers.d/01-user \
	&& rm -rf /root \
	&& ln -s /homedir /root

COPY --chown=${uid}:${gid} /dotfiles /homedir
COPY /dotfiles/toolbox/entrypoint.sh /entrypoint.sh

USER ${user}

RUN bash /homedir/setup.sh \
	&& sudo rm /etc/sudoers.d/01-user

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
