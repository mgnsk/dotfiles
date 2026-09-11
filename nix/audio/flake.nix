{
  description = "audio";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      audiopkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      levelrider = audiopkgs.stdenv.mkDerivation {
        name = "levelrider";
        src = audiopkgs.fetchFromGitHub {
          owner = "unicornsasfuel";
          repo = "levelrider";
          rev = "ef54128";
          sha256 = "sha256-vyoqoA75hQ7SbliPCVs8ZTmDS3GHPGId4hF/9c34lB8=";
        };

        buildInputs = [
          audiopkgs.which
          audiopkgs.faust2lv2
        ];

        dontWrapQtApps = true;

        buildPhase = ''
          faust2lv2 -vec -time -t 99999 levelrider.dsp
        '';

        installPhase = ''
          mkdir -p $out/lib/lv2
          cp -r levelrider.lv2/ $out/lib/lv2
        '';
      };

      # giang17's Direct2D 1.3 / DirectComposition fork of Wine
      # (https://github.com/giang17/wine, branch d2d1-dcomp-11.16, pinned to
      # the same 11.16 version as the staging build this replaces below).
      #
      # Stock Wine (even with staging) only implements Direct2D up to
      # feature level 1.2 and doesn't implement DCompositionCreateDevice at
      # all (E_NOTIMPL). JUCE 8 plugins use Direct2D + DirectComposition
      # unconditionally for their GUI, and some older JUCE plugins (e.g.
      # Xfer OTT) also hit incomplete/stubbed Direct2D code paths - either
      # way the result is a plugin window that's rendered but genuinely
      # black, while audio/MIDI/automation keep working fine. This was
      # confirmed empirically (not just by matching this known upstream
      # issue): see the "2026-09-10" update in refactor.md - a matched
      # fail/success xwayland-satellite/Xwayland trace pair showed the
      # compositing pipeline (Xwayland + xwayland-satellite) faithfully
      # copying every damaged region through to the Wayland surface in
      # BOTH cases, ruling out any Xwayland-level race - the pixmap
      # content itself is what's black, which points at wine's own
      # Direct2D/DXVK rendering rather than anything downstream of it.
      #
      # giang17's fork is not layered as a patch on top of nixpkgs' own
      # wine-staging patchset - it's a full modified source tree - so this
      # replaces `src` (and drops staging + the small nixpkgs patches, none
      # of which touch d2d1/dcomp) rather than trying to combine both.
      wineD2DSrc = audiopkgs.fetchgit {
        url = "https://github.com/giang17/wine";
        rev = "a893414dfaa07d8d86719df8f67b1bd53b29dbb8"; # d2d1-dcomp-11.16 branch HEAD, 2026-09-04
        hash = "sha256-YRlEUumTICo2y8+62sODmrNnYpRpmc8ftrprQnQ7yfY=";
      };

      # wineWow (classic 32+64-bit split build, as opposed to the merged
      # WoW64 build nixpkgs exposes by default) - yabridge's bitbridge
      # (32-bit host support) only compiles against the classic split, see
      # yabridge upstream issue #435 for the WoW64 incompatibility - so
      # this is what yabridgeGitMaster below is built against.
      bitbridgeWine =
        (audiopkgs.wine.override {
          wineBuild = "wineWow";
          wineRelease = "unstable"; # version 11.16, matches wineD2DSrc's base
        }).overrideAttrs
          (old: {
            version = "11.16-d2d1-dcomp";
            src = wineD2DSrc;
            patches = [ ];
          });

      # Modern Wine merged the separate wine/wine64 loader binaries into a
      # single arch-detecting `wine` binary, but winetricks (as packaged in
      # nixpkgs-audio) still expects a `wine64` binary to exist for 64-bit
      # WINEPREFIX setup (see winetricks_early_wine_arch/w_expand_env). Without
      # this, winetricks silently constructs a nonexistent "wine64" path and
      # every `wine cmd.exe` call it makes to query the environment (e.g.
      # %AppData%) returns nothing, so it dies mid-activation before dxvk/
      # gdiplus get installed. A plain symlink is enough since the unified
      # binary already handles both architectures.
      wine64Shim = audiopkgs.runCommand "wine64-shim" { } ''
        mkdir -p "$out/bin"
        ln -s "${bitbridgeWine}/bin/wine" "$out/bin/wine64"
      '';

      # yabridge built from upstream git master instead of nixpkgs' package,
      # because nixpkgs' pkgs/by-name/ya/yabridge hardcodes
      # -Dbitbridge=false and patches libyabridge to drop 32-bit support
      # entirely. Modeled on that package.nix (as of nixpkgs-audio rev
      # c043004d1c) minus libyabridge-drop-32-bit-support.patch, with
      # bitbridge re-enabled and built against bitbridgeWine above.
      #
      # Pin: git master as of 2026-08-02 (commit b580a9f). This tracks an
      # unreleased commit, not a tagged release - bump deliberately, and
      # re-check that the reused nixpkgs patches (in
      # ./yabridge-git-master/) still apply when bumping.
      yabridgeGitMaster =
        let
          wine = bitbridgeWine;

          # Derived from subprojects/asio.wrap
          asio = audiopkgs.fetchFromGitHub {
            owner = "chriskohlhoff";
            repo = "asio";
            tag = "asio-1-28-2";
            hash = "sha256-8Sw0LuAqZFw+dxlsTstlwz5oaz3+ZnKBuvSdLW6/DKQ=";
          };

          # Derived from subprojects/bitsery.wrap
          bitsery = audiopkgs.fetchFromGitHub {
            owner = "fraillt";
            repo = "bitsery";
            tag = "v5.2.3";
            hash = "sha256-rmfcIYCrANycFuLtibQ5wOPwpMVhpTMpdGsUfpR3YsM=";
          };

          # Derived from subprojects/clap.wrap
          clap = audiopkgs.fetchFromGitHub {
            owner = "free-audio";
            repo = "clap";
            tag = "1.1.9";
            hash = "sha256-z2P0U2NkDK1/5oDV35jn/pTXCcspuM1y2RgZyYVVO3w=";
          };

          # Derived from subprojects/function2.wrap
          function2 = audiopkgs.fetchFromGitHub {
            owner = "Naios";
            repo = "function2";
            tag = "4.2.3";
            hash = "sha256-+fzntJn1fRifOgJhh5yiv+sWR9pyaeeEi2c1+lqX3X8=";
          };

          # Derived from subprojects/ghc_filesystem.wrap
          ghc_filesystem = audiopkgs.fetchFromGitHub {
            owner = "gulrak";
            repo = "filesystem";
            tag = "v1.5.14";
            hash = "sha256-XZ0IxyNIAs2tegktOGQevkLPbWHam/AOFT+M6wAWPFg=";
          };

          # Derived from subprojects/tomlplusplus.wrap
          tomlplusplus = audiopkgs.fetchFromGitHub {
            owner = "marzer";
            repo = "tomlplusplus";
            tag = "v3.4.0";
            hash = "sha256-h5tbO0Rv2tZezY58yUbyRVpsfRjY3i+5TPkkxr6La8M=";
          };

          # Derived from vst3.wrap
          vst3 = audiopkgs.fetchFromGitHub {
            owner = "robbert-vdh";
            repo = "vst3sdk";
            tag = "v3.7.7_build_19-patched";
            fetchSubmodules = true;
            hash = "sha256-LsPHPoAL21XOKmF1Wl/tvLJGzjaCLjaDAcUtDvXdXSU=";
          };
        in
        audiopkgs.multiStdenv.mkDerivation {
          pname = "yabridge";
          version = "git-b580a9f-2026-08-02";

          src = audiopkgs.fetchFromGitHub {
            owner = "robbert-vdh";
            repo = "yabridge";
            rev = "b580a9f7fc46509767ca156d4f92872552b9e571";
            hash = "sha256-TiKiyE3GZYCX1+vooHdD03fAhNQPAA1IzTfkG++I7TY=";
          };

          # Unpack subproject sources
          postUnpack = ''
            (
              cd "$sourceRoot/subprojects"
              cp -R --no-preserve=mode,ownership ${asio} asio
              cp -R --no-preserve=mode,ownership ${bitsery} bitsery
              cp -R --no-preserve=mode,ownership ${clap} clap
              cp -R --no-preserve=mode,ownership ${function2} function2
              cp -R --no-preserve=mode,ownership ${ghc_filesystem} ghc_filesystem
              cp -R --no-preserve=mode,ownership ${tomlplusplus} tomlplusplus
              cp -R --no-preserve=mode,ownership ${vst3} vst3
            )
          '';

          patches = [
            # Hard code bitbridge & runtime dependencies. Uses the older,
            # bitbridge-aware revision of this patch (from nixpkgs commit
            # 7d91ec6c, the last commit where nixpkgs still built bitbridge)
            # rather than the current one, which dropped the libxcb32
            # substitution once nixpkgs stopped building bitbridge.
            (audiopkgs.replaceVars ./yabridge-git-master/hardcode-dependencies.patch {
              libdbus = audiopkgs.dbus.lib;
              libxcb32 = audiopkgs.pkgsi686Linux.libxcb;
              inherit wine;
            })

            # Patch the chainloader to search for libyabridge through NIX_PROFILES
            ./yabridge-git-master/libyabridge-from-nix-profiles.patch
          ];

          postPatch = ''
            patchShebangs .
            (
              cd subprojects
              cp packagefiles/asio/* asio
              cp packagefiles/bitsery/* bitsery
              cp packagefiles/clap/* clap
              cp packagefiles/function2/* function2
              cp packagefiles/ghc_filesystem/* ghc_filesystem
            )
          '';

          nativeBuildInputs = [
            audiopkgs.meson
            audiopkgs.ninja
            audiopkgs.pkg-config
            wine
          ];

          buildInputs = [
            audiopkgs.libxcb
            audiopkgs.dbus
          ];

          mesonFlags = [
            "--cross-file"
            "cross-wine.conf"
            "-Dbitbridge=true"

            # Requires CMake and is unnecessary
            "-Dtomlplusplus:generate_cmake_config=false"
          ];

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin" "$out/lib"
            cp yabridge-host.exe{,.so} "$out/bin"
            cp yabridge-host-32.exe{,.so} "$out/bin"
            cp libyabridge{,-chainloader}-{vst2,vst3,clap}.so "$out/lib"
            runHook postInstall
          '';

          # Hard code wine path in wrapper scripts generated by winegcc
          postFixup = ''
            for exe in "$out"/bin/*.exe; do
              substituteInPlace "$exe" \
                --replace-fail 'WINELOADER="wine"' 'WINELOADER="${wine}/bin/wine"'
            done
          '';

          meta = {
            description = "Modern and transparent way to use Windows VST2 and VST3 plugins on Linux (git master, bitbridge re-enabled)";
            homepage = "https://github.com/robbert-vdh/yabridge";
            license = audiopkgs.lib.licenses.gpl3Plus;
            platforms = [ "x86_64-linux" ];
          };
        };

      yabridgectlGitMaster = audiopkgs.rustPlatform.buildRustPackage {
        pname = "yabridgectl";
        version = yabridgeGitMaster.version;

        src = yabridgeGitMaster.src;
        sourceRoot = "${yabridgeGitMaster.src.name}/tools/yabridgectl";

        # Matches nixpkgs' pinned cargoHash: tools/yabridgectl/Cargo.lock is
        # unchanged between the 5.1.1 tag and this git master pin. Re-check
        # (and let the build tell you the correct hash) when bumping the pin.
        cargoHash = "sha256-VcBQxKjjs9ESJrE4F1kxEp4ah3j9jiNPq/Kdz/qPvro=";

        patches = [
          # Patch yabridgectl to search for the chainloader through NIX_PROFILES
          ./yabridge-git-master/chainloader-from-nix-profiles.patch

          # Dependencies are hardcoded in yabridge, so the check is unnecessary and likely incorrect
          ./yabridge-git-master/remove-dependency-verification.patch
        ];

        patchFlags = [ "-p3" ];

        nativeBuildInputs = [ audiopkgs.makeWrapper ];

        postFixup = ''
          wrapProgram "$out/bin/yabridgectl" \
            --prefix PATH : ${audiopkgs.lib.makeBinPath [ yabridgeGitMaster ]}
        '';

        meta = {
          description = "Small, optional utility to help set up and update yabridge for several directories at once";
          homepage = "https://github.com/robbert-vdh/yabridge/tree/${yabridgeGitMaster.version}/tools/yabridgectl";
          license = audiopkgs.lib.licenses.gpl3Plus;
          platforms = yabridgeGitMaster.meta.platforms;
          mainProgram = "yabridgectl";
        };
      };

      # Wine and yabridge. yabridge/yabridgectl are built from upstream git
      # master (see yabridgeGitMaster/yabridgectlGitMaster above) rather than
      # nixpkgs' packages, to get 32-bit bitbridge support back on a current
      # Wine. Kept as its own list since homeModule below also needs just
      # these on REAPER's LD_LIBRARY_PATH (not the plugins below).
      winePkgs = [
        yabridgeGitMaster
        yabridgectlGitMaster
        bitbridgeWine
        wine64Shim
        audiopkgs.winetricks
      ];

      # Kept apart from each other (rather than one plain list) since
      # homeModule below wires each format into its own REAPER
      # preferences.plugIns.<format>.searchPaths.
      clapPlugins = with audiopkgs; [
        airwin2rack
        surge-xt
      ];

      lv2Plugins = with audiopkgs; [
        x42-plugins
        x42-avldrums
        magnetophonDSP.VoiceOfFaust
        magnetophonDSP.MBdistortion
        levelrider
        neural-amp-modeler-lv2
      ];

      vst3Plugins = with audiopkgs; [
        chow-phaser
      ];

      audioPkgs = winePkgs ++ clapPlugins ++ lv2Plugins ++ vst3Plugins;

      homeModule =
        {
          lib,
          pkgs,
          config,
          ...
        }:
        let
          # Upstream RaySession has a dead `from cgitb import text` import
          # (the imported name is never used) that only breaks once cgitb is
          # actually removed from the stdlib in Python 3.13+. Strip it so the
          # patchbay module imports cleanly.
          #
          # It also links against real libjack2, but there's no jack1/jack2
          # server here - only pipewire's JACK-compatible implementation. This
          # is what `pw-jack` does under the hood: put pipewire's libjack.so.0
          # ahead of the real one on LD_LIBRARY_PATH so ray-daemon picks it up
          # instead of failing to find a JACK server.
          raysessionFixed = pkgs.raysession.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              sed -i '/^from cgitb import text$/d' \
                src/gui/patchbay/patchcanvas/portgroup_widget.py
            '';
            makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
              "--prefix"
              "LD_LIBRARY_PATH"
              ":"
              "${pkgs.pipewire.jack}/lib"
            ];
          });

          # fetchurl's output is a store path, so its linked file name in
          # ColorThemes/ carries the store hash prefix - derive `active`
          # from the same path instead of hardcoding the plain file name,
          # so the two always agree.
          reaperTheme = pkgs.fetchurl {
            url = "https://stash.reaper.fm/30492/Default_5_Dark_Extended.ReaperThemeZip";
            sha256 = "0zbjnrxbd0pzjf1ll8m94ji06spxv9yhmjmc7l4pw9nwcdw5gl4z";
          };

          # Plain upstream nixpkgs xwayland-satellite and xwayland - no
          # custom pins, patches, or postFixup overrides. This setup used
          # to carry a pinned xwayland-satellite commit plus a local
          # subsurface-tracking patch, and later a separately-patched
          # "xwaylandTraced" Xwayland build with ErrorF instrumentation,
          # both aimed at what looked like a black-window bug in
          # DXVK/Vulkan-rendered wine VST GUIs (Xfer OTT and others). That
          # turned out to be a misdiagnosis: the actual cause was wine's
          # own incomplete Direct2D/DirectComposition implementation (see
          # refactor.md's 2026-09-10 updates and the switch to a
          # giang17/wine-based bitbridgeWine above), unrelated to Xwayland
          # or xwayland-satellite entirely. Both custom builds were
          # reverted back to plain upstream once that was confirmed - see
          # refactor.md for the full history and for the still-open
          # separate issue (a plugin popup-menu flicker/positioning bug)
          # this revert was done to get a clean baseline against.
          xwaylandSatellite = audiopkgs.xwayland-satellite;

          # Wraps the reaper-flake launcher (config.programs.reaper.package,
          # the one that already injects -cfgfile) in `unshare --net
          # --map-current-user`, the same manual invocation used before
          # this was made declarative - a fresh, interface-less network
          # namespace that every child process (wine, the yabridge host,
          # in-process VST/CLAP/LV2 plugins, ReaPack's own update checks)
          # inherits too, so nothing REAPER spawns can reach the network.
          # --map-current-user keeps this unprivileged (no setuid/
          # capabilities needed) and, unlike bwrap, plain `unshare -n`
          # doesn't touch the mount namespace, so X11/Wayland/PipeWire
          # sockets keep working with no extra bind-mounting.
          #
          # Pass `--net` as the first argument (e.g. `reaper --net`) to
          # skip the namespace and get a normal, internet-connected
          # REAPER for one run - useful for a ReaPack sync or similar.
          #
          # Also starts a private xwayland-satellite instance on a spare
          # X display and points only this REAPER invocation at it via
          # $DISPLAY (inherited by wine, the yabridge host and every
          # plugin GUI it spawns).
          # sway's own built-in XWayland has an unresolved override-redirect
          # popup positioning bug (ICCCM gives no reliable way to tell
          # a popup from a toplevel), which is what causes yabridge-hosted
          # Windows VST context/hover menus to render in the wrong place
          # or not show at all under sway. xwayland-satellite (see
          # xwaylandSatellite above) fixes this for most plugins
          # (github.com/Supreeeme/xwayland-satellite issue #293) - though
          # see refactor.md for an open exception (a specific plugin's
          # menu still flickers/mispositions). Running it as its own X
          # display here - rather than replacing sway's XWayland
          # session-wide - scopes the fix to REAPER's process tree only;
          # every other app keeps using sway's normal XWayland untouched.
          reaperNoNet = pkgs.symlinkJoin {
            name = "reaper-no-net";
            paths = [ config.programs.reaper.package ];
            postBuild = ''
              rm -f "$out/bin/reaper"
              cat > "$out/bin/reaper" <<'EOF'
              #!${pkgs.runtimeShell}

              find_free_display() {
                n=50
                while [ -S "/tmp/.X11-unix/X$n" ] || [ -e "/tmp/.X$n-lock" ]; do
                  n=$((n + 1))
                done
                echo "$n"
              }

              disp_num=$(find_free_display)
              # Verbose logging kept on for now while the popup-menu
              # flicker/positioning bug (see refactor.md) is still open;
              # xwayland-satellite runs plain upstream, no PATH override
              # needed.
              RUST_LOG=debug WAYLAND_DEBUG=1 ${lib.escapeShellArg "${xwaylandSatellite}/bin/xwayland-satellite"} ":$disp_num" -verbose 10 > "$HOME/.cache/xwayland-satellite-debug.log" 2>&1 &
              satellite_pid=$!
              trap 'kill "$satellite_pid" 2>/dev/null' EXIT

              i=0
              while [ ! -S "/tmp/.X11-unix/X$disp_num" ] && [ "$i" -lt 100 ]; do
                sleep 0.05
                i=$((i + 1))
              done

              export DISPLAY=":$disp_num"

              if [ "$1" = "--net" ]; then
                shift
                ${lib.escapeShellArg "${config.programs.reaper.package}/bin/reaper"} "$@"
                exit $?
              fi
              ${lib.escapeShellArg "${pkgs.util-linux}/bin/unshare"} --net --map-current-user -- ${lib.escapeShellArg "${config.programs.reaper.package}/bin/reaper"} "$@"
              EOF
              chmod +x "$out/bin/reaper"
            '';
            meta = config.programs.reaper.package.meta or { };
          };
        in
        {
          home.packages = [
            pkgs.pipewire.jack
            raysessionFixed
            pkgs.qjackctl
            pkgs.fluidsynth
            reaperNoNet
            # Also used internally by reaperNoNet above; kept on PATH too
            # so it can be run/inspected by hand (RUST_LOG=debug
            # xwayland-satellite :N) when debugging the wrapper.
            xwaylandSatellite
          ]
          ++ audioPkgs;

          # Manages ~/.config/REAPER declaratively (theme, ReaPack, plugin
          # search paths). Plugin store paths (clapPlugins/lv2Plugins/
          # vst3Plugins, defined above) come from the nixpkgs-audio
          # channel, same as the wine/yabridge packages folded into
          # home.packages above - REAPER, its plugins, and the wine bridge
          # are all always installed, no separate dev shell needed.
          programs.reaper = {
            enable = true;
            configPath = "/home/${config.home.username}/.config/REAPER";

            # Installed separately as reaperNoNet above (network-namespaced);
            # this default, unsandboxed package must stay off PATH or the
            # two would collide over bin/reaper.
            installPackage = false;

            # Adds wine/yabridge libraries to REAPER's LD_LIBRARY_PATH,
            # inherited by every process it spawns, including the yabridge
            # wine host. GUI plugin rendering (mesa/vulkan) comes from the
            # system's own drivers instead of a nixpkgs-audio copy - see
            # targets.genericLinux.enable below. pipewire.jack goes first
            # so its libjack.so.0 (pipewire's JACK-compatible
            # implementation) is found ahead of any real libjack2 - there's
            # no jack1/jack2 server here, only pipewire's - same fix as
            # raysessionFixed below, but done here via LD_LIBRARY_PATH
            # order since REAPER isn't wrapped with pw-jack itself.
            packages = [ pkgs.pipewire.jack ] ++ winePkgs;

            extensions.reapack.enable = true;

            theme = {
              active = builtins.baseNameOf "${reaperTheme}";
              colorThemes = [ reaperTheme ];
            };

            preferences.plugIns = {
              vst.searchPaths = map (p: "${p}/lib/vst3") vst3Plugins;
              clap.searchPaths = map (p: "${p}/lib/clap") clapPlugins;
              lv2.searchPaths = map (p: "${p}/lib/lv2") lv2Plugins;
            };
          };

          # Sets up the Windows-plugin wine prefix that yabridge bridges
          # into REAPER's VST/VST3/CLAP paths above: a DXVK/GDI+ prefix,
          # win-plugins symlinked in from ~/Shared/Audio, and a yabridgectl
          # sync so newly (un)installed Windows plugins pick up chainloader
          # .so files. Runs on every `home-manager switch` instead of every
          # `nix develop`, so REAPER works standalone.
          home.activation.audioWinePrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] (
            let
              wineBinPath = audiopkgs.lib.makeBinPath (winePkgs ++ [ bitbridgeWine ]);
              winPlugins = "/home/${config.home.username}/Shared/Audio/win-plugins";
            in
            # bash
            ''
              export WINEPREFIX=${audiopkgs.lib.escapeShellArg "/home/${config.home.username}/.wine-audio"}
              export PATH=${audiopkgs.lib.escapeShellArg wineBinPath}:$PATH

              # home.sessionVariables.NIX_PROFILES only takes effect in a
              # fresh login shell, not in the shell that invoked this
              # activation script, so yabridgectl (used below) can't find
              # its own libyabridge-chainloader-*.so without this too.
              export NIX_PROFILES=${audiopkgs.lib.escapeShellArg yabridgeGitMaster}" $NIX_PROFILES"

              # Needed for Guitar Pro 5 (gdiplus). DXVK is deliberately not
              # installed here - giang17's Direct2D/DirectComposition wine
              # fork (see bitbridgeWine above) explicitly says not to: DXVK
              # replaces dxgi.dll/d3d11.dll and bypasses the composition-
              # swapchain path the fork is built on.
              if [ ! -d "$WINEPREFIX" ]; then
                winetricks -q gdiplus
              fi

              winplugins=${audiopkgs.lib.escapeShellArg winPlugins}

              link_into_prefix() {
                target=$1
                source=$2
                rm -rf "$target"
                ln -s "$source" "$target"
              }

              link_into_prefix "$WINEPREFIX/drive_c/users/${config.home.username}/win-plugins" "$winplugins"

              if [ -d "$winplugins/AppData" ]; then
                link_into_prefix "$WINEPREFIX/drive_c/users/${config.home.username}/AppData" "$winplugins/AppData"
              fi

              if [ -d "$winplugins/Documents" ]; then
                link_into_prefix "$WINEPREFIX/drive_c/users/${config.home.username}/Documents" "$winplugins/Documents"
              fi

              if [ -d "$winplugins/ProgramData" ]; then
                ln -sf "$winplugins"/ProgramData/* "$WINEPREFIX"/drive_c/ProgramData/
              fi

              if [ -d "$winplugins/Program Files" ]; then
                ln -sf "$winplugins"/Program\ Files/* "$WINEPREFIX"/drive_c/Program\ Files/
              fi

              if [ -d "$winplugins/Program Files (x86)" ]; then
                ln -sf "$winplugins"/Program\ Files\ \(x86\)/* "$WINEPREFIX"/drive_c/Program\ Files\ \(x86\)/
              fi

              if [ -d "$winplugins/windows/Fonts" ]; then
                ln -sf "$winplugins"/windows/Fonts/* "$WINEPREFIX"/drive_c/windows/Fonts/
              fi

              if [ -f "$winplugins/custom.reg" ]; then
                wine regedit "$winplugins/custom.reg"
              fi

              link_into_prefix "/home/${config.home.username}/.vst3" "/home/${config.home.username}/Shared/Audio/vst3"

              if [ -d "$winplugins/Plugins" ]; then
                yabridgectl sync --force --prune --verbose
                yabridgectl status
              fi
            ''
          );

          home.sessionVariables = {
            WINEPREFIX = "/home/${config.home.username}/.wine-audio";

            # nix.sh (sourced earlier in ~/.bashrc) unconditionally
            # overwrites NIX_PROFILES, dropping any prior value. Home
            # Manager sources this file's generated hm-session-vars.sh
            # right after nix.sh, so re-asserting the yabridge entry here
            # re-adds it every shell without fighting nix.sh for order.
            # Without it, yabridge's chainloader .so files can't find
            # libyabridge-{vst2,vst3}.so at runtime and every bridged
            # plugin fails to load in REAPER.
            NIX_PROFILES = "${yabridgeGitMaster} $NIX_PROFILES";
          };

          home.file.".config/yabridgectl/config.toml".source =
            (pkgs.formats.toml { }).generate "yabridgectl-config.toml"
              {
                plugin_dirs = [ "/home/${config.home.username}/Shared/Audio/win-plugins/Plugins" ];
                vst2_location = "centralized";
                no_verify = false;
                blacklist = [ ];
              };

          # yabridge searches for this file starting in the plugin's own
          # directory and walking up parents, so placing it at the root of
          # win-plugins/Plugins applies it to every bridged plugin.
          home.file."Shared/Audio/win-plugins/Plugins/yabridge.toml".text = ''
            # =====================================================================
            # GLOBAL CONFIGURATION (Applies to all plugins)
            # =====================================================================
            ["*"]
            # Force the plugin UI to open as a free-floating, detached desktop window.
            # Options are: "embedded" (default Xembed) or "detached"
            editor_type = "detached"
          '';

          home.file."Shared/Audio/win-plugins/custom.reg".text = ''
            Windows Registry Editor Version 5.00

            [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
            "Guitar Pro 5 (TrueType)"="Guitar Pro 5.ttf"

            [HKEY_LOCAL_MACHINE\Software\Wow6432Node\Arobas Music\Guitar Pro 5]
            "InstallFolder"="C:\\Program Files (x86)\\Guitar Pro 5"
          '';

          home.file."Shared/Audio/win-plugins/AppData/Roaming/Ugritone/Ampenstein/config.xml".text = ''
            <?xml version="1.0" encoding="UTF-8"?>

            <root pluginDataPath="C:\users\${config.home.username}\win-plugins\Plugins\Ugritone\Ampenstein\Processors"
                  IRPath="C:\users\${config.home.username}\win-plugins\Plugins\Ugritone\Ampenstein\Impulse Responses"
                  flipChannels="0" temporarySaveAmpStatesForEachSlot="1" UserPresetsPath="C:\users\${config.home.username}\win-plugins\Plugins\Ugritone\Ampenstein\User Presets"
                  BGImagePath=""/>
          '';

          home.file."Shared/Audio/win-plugins/AppData/Roaming/Ugritone/VerbCore/config.cfg".text = # xml
            ''
              <?xml version="1.0" encoding="UTF-8"?>

              <root userDataPath="C:\users\${config.home.username}\win-plugins\Plugins\Ugritone\VerbCore"/>
            '';
        };

      # Roots for closurePositions below, hand-curated since these packages
      # are just plain list entries rather than a derivable module output
      # (unlike the main flake's nixpkgs-home set, which is derived from
      # home-manager's own merged package list).
      packageSets.nixpkgs = audioPkgs;

      # For packageSets.nixpkgs, the meta.position of every package plus its
      # full transitive build closure, deduplicated by drvPath. Used by
      # flake-update's per-file diff review.
      closurePositions = builtins.mapAttrs (
        _: pkgs:
        let
          startSet = builtins.filter (p: builtins.isAttrs p && p ? drvPath) (audiopkgs.lib.flatten pkgs);
          closure = builtins.genericClosure {
            startSet = map (p: {
              key = p.drvPath;
              val = p;
            }) startSet;
            operator =
              { val, ... }:
              map
                (d: {
                  key = d.drvPath;
                  val = d;
                })
                (
                  builtins.filter (d: builtins.isAttrs d && d ? drvPath) (
                    audiopkgs.lib.flatten (
                      (val.buildInputs or [ ])
                      ++ (val.nativeBuildInputs or [ ])
                      ++ (val.propagatedBuildInputs or [ ])
                      ++ (val.propagatedNativeBuildInputs or [ ])
                    )
                  )
                );
          };
        in
        audiopkgs.lib.unique (
          builtins.filter (x: x != null) (map ({ val, ... }: val.meta.position or null) closure)
        )
      ) packageSets;
    in
    {
      inherit packageSets closurePositions;

      formatter.${system} = audiopkgs.nixfmt;

      homeModules.audio = homeModule;

      packages.${system} = {
        inherit audioPkgs bitbridgeWine;

        # Not otherwise a single buildable output - exists so `flake-update`
        # (run from this directory) has something to build and
        # diff-closures against, the same role
        # homeConfigurations.<user>.activationPackage plays in the main
        # flake.
        default = audiopkgs.symlinkJoin {
          name = "audio";
          paths = audioPkgs;
        };
      };
    };
}
