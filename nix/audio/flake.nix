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
      # (https://github.com/giang17/wine, branch d2d1-dcomp-11.17), used for
      # the "experimental" prefix (sway/TTY1/Wayland). See stableWine below
      # (nixpkgs' own wineRelease = "yabridge") for a more conservative
      # alternative, used on TTY2/openbox.
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
        rev = "3cd55010bef6328b9d789d9662b42e4226ff64b1"; # d2d1-dcomp-11.17 branch HEAD, 2026-09-11
        hash = "sha256-Mi5/XSmwEx34X8cQb2tJZ4woTzDGa8xQqO6cl5GUCeY=";
      };

      # wineWow (classic 32+64-bit split build, as opposed to the merged
      # WoW64 build nixpkgs exposes by default) - yabridge's bitbridge
      # (32-bit host support) only compiles against the classic split, see
      # yabridge upstream issue #435 for the WoW64 incompatibility - so
      # this is what mkYabridge below is built against, for both prefixes.
      #
      # Isolation test (2026-09-11): temporarily reverted this to stock
      # nixpkgs wine-staging to check whether giang17's fork itself causes
      # the intermittent virtual_setup_exception stack-overflow crashes seen
      # on PTE-qX and Ozone 9's GUI-open/project-load (even at a bumped 32
      # MiB yabridge-host stack reserve - see the postPatch comment in
      # mkYabridge below - crashes still recurred, just took longer,
      # pointing at runaway/unbounded recursion rather than a fixed depth).
      # Result: confirmed - stock wine-staging never crashed, but Ozone
      # 9/PTE-X went back to rendering black (the original bug the fork
      # fixes). Diffing the fork against vanilla wine-11.16 showed its
      # ntdll/exception/thread-stack code is untouched (only an unrelated
      # one-line MADV_FREE tweak in virtual.c); the actual diff is 173 files
      # of real Direct2D/DirectComposition/d3d11/dxgi/dwrite implementation
      # replacing what's mostly stubs in stock Wine, which is almost
      # certainly where the runaway stack usage lives - not something
      # feasibly bisectable here. Switched back to the fork (this pick):
      # correct GUIs for Direct2D-dependent plugins, at the cost of the
      # intermittent crash/freeze risk until this is fixed upstream in
      # giang17/wine (actively maintained - worth filing an issue there).
      # This crash risk is the main reason stableWine below exists as a
      # fallback: same yabridge/REAPER setup, ordinary wine.
      #
      # NTsync note: no patch needed for it at all - wine 11.16 already has
      # native ntsync support behind HAVE_LINUX_NTSYNC_H (confirmed present
      # in dlls/ntdll/unix/sync.c), and nixpkgs' kernel headers (6.18.7+, a
      # requirement for the header to exist) already satisfy that check, so
      # it's compiled in automatically and used at runtime if the kernel
      # exposes /dev/ntsync.
      #
      # wine-staging tried and reverted (2026-09-11): attempted layering
      # nixpkgs' useStaging (wineRelease = "staging", which runs the real
      # staging/patchinstall.py --all against whatever `src` is unpacked -
      # here, wineD2DSrc) on top of giang17's fork instead of stock 11.16,
      # to get staging's patchset alongside Direct2D + NTsync. Failed
      # immediately: the second staging patch already conflicts
      # (`Staging/0002-winelib-Append-Staging-at-the-end-of-the-version-s.patch`
      # fails against configure.ac). giang17's fork and wine-staging are two
      # independently-diverged trees, and wine-staging's patches apply
      # sequentially with hardcoded context - any file both trees touch
      # (giang17's own PATCHES.md lists winex11.drv as touched, a common
      # staging target too) is a likely conflict. Bulk-applying "all of
      # staging" isn't viable without a large, fragile, hand-tuned exclusion
      # list that would need re-tuning on every giang17 rebase or staging
      # update - not attempted further.
      experimentalWine =
        (audiopkgs.wine.override {
          wineBuild = "wineWow";
          # nixpkgs' own "unstable" version (currently 11.16) doesn't need to
          # match wineD2DSrc's base (11.17) - src is fully overridden below
          # and patches = [ ] drops nixpkgs' small unstable-channel patches,
          # so this only selects the unstable build recipe/metadata shape.
          wineRelease = "unstable";
        }).overrideAttrs
          (old: {
            version = "11.17-d2d1-dcomp";
            src = wineD2DSrc;
            patches = [ ];
          });

      # "Stable" wine (used on TTY2/openbox/Xorg): nixpkgs' own
      # wineRelease = "yabridge" source - wine 9.21 + wine-staging, an old
      # enough, ordinary (non-forked) wine that nixpkgs itself curates
      # specifically for building yabridge's bitbridge on a modern
      # toolchain (see pkgs/applications/emulators/wine/sources.nix and
      # default.nix upstream - already hashed/maintained there, no manual
      # fetchurl/hash-pinning needed here). No black-window Direct2D fix
      # and no DirectComposition support (unlike experimentalWine above),
      # but none of its intermittent stack-overflow crash risk either -
      # this is the fallback for when that instability, or sway's
      # popup-menu bug (see refactor.md), gets in the way. Note this pulls
      # in wine-staging, not literally vanilla wine - that's nixpkgs' own
      # curated pairing for bitbridge, still materially more conservative
      # than the giang17 fork above.
      stableWine = audiopkgs.wine.override {
        wineBuild = "wineWow"; # classic 32+64 split, same reasoning as experimentalWine
        wineRelease = "yabridge";
      };

      # Modern Wine merged the separate wine/wine64 loader binaries into a
      # single arch-detecting `wine` binary, but winetricks (as packaged in
      # nixpkgs-audio) still expects a `wine64` binary to exist for 64-bit
      # WINEPREFIX setup (see winetricks_early_wine_arch/w_expand_env). Without
      # this, winetricks silently constructs a nonexistent "wine64" path and
      # every `wine cmd.exe` call it makes to query the environment (e.g.
      # %AppData%) returns nothing, so it dies mid-activation before dxvk/
      # gdiplus get installed. A plain symlink is enough since the unified
      # binary already handles both architectures.
      mkWine64Shim =
        wine:
        audiopkgs.runCommand "wine64-shim" { } ''
          mkdir -p "$out/bin"
          ln -s "${wine}/bin/wine" "$out/bin/wine64"
        '';

      wine64ShimExperimental = mkWine64Shim experimentalWine;
      wine64ShimStable = mkWine64Shim stableWine;

      # yabridge built from upstream git master instead of nixpkgs' package,
      # because nixpkgs' pkgs/by-name/ya/yabridge hardcodes
      # -Dbitbridge=false and patches libyabridge to drop 32-bit support
      # entirely. Modeled on that package.nix (as of nixpkgs-audio rev
      # c043004d1c) minus libyabridge-drop-32-bit-support.patch, with
      # bitbridge re-enabled. Parameterized over `wine` (mkYabridge below)
      # so it can be built against either experimentalWine or stableWine -
      # the only wine-specific parts are the `wine` binding itself (used in
      # nativeBuildInputs, the hardcode-dependencies patch, and postFixup's
      # WINELOADER substitution) and pname/version metadata; everything
      # else (subproject sources/patches, mesonFlags, installPhase) is
      # wine-independent and fetched/defined once, shared below.
      #
      # Pin: git master as of 2026-08-02 (commit b580a9f). This tracks an
      # unreleased commit, not a tagged release - bump deliberately, and
      # re-check that the reused nixpkgs patches (in
      # ./yabridge-git-master/) still apply when bumping.
      yabridgeSrc = audiopkgs.fetchFromGitHub {
        owner = "robbert-vdh";
        repo = "yabridge";
        rev = "b580a9f7fc46509767ca156d4f92872552b9e571";
        hash = "sha256-TiKiyE3GZYCX1+vooHdD03fAhNQPAA1IzTfkG++I7TY=";
      };

      # Derived from subprojects/asio.wrap
      yabridgeSubprojectAsio = audiopkgs.fetchFromGitHub {
        owner = "chriskohlhoff";
        repo = "asio";
        tag = "asio-1-28-2";
        hash = "sha256-8Sw0LuAqZFw+dxlsTstlwz5oaz3+ZnKBuvSdLW6/DKQ=";
      };

      # Derived from subprojects/bitsery.wrap
      yabridgeSubprojectBitsery = audiopkgs.fetchFromGitHub {
        owner = "fraillt";
        repo = "bitsery";
        tag = "v5.2.3";
        hash = "sha256-rmfcIYCrANycFuLtibQ5wOPwpMVhpTMpdGsUfpR3YsM=";
      };

      # Derived from subprojects/clap.wrap
      yabridgeSubprojectClap = audiopkgs.fetchFromGitHub {
        owner = "free-audio";
        repo = "clap";
        tag = "1.1.9";
        hash = "sha256-z2P0U2NkDK1/5oDV35jn/pTXCcspuM1y2RgZyYVVO3w=";
      };

      # Derived from subprojects/function2.wrap
      yabridgeSubprojectFunction2 = audiopkgs.fetchFromGitHub {
        owner = "Naios";
        repo = "function2";
        tag = "4.2.3";
        hash = "sha256-+fzntJn1fRifOgJhh5yiv+sWR9pyaeeEi2c1+lqX3X8=";
      };

      # Derived from subprojects/ghc_filesystem.wrap
      yabridgeSubprojectGhcFilesystem = audiopkgs.fetchFromGitHub {
        owner = "gulrak";
        repo = "filesystem";
        tag = "v1.5.14";
        hash = "sha256-XZ0IxyNIAs2tegktOGQevkLPbWHam/AOFT+M6wAWPFg=";
      };

      # Derived from subprojects/tomlplusplus.wrap
      yabridgeSubprojectTomlplusplus = audiopkgs.fetchFromGitHub {
        owner = "marzer";
        repo = "tomlplusplus";
        tag = "v3.4.0";
        hash = "sha256-h5tbO0Rv2tZezY58yUbyRVpsfRjY3i+5TPkkxr6La8M=";
      };

      # Derived from vst3.wrap
      yabridgeSubprojectVst3 = audiopkgs.fetchFromGitHub {
        owner = "robbert-vdh";
        repo = "vst3sdk";
        tag = "v3.7.7_build_19-patched";
        fetchSubmodules = true;
        hash = "sha256-LsPHPoAL21XOKmF1Wl/tvLJGzjaCLjaDAcUtDvXdXSU=";
      };

      mkYabridge =
        {
          wine,
          pname,
          version,
        }:
        audiopkgs.multiStdenv.mkDerivation {
          inherit pname version;

          src = yabridgeSrc;

          # Unpack subproject sources
          postUnpack = ''
            (
              cd "$sourceRoot/subprojects"
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectAsio} asio
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectBitsery} bitsery
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectClap} clap
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectFunction2} function2
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectGhcFilesystem} ghc_filesystem
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectTomlplusplus} tomlplusplus
              cp -R --no-preserve=mode,ownership ${yabridgeSubprojectVst3} vst3
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

      yabridgeExperimental = mkYabridge {
        wine = experimentalWine;
        pname = "yabridge-experimental";
        version = "11.17-d2d1-dcomp+git-b580a9f";
      };

      yabridgeStable = mkYabridge {
        wine = stableWine;
        pname = "yabridge-stable";
        version = "9.21-yabridge+git-b580a9f";
      };

      # yabridgectl's sources don't depend on which wine it'll be paired
      # with - only the wrapped `yabridge` bin dir baked into postFixup's
      # PATH differs between the two instantiations below.
      mkYabridgectl =
        { yabridge, pname }:
        audiopkgs.rustPlatform.buildRustPackage {
          inherit pname;
          version = yabridge.version;

          src = yabridgeSrc;
          sourceRoot = "${yabridgeSrc.name}/tools/yabridgectl";

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
              --prefix PATH : ${audiopkgs.lib.makeBinPath [ yabridge ]}
          '';

          meta = {
            description = "Small, optional utility to help set up and update yabridge for several directories at once";
            homepage = "https://github.com/robbert-vdh/yabridge/tree/${yabridge.version}/tools/yabridgectl";
            license = audiopkgs.lib.licenses.gpl3Plus;
            platforms = yabridge.meta.platforms;
            mainProgram = "yabridgectl";
          };
        };

      yabridgectlExperimental = mkYabridgectl {
        yabridge = yabridgeExperimental;
        pname = "yabridgectl-experimental";
      };

      yabridgectlStable = mkYabridgectl {
        yabridge = yabridgeStable;
        pname = "yabridgectl-stable";
      };

      # Wine and yabridge for each prefix. Kept as separate lists (rather
      # than one combined one) since homeModule below needs just one
      # prefix's worth on REAPER's LD_LIBRARY_PATH/PATH per launch - each
      # reaper-<name> binary uses only its own (see mkReaperScript/
      # home.activation in homeModule).
      winePkgsExperimental = [
        yabridgeExperimental
        yabridgectlExperimental
        experimentalWine
        wine64ShimExperimental
        audiopkgs.winetricks
      ];

      winePkgsStable = [
        yabridgeStable
        yabridgectlStable
        stableWine
        wine64ShimStable
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

      # Flat list of everything wine/yabridge/plugin-related, for
      # packages.${system} (build-sanity/CI use only - NOT fed into
      # home.packages, see homeModule below for why).
      audioPkgs = winePkgsStable ++ winePkgsExperimental ++ clapPlugins ++ lv2Plugins ++ vst3Plugins;

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
          # giang17/wine-based experimentalWine above), unrelated to
          # Xwayland or xwayland-satellite entirely. Both custom builds
          # were reverted back to plain upstream once that was confirmed -
          # see refactor.md for the full history and for the still-open
          # separate issue (a plugin popup-menu flicker/positioning bug,
          # xwayland-satellite has no X11 popup-grab handling at all) that
          # this revert was done to get a clean baseline against, and that
          # stableWine/TTY2-openbox above/below exist to route around
          # entirely (real X11, no Wayland bridging at all).
          xwaylandSatellite = audiopkgs.xwayland-satellite;

          # Builds one prefix's `reaper-<name>` launch script (invoked twice
          # below, once per prefix - see reaperLaunchers). Both wine builds'
          # yabridge chainloaders write into the same shared ~/.vst3 (see
          # mkPrefixActivationBody below), so each script re-syncs its own
          # prefix's chainloaders right before launching REAPER - this makes
          # either binary correct to run at any time, regardless of which
          # prefix was last synced during `home-manager switch` or launched
          # via the other binary, with no env var or manual step needed.
          #
          # Wraps config.programs.reaper.basePackage (the raw, unwrapped
          # REAPER install) directly rather than config.programs.reaper.package
          # (reaper-flake's own -cfgfile/LD_LIBRARY_PATH wrapper, built from
          # a single static `packages` list) since LD_LIBRARY_PATH needs to
          # vary between the two prefixes - the -cfgfile injection below
          # replicates what that wrapper does.
          #
          # Also runs REAPER inside `unshare --net --map-current-user`, a
          # fresh, interface-less network namespace that every child
          # process (wine, the yabridge host, in-process VST/CLAP/LV2
          # plugins, ReaPack's own update checks) inherits too, so nothing
          # REAPER spawns can reach the network. --map-current-user keeps
          # this unprivileged (no setuid/capabilities needed) and, unlike
          # bwrap, plain `unshare -n` doesn't touch the mount namespace, so
          # X11/Wayland/PipeWire sockets keep working with no extra
          # bind-mounting. Pass `--net` as the first argument (e.g.
          # `reaper-stable --net`) to skip the namespace and get a normal,
          # internet-connected REAPER for one run - useful for a ReaPack
          # sync or similar.
          #
          # `xwaylandSatellite = null` (the stable/openbox default) skips
          # spawning a private xwayland-satellite instance entirely - the
          # TTY2 Xorg session already has a real $DISPLAY. Passing it (the
          # experimental/sway launcher below) spawns one on a spare X
          # display and points $DISPLAY at it for this REAPER process tree
          # only, exactly as before. Set DEBUG=1 to turn on rust/wayland
          # debug logging for the satellite process.
          mkReaperScript =
            {
              winePrefixDir,
              winePkgs,
              yabridge,
              wine,
              xwaylandSatellite ? null,
            }:
            ''
              #!${pkgs.runtimeShell}

              ${lib.optionalString (xwaylandSatellite != null) ''
                find_free_display() {
                  n=50
                  while [ -S "/tmp/.X11-unix/X$n" ] || [ -e "/tmp/.X$n-lock" ]; do
                    n=$((n + 1))
                  done
                  echo "$n"
                }
              ''}

              # On exit: kill this invocation's own xwayland-satellite (if
              # any) and the Xwayland it spawned, then wineserver -k to tear
              # down the yabridge wine host and any wine-hosted plugins left
              # running - REAPER's own exit doesn't always reap those.
              cleanup() {
                ${lib.optionalString (xwaylandSatellite != null) ''
                  if [ -n "''${satellite_pid:-}" ]; then
                    xwayland_pid=$(${lib.escapeShellArg "${pkgs.procps}/bin/pgrep"} -P "$satellite_pid" -x Xwayland 2>/dev/null)
                    kill "$satellite_pid" 2>/dev/null
                    [ -n "$xwayland_pid" ] && kill "$xwayland_pid" 2>/dev/null
                  fi
                ''}
                ${lib.escapeShellArg "${wine}/bin/wineserver"} -k 2>/dev/null
              }
              trap cleanup EXIT

              export WINEPREFIX=${lib.escapeShellArg winePrefixDir}
              export PATH=${lib.escapeShellArg (audiopkgs.lib.makeBinPath winePkgs)}:$PATH
              export NIX_PROFILES=${lib.escapeShellArg "${yabridge}"}" $NIX_PROFILES"
              export LD_LIBRARY_PATH=${
                lib.escapeShellArg (audiopkgs.lib.makeLibraryPath ([ pkgs.pipewire.jack ] ++ winePkgs))
              }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

              # Re-sync this prefix's yabridge chainloaders into the shared
              # ~/.vst3 right before launching - see comment above.
              yabridgectl sync --force --prune --verbose
              yabridgectl status

              ${lib.optionalString (xwaylandSatellite != null) ''
                disp_num=$(find_free_display)
                if [ "$DEBUG" = "1" ]; then
                  RUST_LOG=debug WAYLAND_DEBUG=1 ${lib.escapeShellArg "${xwaylandSatellite}/bin/xwayland-satellite"} ":$disp_num" -verbose 10 \
                    > "$HOME/.cache/xwayland-satellite-debug.log" 2>&1 &
                else
                  ${lib.escapeShellArg "${xwaylandSatellite}/bin/xwayland-satellite"} ":$disp_num" &
                fi
                satellite_pid=$!

                i=0
                while [ ! -S "/tmp/.X11-unix/X$disp_num" ] && [ "$i" -lt 100 ]; do
                  sleep 0.05
                  i=$((i + 1))
                done

                export DISPLAY=":$disp_num"
              ''}

              reaper_bin=${lib.escapeShellArg "${config.programs.reaper.basePackage}/bin/reaper"}
              cfgfile=${lib.escapeShellArg "${config.programs.reaper.configPath}/reaper.ini"}

              net=0
              if [ "''${1:-}" = "--net" ]; then
                net=1
                shift
              fi

              # Replicates reaper-flake's own -cfgfile injection
              # (modules/default.nix, homeWrappedReaperPackage) since
              # basePackage is called directly here, bypassing that wrapper.
              has_cfgfile=0
              for arg in "$@"; do
                case "$arg" in
                  -cfgfile | --cfgfile | -cfgfile=* | --cfgfile=*)
                    has_cfgfile=1
                    ;;
                esac
              done
              if [ "$has_cfgfile" -eq 0 ]; then
                set -- -cfgfile "$cfgfile" "$@"
              fi

              if [ "$net" -eq 1 ]; then
                exec "$reaper_bin" "$@"
              fi
              exec ${lib.escapeShellArg "${pkgs.util-linux}/bin/unshare"} --net --map-current-user -- "$reaper_bin" "$@"
            '';

          # Two REAPER launch binaries, reaper-stable and reaper-experimental,
          # each hardcoded to its own prefix - no env var, no ambiguity about
          # which backend a given invocation uses.
          reaperLaunchers = pkgs.symlinkJoin {
            name = "reaper-launchers";
            paths = [ config.programs.reaper.basePackage ];
            postBuild = ''
              rm -f "$out/bin/reaper"

              cat > "$out/bin/reaper-stable" <<'EOF'
              ${mkReaperScript {
                winePrefixDir = "/home/${config.home.username}/.wine-stable";
                winePkgs = winePkgsStable;
                yabridge = yabridgeStable;
                wine = stableWine;
              }}
              EOF
              chmod +x "$out/bin/reaper-stable"

              cat > "$out/bin/reaper-experimental" <<'EOF'
              ${mkReaperScript {
                winePrefixDir = "/home/${config.home.username}/.wine-experimental";
                winePkgs = winePkgsExperimental;
                yabridge = yabridgeExperimental;
                wine = experimentalWine;
                xwaylandSatellite = xwaylandSatellite;
              }}
              EOF
              chmod +x "$out/bin/reaper-experimental"
            '';
            meta = config.programs.reaper.basePackage.meta or { };
          };

          # Shared body for both home.activation.audioWinePrefix* blocks
          # below: symlinks win-plugins/AppData/Documents/ProgramData/
          # Program Files/Program Files (x86)/Fonts from ~/Shared/Audio/
          # win-plugins into $WINEPREFIX, applies custom.reg, and symlinks
          # ~/.vst3 (the shared discovery path both prefixes' yabridge
          # chainloaders write into). Deliberately does NOT run yabridgectl
          # sync itself - each reaper-<name> launcher (see mkReaperScript
          # above) does its own sync right before launching instead, so
          # both prefixes can be fully activated on every `home-manager
          # switch` without one's chainloaders clobbering the other's.
          mkPrefixActivationBody = winePrefixDir: ''
            export WINEPREFIX=${audiopkgs.lib.escapeShellArg winePrefixDir}

            winplugins=${audiopkgs.lib.escapeShellArg "/home/${config.home.username}/Shared/Audio/win-plugins"}

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
          '';
        in
        {
          home.packages = [
            pkgs.pipewire.jack
            raysessionFixed
            pkgs.qjackctl
            pkgs.fluidsynth
            # The one thing from this whole setup that should be on PATH -
            # everything wine/yabridge-specific stays scoped inside each
            # reaper-<name> script and the home.activation blocks below,
            # never exported globally, so the two wine builds' binaries
            # (wine, wineserver, yabridge-host*.exe, ...) can't clash with
            # each other on PATH/NIX_PROFILES.
            reaperLaunchers
            # Also used internally by reaper-experimental (see
            # mkReaperScript above); kept on PATH too so it can be
            # run/inspected by hand when debugging the wrapper.
            xwaylandSatellite
          ]
          ++ clapPlugins
          ++ lv2Plugins
          ++ vst3Plugins;

          # Manages ~/.config/REAPER declaratively (theme, ReaPack, plugin
          # search paths) - shared by both prefixes, since it's the same
          # REAPER app/session either way; only the wine backend for
          # bridged Windows plugins differs per launch (see mkReaperScript
          # above). Plugin store paths (clapPlugins/lv2Plugins/vst3Plugins,
          # defined above) come from the nixpkgs-audio channel, same as the
          # wine/yabridge packages built above - REAPER, its plugins, and
          # the wine bridge are all always installed, no separate dev
          # shell needed.
          programs.reaper = {
            enable = true;
            configPath = "/home/${config.home.username}/.config/REAPER";

            # Installed separately as reaperLaunchers above (network-
            # namespaced, one binary per wine backend); this default,
            # unwrapped package must stay off PATH or it would collide
            # with reaper-stable/reaper-experimental's own bin/reaper*.
            installPackage = false;

            # wine/yabridge LD_LIBRARY_PATH is injected per-launch by each
            # reaper-<name> script above instead (it varies between the
            # stable and experimental prefixes, so a single static list
            # here can't express it) - pipewire.jack is the only real,
            # prefix-independent entry left.
            packages = [ pkgs.pipewire.jack ];

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

          xdg.desktopEntries."reaper-stable" = {
            name = "REAPER (Stable)";
            genericName = "Digital Audio Workstation";
            exec = "reaper-stable";
            icon = "reaper";
            terminal = false;
            categories = [
              "Audio"
              "AudioVideo"
              "Music"
            ];
          };

          xdg.desktopEntries."reaper-experimental" = {
            name = "REAPER (Experimental)";
            genericName = "Digital Audio Workstation";
            exec = "reaper-experimental";
            icon = "reaper";
            terminal = false;
            categories = [
              "Audio"
              "AudioVideo"
              "Music"
            ];
          };

          # Sets up the Windows-plugin wine prefixes that yabridge bridges
          # into REAPER's VST/VST3/CLAP paths above. Both blocks always run
          # on every `home-manager switch` (unconditionally, unlike an
          # earlier revision that gated this by an env var) - the shared
          # ~/.vst3 no longer needs one prefix "elected" at switch time,
          # since each reaper-<name> binary re-syncs its own chainloaders
          # into it right before launching (see mkReaperScript above).
          home.activation.audioWinePrefixStable = lib.hm.dag.entryAfter [ "writeBoundary" ] (
            let
              wineBinPath = audiopkgs.lib.makeBinPath winePkgsStable;
              winePrefixDir = "/home/${config.home.username}/.wine-stable";
            in
            # bash
            ''
              export PATH=${audiopkgs.lib.escapeShellArg wineBinPath}:$PATH

              # Needed for Guitar Pro 5. Checked against the actual DLL
              # rather than "the prefix directory doesn't exist yet" - a
              # prefix can exist without a given verb applied (e.g. an
              # interrupted activation), and gating on the directory alone
              # would then never retry.
              if [ ! -e ${audiopkgs.lib.escapeShellArg winePrefixDir}/drive_c/windows/system32/gdiplus.dll ]; then
                WINEPREFIX=${audiopkgs.lib.escapeShellArg winePrefixDir} winetricks -q gdiplus
              fi

              # Stock/staging wine has no Direct2D/DirectComposition path to
              # conflict with DXVK (unlike experimentalWine below, which
              # deliberately omits it). Uses winetricks' own "dxvk" verb
              # (network-dependent, but confirmed working) rather than
              # nixpkgs' dxvk package/setup_dxvk.sh.
              if [ ! -e ${audiopkgs.lib.escapeShellArg winePrefixDir}/drive_c/windows/system32/d3d9.dll ]; then
                WINEPREFIX=${audiopkgs.lib.escapeShellArg winePrefixDir} winetricks -q dxvk
              fi

              ${mkPrefixActivationBody winePrefixDir}
            ''
          );

          home.activation.audioWinePrefixExperimental = lib.hm.dag.entryAfter [ "writeBoundary" ] (
            let
              wineBinPath = audiopkgs.lib.makeBinPath winePkgsExperimental;
              winePrefixDir = "/home/${config.home.username}/.wine-experimental";
            in
            # bash
            ''
              export PATH=${audiopkgs.lib.escapeShellArg wineBinPath}:$PATH

              # Needed for Guitar Pro 5. Checked against the actual DLL
              # rather than "the prefix directory doesn't exist yet" - a
              # prefix can exist without a given verb applied (e.g. an
              # interrupted activation), and gating on the directory alone
              # would then never retry. DXVK is deliberately not installed
              # here - giang17's Direct2D/DirectComposition wine fork (see
              # experimentalWine above) explicitly says not to: DXVK
              # replaces dxgi.dll/d3d11.dll and bypasses the
              # composition-swapchain path the fork is built on.
              if [ ! -e ${audiopkgs.lib.escapeShellArg winePrefixDir}/drive_c/windows/system32/gdiplus.dll ]; then
                WINEPREFIX=${audiopkgs.lib.escapeShellArg winePrefixDir} winetricks -q gdiplus
              fi

              ${mkPrefixActivationBody winePrefixDir}
            ''
          );

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
        inherit
          stableWine
          experimentalWine
          yabridgeStable
          yabridgeExperimental
          yabridgectlStable
          yabridgectlExperimental
          ;

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
