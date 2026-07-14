# Home-manager module bundle — the shareable part.
#
# This is exported as `homeModules.default` so other users can import it in
# their own flake and set their own `home.username` / `home.homeDirectory`:
#
#   outputs = { nix-ide, home-manager, nixpkgs, ... }@inputs: {
#     homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
#       pkgs = nixpkgs.legacyPackages.x86_64-darwin;
#       modules = [
#         nix-ide.homeModules.default
#         { home = { username = "alice"; homeDirectory = "/Users/alice"; stateVersion = "24.11"; }; }
#       ];
#     };
#   };
#
# The maintainer's own `homeConfigurations.kevin-${system}` (defined in
# flake.nix) wraps this module with `home.username`/`home.homeDirectory`
# set, so this module itself stays user-agnostic.

{ ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./fzf.nix
    ./zoxide.nix
    ./packages.nix
    ./files.nix
  ];

  home.stateVersion = "24.11";

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