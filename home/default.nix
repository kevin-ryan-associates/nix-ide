# Home-manager aggregator.
#
# Wired into the flake as the single home-manager module. Imports the
# per-concern modules and sets the cross-cutting fields (username, home
# directory, state version) that came from the flake via extraSpecialArgs.

{ username, homeDirectory, ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./fzf.nix
    ./zoxide.nix
    ./packages.nix
    ./files.nix
  ];

  home = {
    inherit username homeDirectory;
    stateVersion = "24.11";
  };

  # We only use zsh; disable shell integration defaults for every other
  # shell so HM modules don't pull in nushell/fish/bash integration code
  # paths (and avoid the fzf >=0.73.0 nushell assertion when our pinned
  # nixpkgs-26.05-darwin ships fzf 0.72.0).
  home.shell = {
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableIonIntegration = false;
    enableNushellIntegration = false;
    # enableZshIntegration stays true (default).
  };

  # Let home-manager manage itself.
  programs.home-manager.enable = true;

  # Pinned nixpkgs (26.05-darwin for Intel macOS support) doesn't match HM's
  # unstable branch (26.11). Harmless in practice — disable the version
  # check warning. Revisit when Intel Mac support is no longer needed and
  # nixpkgs flips back to nixos-unstable.
  home.enableNixpkgsReleaseCheck = false;
}