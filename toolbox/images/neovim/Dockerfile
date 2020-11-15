FROM toolbox_build AS neovim-build

ARG user
ARG neovim_commit

USER ${user}

WORKDIR /homedir

RUN wget https://github.com/neovim/neovim/archive/${neovim_commit}.zip \
	&& unzip -q ${neovim_commit}.zip \
	&& cd neovim-${neovim_commit} \
	&& make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=/homedir/neovim -DCMAKE_BUILD_TYPE=RelWithDebInfo" \
	&& make install


FROM scratch AS neovim

COPY --from=neovim-build /homedir/neovim /neovim
