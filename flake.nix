{
  description = "ide";

  inputs = {
    nixpkgs-home.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    audio.url = "path:./nix/audio"; # TEMP: local override for debugging, see refactor.md

    # Neovim plugins not in nixpkgs.
    nvim-plugin-tree-sitter-manager = {
      url = "github:romus204/tree-sitter-manager.nvim";
      flake = false;
    };

    nvim-plugin-autotabline = {
      url = "github:mgnsk/autotabline.nvim";
      flake = false;
    };

    nvim-plugin-dumb-autopairs = {
      url = "github:mgnsk/dumb-autopairs.nvim";
      flake = false;
    };

    nvim-plugin-nvim-fundo = {
      url = "github:kevinhwang91/nvim-fundo";
      flake = false;
    };

    nvim-plugins-tree-sitter-balafon = {
      url = "github:mgnsk/tree-sitter-balafon";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    reaper-flake = {
      url = "github:9Prestidigitator/reaper-flake";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-home";
      inputs.home-manager.follows = "home-manager";
    };

    # Firefox extension packages (vimium, ublock-origin, ...).
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      username = builtins.getEnv "USER";

      homepkgs = import inputs.nixpkgs-home {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      hostname = builtins.getEnv "HOSTNAME";
      audioHosts = [ "probook" ];

      # Roots for closurePositions below, derived from the actual build
      # output (home-manager's merged package list) rather than a
      # hand-curated list, so newly added programs/packages are
      # automatically included without maintenance. The audio flake
      # (nix/audio) tracks its own packageSets/closurePositions for its own
      # nixpkgs pin.
      packageSets = {
        nixpkgs-home = self.homeConfigurations.${username}.config.home.packages;
      };

      # For each package set, the meta.position of every package plus its
      # full transitive build closure, deduplicated by drvPath. Used by
      # nix/flake-update.sh to show per-file diffs scoped to declared
      # packages instead of a whole-nixpkgs-tree diff.
      closurePositions = builtins.mapAttrs (
        _: pkgs:
        let
          startSet = builtins.filter (p: builtins.isAttrs p && p ? drvPath) (homepkgs.lib.flatten pkgs);
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
                    homepkgs.lib.flatten (
                      (val.buildInputs or [ ])
                      ++ (val.nativeBuildInputs or [ ])
                      ++ (val.propagatedBuildInputs or [ ])
                      ++ (val.propagatedNativeBuildInputs or [ ])
                    )
                  )
                );
          };
        in
        homepkgs.lib.unique (
          builtins.filter (x: x != null) (map ({ val, ... }: val.meta.position or null) closure)
        )
      ) packageSets;
    in
    {
      inherit packageSets closurePositions;

      formatter.${system} = homepkgs.nixfmt;

      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = homepkgs;

        extraSpecialArgs = {
          inherit
            inputs
            username
            ;
        };

        modules = [
          inputs.reaper-flake.homeModules.reaper
          inputs.plasma-manager.homeModules.plasma-manager
        ]
        ++ homepkgs.lib.optional (builtins.elem hostname audioHosts) inputs.audio.homeModules.audio
        ++ [
          ./nix/base.nix
          ./nix/shell.nix
          ./nix/terminals.nix
          ./nix/git.nix
          ./nix/neovim.nix
          ./nix/sway.nix
          ./nix/openbox.nix
          ./nix/desktop.nix
          ./nix/dev-tools.nix
          ./nix/packages.nix
          ./nix/misc.nix
        ];
      };
    };
}
