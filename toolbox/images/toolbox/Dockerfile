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

COPY --chown=${uid}:${gid} /dotfiles /home/${user}
COPY /dotfiles/toolbox/entrypoint.sh /entrypoint.sh

USER ${user}

RUN bash /home/${user}/setup.sh \
	&& paru -c --noconfirm \
	&& bash -c "yes | paru -Scc" \
	&& sudo rm /etc/sudoers.d/01-user \
	&& bash /home/${user}/install_tools.sh \
	&& go clean -modcache \
	&& rm -rf \
	/home/${user}/.cache \
	/home/${user}/.cargo/registry \
	&& mkdir /home/${user}/.cache

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
