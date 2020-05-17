### Immutable development image

This image serves the purpose of documenting my default environment. The dotfiles URL and commit are build arguments which accept a repository managed with [chezmoi](https://github.com/twpayne/chezmoi).

Quick run
`$ docker run --rm -it --entrypoint /asuser.sh -e UID=$(id -u) -e USER=$(id -un) -e GID=$(id -g) -e GROUP=$(id -gn) mgnsk/dev-env /bin/bash`

The default entrypoint `/asroot.sh` runs as root.
The `/asuser.sh` entrypoint creates a user and runs as it.

All vim plugins are locked to git commits.

`earlyoom` is started on each bash session.

### Go

[gopher.vim](https://github.com/arp242/gopher.vim) is used. It installs go tools by using a module.
Everything is thus version-locked.

### Tasks

Build and run:

`$ tusk build`

`$ tusk bash`
 

 To download/update image, run:

`$ tusk clean`

`$ tusk bash`
