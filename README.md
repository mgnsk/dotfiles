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

# Installation on a fresh Arch system

Download the install script:

```sh
curl https://raw.githubusercontent.com/mgnsk/dotfiles/refs/heads/master/.scripts/postinstall.sh
```

Run the install script and follow instructions.

# development IDE

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

# Audio

The audio nix shell includes a Reaper, yabridge and wine installation.
For CLI usage (to install plugins, etc.), run `ide` and select audio.

The host system is assumed to run a PipeWire audio server and the operating user is assumed to have realtime privileges.
Audio applications connect to PipeWire via the JACK API.

## Reaper on Wayland

Some plugins that use Vulkan, have rendering issues on Wayland.
In TTY1 (in the Sway/Wayland), start Reaper (Wayland) application
to fix those issues but suffer some graphical interface latency
and CPU overhead due to running in Xpra.

## Reaper on Xorg

In TTY2 (in Openbox/Xorg), start Reaper application. The best way to run it.

## Linux plugins

The audio shell includes some CLAP plugins, which are made available via
the `CLAP_PATH` env var. Ensure Reaper is configured to search from `%CLAP_PATH%`.
It is important that `CLAP_PATH` entries are separated via semicolon.

Currently there are no LV2 plugins in use but Reaper has an issue with reading
the `LV2_PATH` env var. To use LV2 plugins, install or symlink them to `~/.lv2`
and make sure this path is configured in Reaper.

I have not attempted to configure any other Linux plugin format.

## Setting up Windows plugins

Drop your windows plugins into `~/.win-plugins`.

If the plugin has a setup, then inside the audio shell run it with wine: `wine MyPluginSetup.exe`.
Attempt to install it to `~/.win-plugins`
(through wine `Z:` volume Linux home should be available).

If you can't change the path, then determine if you can move it manually
to `~/.win-plugins` after installing. If it depends on some other files,
it is probably best to leave it as is and add the plugin path to
yabridgectl in `flake.nix` file.

The idea is to attempt to keep WINEPREFIX ephemerable as possible.

- Plugins can be manually scanned with `yabridgectl sync`.
- Display plugins with `yabridgectl status`.
- To force resync, remove `~/.vst/yabridge` and `~/.vst3/yabridge` and sync again.

## Raysession

RaySession provides a way to change the PipeWire buffer size (in the top right corner).
If the patchbay connections disappear, just hit Ctrl+R to refresh.

# Useful nix stuff

## diff-highlight to /bin

### Overlays

The recommended way to do overlays. This causes the package to be built from source though.
Downstream users get the modified `git` package.

```nix
pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        git = prev.git.overrideAttrs (
          finalAttrs: previousAttrs: {
            # Make diff-highlight available directly.
            postInstall =
              (previousAttrs.postInstall or "")
              + ''
                ln -s $out/share/git/contrib/diff-highlight/diff-highlight $out/bin/diff-highlight
                    '';
          }
        );
      })
    ];
};
```

### linkFarm

Symlinks only the single file we need. The new package contains only the `/bin/diff-highlight` symlimk.

```nix
diff-highlight = pkgs.linkFarm "diff-highlight" [
    {
      name = "bin/diff-highlight";
      path = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
    }
];
```
