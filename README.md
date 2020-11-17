![example workflow name](https://github.com/mgnsk/dotfiles/workflows/build/badge.svg)

# Installation

Warning: overwrites the user's files.

```
$ git clone --separate-git-dir=$HOME/.dotfiles https://github.com/mgnsk/dotfiles.git $HOME/dotfiles-tmp
$ rm -r ~/dotfiles-tmp/
$ alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
$ config config status.showUntrackedFiles no
$ config reset --hard origin/master
```
