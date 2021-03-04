FROM toolbox_toolbox-aur

ARG uid
ARG gid
ARG user

COPY --chown=${uid}:${gid} /dotfiles /home/${user}

RUN bash ~/install_tools.sh \
	&& go clean -modcache \
	&& ~/.npm-global/bin/yarn cache clean --all \
	&& npm cache clean --force \
	&& rm -rf /tmp/* \
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

COPY /dotfiles/toolbox/entrypoint.fish /entrypoint.fish

ENTRYPOINT ["/entrypoint.fish"]
