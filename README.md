# Preface

Everything in this README is written with the assumption
that the machine is set up exactly like the dotfiles.

# Installation

Modified dotfiles method based on https://www.atlassian.com/git/tutorials/dotfiles

Warning: overwrites the user's files.

```
git clone --recurse-submodules --separate-git-dir=$HOME/.git https://github.com/mgnsk/dotfiles.git $HOME/dotfiles-tmp
git config status.showUntrackedFiles no
git reset --hard --recurse-submodules origin/master
rm -r ~/dotfiles-tmp/
```

# Audio

The audio nix shell includes a Reaper and yabridge installation.
Currently we are using system-wide wine installation.
Run `ide-audio` to run the audio environment.

## Setting up Windows plugins

Drop your windows plugins into `~/.win-plugins/Plugins`.

If the plugin has a setup, then inside the audio shell run it with wine: `wine MyPluginSetup.exe`.
Attempt to install it to somewhere in `~/.win-plugins`
(through wine `Z:` volume Linux home should be available).

If you can't change the path, then determine if you can move it manually
to `~/.win-plugins` after installing. If it depends on some other files,
configure it in `~/.win-plugins/setup.sh`.

WINEPREFIX should be kept ephemerable, i.e. you could delete `~/.wine` and run the environment again
to recreate it.

- Plugins can be manually scanned with `yabridgectl sync`.
- Display plugins with `yabridgectl status`.
- To force resync, remove `~/.vst/yabridge` and `~/.vst3/yabridge` and sync again or re-enter the environment.

## Raysession

RaySession provides a way to change the PipeWire buffer size (in the top right corner).
If the patchbay connections disappear, just hit Ctrl+R to refresh.
