{ pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # Nix-built GUI programs link against
  # glvnd, which on NixOS finds GPU drivers via /run/opengl-driver.
  # That path doesn't exist on Arch, so EGL/GLX finds zero vendor
  # ICDs and every OpenGL window fails to open. This symlinks the
  # Mesa drivers from this flake's nixpkgs into /run/opengl-driver
  # (one-time `sudo .../non-nixos-gpu-setup` after switching).
  targets.genericLinux.enable = true;

  nix.package = pkgs.nix;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
