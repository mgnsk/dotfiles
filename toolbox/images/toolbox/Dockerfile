FROM toolbox_toolbox-base

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
	&& passwd -d ${user} \
	&& echo "${user} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers.d/01-user

USER ${user}

RUN git clone https://aur.archlinux.org/paru-bin.git /tmp/paru \
	&& cd /tmp/paru \
	&& makepkg -si --noconfirm \
	&& paru -S --noconfirm --needed \
	fish-fzf-git \
	direnv \
	hadolint-bin \
	neovim-git \
	&& paru -c --noconfirm \
	&& bash -c "yes | paru -Scc" \
	&& sudo rm -rf /tmp \
	&& sudo install -d -m 0777 /tmp \
	&& sudo rm /etc/sudoers.d/01-user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY /dotfiles/toolbox/entrypoint.fish /entrypoint.fish

RUN bash ~/install_tools.sh \
	&& go clean -modcache \
	&& rm -rf \
	~/.cache \
	~/.cargo/registry \
	&& mkdir -p \
	~/.cache \
	~/.local/share/direnv \
	~/.tmux/resurrect \
	~/.npm-global \
	~/.local/bin \
	~/.local/lib

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.fish"]
