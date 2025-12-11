{
  description = "ide";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      airwindows-consolidated = pkgs.stdenv.mkDerivation {
        name = "airwindows-consolidated";
        src = pkgs.fetchzip {
          url = "https://github.com/baconpaul/airwin2rack/releases/download/DAWPlugin/AirwindowsConsolidated-2025-12-07-a797d6c-Linux.zip";
          sha256 = "4JnpnEWOiydXKxWmDQSVXqjPQqFWnnVzZuiuVcTWDDc=";
        };
        installPhase = ''
          install -m755 -D ./Airwindows\ Consolidated.clap $out/lib/clap/Airwindows\ Consolidated.clap
        '';
      };

      spirv-tools-lib = pkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${pkgs.spirv-tools}/lib/libSPIRV-Tools-shared.so";
        }
      ];

      reaper-default-5-dark-extended-theme = pkgs.stdenv.mkDerivation {
        name = "reaper-default-5-dark-extended-theme";
        src = pkgs.fetchurl {
          url = "https://stash.reaper.fm/30492/Default_5_Dark_Extended.ReaperThemeZip";
          sha256 = "9fd0577863dc267e093dacca0a7ddafd6a03a224a9224a8393ff82b67ab6727d";
        };
        phases = [ "installPhase" ];
        installPhase = ''
          install -m644 -D $src $out/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip
        '';
      };

      levelrider = pkgs.stdenv.mkDerivation {
        name = "levelrider";
        src = pkgs.fetchFromGitHub {
          owner = "unicornsasfuel";
          repo = "levelrider";
          rev = "ef54128";
          sha256 = "sha256-vyoqoA75hQ7SbliPCVs8ZTmDS3GHPGId4hF/9c34lB8=";
        };

        buildInputs = [
          pkgs.which
          pkgs.faust2lv2
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

      audioPkgs = with pkgs; [
        # Pipewire JACK management.
        pipewire.jack

        # For LSP and Zam plugins.
        mesa
        libGL

        # Complete Vulkan setup to fix Northern Artillery Drums plugin GUI not updating until window moved.
        libdrm
        llvmPackages_21.libllvm
        elfutils
        zstd
        xorg.libxcb
        wayland
        libz
        xorg.libX11
        xorg.libxshmfence
        xorg.xcbutilkeysyms
        libudev-zero
        expat
        spirv-tools-lib
        stdenv.cc.cc.lib

        # Reaper.
        reaper
        reaper-reapack-extension
        reaper-default-5-dark-extended-theme

        # Bitwig.
        bitwig-studio

        # Wine and yabridge.
        yabridge
        yabridgectl
        winetricks
        cabextract

        # General programs.
        fluidsynth
      ];

      clapPlugins = with pkgs; [
        airwindows-consolidated
        surge-XT
      ];

      lv2Plugins = with pkgs; [
        x42-plugins
        x42-avldrums
        magnetophonDSP.VoiceOfFaust
        magnetophonDSP.MBdistortion
        levelrider
        neural-amp-modeler-lv2
      ];

      vst3Plugins = with pkgs; [
        chow-phaser
      ];

      makePluginPath =
        type: paths:
        builtins.concatStringsSep ";" (
          map (path: path + "/lib/${type}") (builtins.filter (x: x != null) paths)
        );

      setIni =
        file: section: attrs:
        builtins.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (name: value: ''
            crudini --set --ini-options=nospace ${file} ${section} ${name} "${value}"
          '') attrs
        );
    in
    {
      devShells.${system} = {
        audio = pkgs.mkShellNoCC {
          buildInputs = [
            audioPkgs
            clapPlugins
            lv2Plugins
            vst3Plugins
          ];
          shellHook = ''
            set -e

            function cleanup {
              echo "Exiting audio shell"
              wineserver -k || true
            }

            trap cleanup EXIT

            export CUSTOM_HOST="ide-audio"
            export NIX_PROFILES="${pkgs.yabridge} $NIX_PROFILES"
            export WINEFSYNC=1
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath audioPkgs}:$LD_LIBRARY_PATH"

            # Setup reaper.
            mkdir -p ~/.config/REAPER/UserPlugins
            ln -sf ${pkgs.reaper-reapack-extension}/UserPlugins/* ~/.config/REAPER/UserPlugins/

            ${setIni "~/.config/REAPER/reaper.ini" "reaper" {
              lastthemefn5 = "${reaper-default-5-dark-extended-theme}/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip";
              clap_path_linux-x86_64 = "~/.clap;${makePluginPath "clap" clapPlugins}";
              lv2path_linux = "~/.lv2;${makePluginPath "lv2" lv2Plugins}";
              vstpath = "~/.vst;~/.vst3;${makePluginPath "vst3" vst3Plugins}";
              ui_scale = "1.0";
            }}

            bash ~/.scripts/check-vulkan-deps.sh
            bash ~/.win-plugins/setup.sh

            set +e

            echo "Starting audio shell"
          '';
        };
      };
    };
}
