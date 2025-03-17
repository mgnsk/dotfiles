# Installation

Modified dotfiles method based on https://www.atlassian.com/git/tutorials/dotfiles

Warning: overwrites the user's files.

```
git clone --recurse-submodules --separate-git-dir=$HOME/.git https://github.com/mgnsk/dotfiles.git $HOME/dotfiles-tmp
git config status.showUntrackedFiles no
git reset --hard --recurse-submodules origin/master
rm -r ~/dotfiles-tmp/
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

## Run the container

Navigate to a project directory and run `ide` or `ide-docker` to enter the environment.
A bash shell starts in the current directory.

From there on, for example, you can continue by invoking `nvim`.

```sh
cd ~/Projects/project1
ide
nvim
```

An example using `tmux` would be to spawn a container in the projects root directory `~/Projects`, running tmux and using each project in its own tmux window.
Sometimes it is useful to use tmux inside a single project to run multiple instances of neovim for different parts of the project.
