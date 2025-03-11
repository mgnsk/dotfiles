Dotfiles method based on https://www.atlassian.com/git/tutorials/dotfiles

# Installation

Warning: overwrites the user's files.

```
$ git clone --recurse-submodules --separate-git-dir=$HOME/.dotfiles https://github.com/mgnsk/dotfiles.git $HOME/dotfiles-tmp
$ rm -r ~/dotfiles-tmp/
$ alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
$ config config status.showUntrackedFiles no
$ config reset --hard --recurse-submodules origin/master
```

# IDE

`ide` is the nix development environment.
`ide-docker` is the nix in docker development environment.

It's main application is running neovim and companion tools.

The nix environment needs only the `nix` package manager:

https://nixos.org/download/

The docker environment needs only `docker` with the `compose` plugin:

https://docs.docker.com/engine/install/
https://docs.docker.com/compose/install/

## Clone the repository

```sh
git clone git@github.com:mgnsk/dotfiles.git dotfiles
cd dotfiles/ide
```

Add the absolute path to `dotfiles/ide/bin` directory to your PATH to use the `ide` and `ide-docker` executable scripts.

## Run the container

Navigate to a project directory and run `ide` or `ide-docker` to enter the environment.
A bash shell starts in the current directory.

In the environment, run `dotfiles/.tools/install-nvim.sh` to set up neovim plugin dependencies.

You may want to install some go tools: `dotfiles/.tools/install-go.sh`.

TODO: automate both of these.

From there on, for example, you can continue by invoking `nvim`.

```sh
cd ~/Projects/project1
ide
nvim
```

An example using `tmux` would be to spawn a container in the projects root directory `~/Projects`, running tmux and using each project in its own tmux window.
Sometimes it is useful to use tmux inside a single project to run multiple instances of neovim for different parts of the project.
