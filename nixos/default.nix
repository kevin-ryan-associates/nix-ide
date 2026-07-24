# NixOS module bundle (Phase 8).
#
# Composable — a consumer imports this in their own `nixosConfigurations`
# via `nixpkgs.lib.nixosSystem { modules = [ nix-ide.nixosModules.default ]; }`
# and supplies their own `home.username`/`home.homeDirectory`/hostname.
#
# This file is NOT a module directly: `flake.nix` evaluates
# `import ./nixos { inherit inputs self; }`, closing over nix-ide's own
# flake inputs. That is what makes the bundle self-contained — consumers
# need no `specialArgs` and do not re-declare our vendored inputs.
#
# What this bundle does:
#   - Enables native Docker (`virtualisation.docker.enable = true;`).
#   - Installs the Meslo Nerd Font via `fonts.packages` so Ghostty, Neovim
#     and terminal icons render correctly. macOS gets the same font via the
#     Homebrew cask in `darwinModules.default`.
#   - Wires `home-manager.nixosModules.home-manager` so HM activates as part
#     of `nixos-rebuild switch`, and imports the user-agnostic
#     `homeModules.default` via `home-manager.sharedModules` so every
#     HM-managed config + tool lands on every declared
#     `home-manager.users.<name>` at switch time.
#   - Enables zsh at the system level so it lands in `/etc/shells` — the HM
#     bundle's `programs.zsh` config is per-user, but the login shell must
#     be system-known for `chsh`/display managers. The caller still picks
#     the shell per user (`users.users.<name>.shell = pkgs.zsh;`).
#
# What this bundle does NOT do:
#   - Set `home.username` / `home.homeDirectory` (caller does, per
#     `home-manager.users.<name>`).
#   - Create the user account — caller's `users.users.<name>` does.
#   - Hardcode a hostname (caller does).
#   - Set `system.stateVersion` (caller does — NixOS asserts it).

{ inputs, self }:

{ pkgs, lib, config, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # The user-agnostic HM bundle (Phase 2–7) applied to every declared
  # `home-manager.users.<name>`. It carries its own `_module.args` for the
  # vendored upstream flakes (herdr/opencode/hunk), so nothing further is
  # needed here — consumers only supply `home.username`/`home.homeDirectory`.
  home-manager.sharedModules = [ self.homeModules.default ];

  # ---- Native Docker runtime ---------------------------------------------
  # Linux equivalent of the macOS Colima cask. The HM bundle's `lazydocker`
  # + `docker compose` invocation resolve against this daemon.
  virtualisation.docker.enable = true;

  # ---- Nerd Font (one-line equivalent of the brew cask on macOS) ---------
  # `nerd-fonts.meslo-lg` ships the same MesloLGS Nerd Font the dotfiles
  # repo installed via `brew install --cask font-meslo-lg-nerd-font` on
  # macOS. `fonts.packages` adds it to the system font path; fc-cache runs
  # automatically on activation.
  fonts.packages = with pkgs; [ nerd-fonts.meslo-lg ];

  # ---- System zsh ----------------------------------------------------------
  # Put zsh on the system PATH and in `/etc/shells` so callers can set
  # `users.users.<name>.shell = pkgs.zsh;` and `chsh` works. The HM bundle
  # owns the per-user zsh *config*; this is just the system binary.
  programs.zsh.enable = true;
}
