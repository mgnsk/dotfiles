Dotfiles method based on https://www.atlassian.com/git/tutorials/dotfiles

# Installation

Warning: overwrites the user's files.

```
$ git clone --recurse-submodules --separate-git-dir=$HOME/.dotfiles https://github.com/mgnsk/dotfiles.git $HOME/dotfiles-tmp
$ rm -r ~/dotfiles-tmp/
$ alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
$ config config status.showUntrackedFiles no
$ config reset --hard origin/master
```

[Neovim keymap](.config/nvim/README.md)

# Toolbox

The toolbox is a rootless development environment container running on podman.
It's main application is running neovim.
The following is a guide on how to run the toolbox without installing the dotfiles
onto the host machine.

## Setting up the host machine

Install [tusk](https://rliebz.github.io/tusk):

from binary:

```sh
curl -sL https://git.io/tusk | bash -s -- -b /usr/local/bin latest
```

or from source:

```sh
go install -v github.com/rliebz/tusk@latest
```

## Clone the repository

```sh
git clone git@github.com:mgnsk/dotfiles.git dotfiles
cd dotfiles/toolbox
```

## Setup podman

```sh
tusk setup
```

## Build the image

Build the image:

```sh
tusk build
```

Add the absolute path to `dotfiles/bin` directory to your PATH to use the `nv` executable script.

## Run neovim

Navigate to a project directory and run it:

```sh
cd ~/Projects/project1
nv
```

## Technical notes

The toolbox uses native overlay driver by default which has this problem: https://github.com/containers/podman/issues/16541
Using the userspace `fuse-overlayfs` can avoid this but has horrible performance during runtime.
