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

# Neovim keymap

## Visual mode

| Shortcut |                   Action |
| -------- | -----------------------: |
| Y        | Yank to system clipboard |
| jj       |                   Escape |

## Terminal mode

| Shortcut | Action |
| -------- | -----: |
| jj       | Escape |

## Insert mode

| Shortcut | Action |
| -------- | -----: |
| jj       | Escape |

## Normal mode

| Shortcut |                                              Action |
| -------- | --------------------------------------------------: |
| qq       |                                         kill buffer |
| C-h      |                                   move to left pane |
| C-j      |                                  move to lower pane |
| C-k      |                                  move to upper pane |
| C-l      |                                  move to right pane |
| ,.       |                                        command mode |
| ,,       |                    open a new terminal to the right |
| tt       |                             open a new terminal tab |
| ,v       |                                      split to right |
| ,s       |                                     split to bottom |
| ,t       |                                      open a new tab |
| ,e       |                    open a file browser in a new tab |
| ,j       |                           switch to the next buffer |
| ,k       |                       switch to the previous buffer |
| ,u       |                                     indent the file |
| ,p       |                                         fzf builtin |
| ,/       |                                        fzf commands |
| ,b       |                                         fzf buffers |
| ,g       |                                       fzf live_grep |
| ,a       |                                    fzf grep_project |
| ,o       |                                           fzf files |
| ,T       |                                            fzf tags |
| ,f       |                            fzf lsp document symbols |
| ,F       |                           fzf lsp workspace symbols |
| ,G       |                                         git history |
| ,B       |                                           git blame |
| ,W       | merge the current file when resolving git conflicts |
| ,V       |                                     open vista pane |
| ,l       |                                  toggle cursor lock |
| ,K       |                              align panes vertically |
| ,H       |                            align panes horizontally |
| ,mt      |                                   move tab to right |
| ,mT      |                                    move tab to left |
| ,[1-9]   |                                       switch to tab |
| ,0       |                                  switch to last tab |
| gj       |                             move to next diagnostic |
| gk       |                             move to prev diagnostic |
| gd       |                                     goto definition |
| ga       |                                         code action |
| ,rn      |                                              rename |
| K        |                                           show docs |
| gD       |                                show implementations |
| gr       |                                     show references |
| gn       |                                 goto next reference |
| gp       |                                 goto prev reference |
