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

The toolbox is an immutable development environment container.
It's main application is running neovim.
The following is a guide on how to run the toolbox without installing the dotfiles
onto the host machine.

## Setting up the host machine

The toolbox requires docker to bet set up on the machine.
Install [tusk](https://rliebz.github.io/tusk) to run tasks:

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

## Build the image

Build the image:

```sh
tusk build
```

Add the absolute path to `dotfiles/bin` directory to your PATH to use the `ide` executable script.

## Run neovim

Navigate to a project directory and run the `ide` executable script to start a new fish shell in the container.
The shell starts in the current directory bind mounted into the container.

From there on, for example, you can start by invoking either `tmux` or `nvim`. See the [Neovim keymap docs](https://github.com/mgnsk/dotfiles/blob/master/.config/nvim/README.md).

```sh
cd ~/Projects/project1
ide
```

An example using `tmux` would be to spawn a container in the projects root directory `~/Projects` and using each project in its own `tmux` window.
