FROM github.com/mgnsk/toolbox/base

ARG user
ARG group

COPY --chown=${user}:${group} /dotfiles /homedir

RUN bash ~/setup.sh \
	&& rm -rf ~/.cache \
	&& mkdir -p \
	~/.cache \
	~/.local/share/nvim \
	~/.local/share/direnv \
	~/.tmux/resurrect \
	~/.composer \
	~/.npm-global \
	~/go \
	~/.cargo \
	~/.local/bin \
	~/.local/lib \
	&& touch ~/.bash_history

WORKDIR /workspace
