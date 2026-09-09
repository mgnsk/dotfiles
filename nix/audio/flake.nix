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

      audio = import ./audio.nix { inherit audiopkgs; };
      inherit (audio) audioPkgs homeModule;

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
        inherit audioPkgs;

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
