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
# This bundle is user-agnostic: it sets NO `home.username` /
# `home.homeDirectory`. The consumer's own flake supplies those, e.g.:
#
#   homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
#     pkgs = nixpkgs.legacyPackages.x86_64-darwin;
#     modules = [
#       nix-ide.homeModules.default
#       { home = { username = "alice"; homeDirectory = "/Users/alice"; stateVersion = "24.11"; }; }
#     ];
#   };
#
# See README.md "For other users" for the full canonical example.

{ ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./fzf.nix
    ./zoxide.nix
    ./packages.nix
    ./files.nix
    ./git.nix
    ./lazygit.nix
    ./lazydocker.nix
    ./nvim.nix
    ./bat.nix
    ./btop.nix
    ./htop.nix
    ./ghostty.nix
    ./herdr.nix
    ./opencode.nix
    ./hunk.nix
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

  # Force XDG config paths on every platform — including macOS. We
  # deliberately avoid the macOS-only `~/Library/Application Support/...`
  # location the dotfiles repo also stowed (lazygit/lazydocker read XDG
  # first on macOS, so the Library/ symlinks were redundant there — dropped
  # in this port). With `xdg.enable = true;`, HM modules for lazygit,
  # lazydocker, and everything else with a Darwin-vs-XDG fork write to
  # `~/.config/<tool>/...` on all hosts.
  xdg.enable = true;

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}