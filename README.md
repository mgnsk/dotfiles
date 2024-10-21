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

# IDE

`ide` is an immutable development environment container image.
It's main application is running neovim.

The following is a guide on how to run the container by using a pre-built Docker image
hosted on Github Container Registry.

## Clone the repository

```sh
git clone git@github.com:mgnsk/dotfiles.git dotfiles
cd dotfiles/ide
```

Add the absolute path to `dotfiles/ide/bin` directory to your PATH to use the `ide` executable script.
After configuring PATH, verify the script is accessible by running `which ide` in a new terminal.

## Run the container

Navigate to a project directory and run `ide` to enter the container.
A fish shell starts in the current directory bind mounted into the container.

From there on, for example, you can continue by invoking `nvim`.

```sh
cd ~/Projects/project1
ide
nvim
```

An example using `tmux` would be to spawn a container in the projects root directory `~/Projects`, running tmux and using each project in its own tmux window.
Sometimes it is useful to use tmux inside a single project to run multiple instances of neovim for different parts of the project.
