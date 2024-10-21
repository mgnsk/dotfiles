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

# Toolbox

The toolbox is an immutable development environment container.
It's main application is running neovim.

The following is a guide on how to run the toolbox without installing the dotfiles
onto the host machine.

## Setting up the host machine

The toolbox requires docker to be set up on the machine.
Install [tusk](https://rliebz.github.io/tusk) to run tasks:

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

Add the absolute path to `dotfiles/toolbox/bin` directory to your PATH to use the `ide` executable script.

## Run neovim

Navigate to a project directory and run the `ide` executable script to start a new fish shell in the container.
The shell starts in the current directory bind mounted into the container.

From there on, for example, you can start by invoking either `tmux` or `nvim`. See the [Neovim keymap docs](https://github.com/mgnsk/dotfiles/blob/master/.config/nvim/README.md).

```sh
cd ~/Projects/project1
ide
```

An example using `tmux` would be to spawn a container in the projects root directory `~/Projects`, running tmux and using each project in its own terminal.
Sometimes it is useful to use tmux inside a single project to run multiple instances of neovim for different parts of the project.
