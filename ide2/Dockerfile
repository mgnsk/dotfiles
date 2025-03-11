FROM nixos/nix:latest AS builder


RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable \
    && nix-channel --update

COPY . /build
WORKDIR /build

RUN nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    build

# # Copy the Nix store closure into a directory. The Nix store closure is the
# # entire set of Nix store values that we need for our build.
# RUN mkdir /tmp/nix-store-closure
# RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure
#
#
# FROM scratch
#
# WORKDIR /app
#
# COPY --from=builder /tmp/nix-store-closure /nix/store
# COPY --from=builder /tmp/build/result /app
# CMD ["/app/bin/bash"]
