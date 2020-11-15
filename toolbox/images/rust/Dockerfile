FROM toolbox_build AS rust-build

ARG user

USER ${user}

WORKDIR /homedir

RUN bash -c "set -euo pipefail; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" \
	&& tar -zcf cargo.tar.gz .cargo \
	&& tar -zcf rustup.tar.gz .rustup \
	&& rm -rf .cargo .rustup


FROM scratch AS rust

COPY --from=rust-build /homedir/cargo.tar.gz /cargo.tar.gz
COPY --from=rust-build /homedir/rustup.tar.gz /rustup.tar.gz
