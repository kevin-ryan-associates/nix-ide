# NixOS module bundle (Phase 8).
#
# Composable — a consumer imports this in their own `nixosConfigurations`
# via `nixpkgs.lib.nixosSystem { modules = [ nix-ide.nixosModules.default ]; }`
# and supplies their own `home.username`/`home.homeDirectory`/hostname.
#
# What this bundle does:
#   - Enables native Docker (`virtualisation.docker.enable = true;`).
#   - Installs the Meslo Nerd Font via `fonts.fonts` so Ghostty, Neovim and
#     terminal icons render correctly. macOS gets the same font via the
#     Homebrew cask in `darwinModules.default`.
#   - Wires `home-manager.nixosModules.home-manager` so HM activates as part
#     of `nixos-rebuild switch`.
#   - Imports the user-agnostic `homeModules.default` (Phase 2–7) so every
#     HM-managed config + tool lands at switch time.
#
# What this bundle does NOT do:
#   - Set `home.username` / `home.homeDirectory` (caller does).
#   - Create the user account — caller's `users.users.<name>` does.
#   - Hardcode a hostname (caller does).
#   - Change the default shell at the system level — `programs.zsh.enable`
#     is enabled here so the binary is on PATH, and `home-manager` sets the
#     user's shell via `users.users.<name>.shell` when the caller configures
#     their user.

{ pkgs, lib, inputs, self, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    self.homeModules.default
  ];

  # Pass the vendored upstream flake inputs through to
  # `home-manager.extraSpecialArgs` so `home/herdr.nix` and
  # `home/opencode.nix` can `herdr.packages...` resolve.
  home-manager.extraSpecialArgs = {
    herdr = inputs.herdr;
    opencode = inputs.opencode;
  };

  # ---- Native Docker runtime ---------------------------------------------
  # Linux equivalent of the macOS Colima cask. The HM bundle's `lazydocker`
  # + `docker compose` invocation resolve against this daemon.
  virtualisation.docker.enable = true;

  # ---- Nerd Font (one-line equivalent of the brew cask on macOS) ---------
  # `nerd-fonts.meslo-lg` ships the same MesloLGS Nerd Font the dotfiles
  # repo installed via `brew install --cask font-meslo-lg-nerd-font` on
  # macOS. `fonts.fonts` adds it to the system font path; fc-cache runs
  # automatically on activation.
  fonts.fonts = with pkgs; [ nerd-fonts.meslo-lg ];

  # ---- 1Password CLI on Linux --------------------------------------------
  # macOS gets this via the brew cask in `darwinModules.default`. On Linux
  # the formula lives at `_1password-cli` in nixpkgs. Keep it out of
  # `homeModules.default`'s `home.packages` so the shareable home bundle
  # doesn't import a darwin-incompatible name; instead ship it here as a
  # system-level package.
  environment.systemPackages = with pkgs; [ _1password-cli ];
}