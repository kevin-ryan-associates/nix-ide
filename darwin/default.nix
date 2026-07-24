# nix-darwin module bundle (Phase 8).
#
# Composable — a consumer imports this in their own `darwinConfigurations`
# via `nix-darwin.lib.darwinSystem { modules = [ nix-ide.darwinModules.default ]; }`
# and supplies their own `home.username`/`home.homeDirectory`/hostname.
#
# This file is NOT a module directly: `flake.nix` evaluates
# `import ./darwin { inherit inputs self; }`, closing over nix-ide's own
# flake inputs. That is what makes the bundle self-contained — consumers
# need no `specialArgs` and do not re-declare our vendored inputs.
#
# What this bundle does:
#   - Wires `home-manager.darwinModules.home-manager` so home-manager is
#     activated as part of `darwin-rebuild switch`.
#   - Imports the user-agnostic `homeModules.default` via
#     `home-manager.sharedModules` so every HM-managed config + tool lands
#     on every declared `home-manager.users.<name>` at `darwin-rebuild`
#     time. (Importing the HM bundle at the system scope instead would
#     fail: `home.*` / `programs.starship` / `xdg.*` are not nix-darwin
#     options.)
#   - Enables Homebrew via `nix-homebrew` and declares the casks the HM
#     side of the config expects: Ghostty and the Nerd Font, plus the
#     Colima formula. These live here rather than in `homeModules.default`
#     because they are system-level (Homebrew casks touch `/Applications`,
#     `/usr/local`, the TCC db, etc.).
#   - Sets up the `~/.docker/config.json` patch that wires
#     `cliPluginsExtraDirs` to the running brew prefix so `docker compose`
#     resolves (see `./docker.nix`). Runs as a home-manager activation —
#     user context — because nix-darwin system activation runs as root
#     with `HOME=~root`.
#
# What this bundle does NOT do:
#   - Set `home.username` / `home.homeDirectory` (caller does, per
#     `home-manager.users.<name>`).
#   - Hardcode a hostname (caller does).
#   - Set `system.stateVersion` / `system.primaryUser` (caller does —
#     nix-darwin asserts both; `nix-homebrew.user` below follows
#     `system.primaryUser`).
#   - Run `chsh` — neither nix-darwin nor home-manager changes the login
#     shell. macOS already defaults to zsh; anything else is a manual
#     consumer step (`chsh -s $(which zsh)`), outside the rebuild.

{ inputs, self }:

{ pkgs, lib, config, ... }:

{
  imports = [
    # Home-manager's darwin module — wires HM activation into darwin-rebuild.
    inputs.home-manager.darwinModules.home-manager
    # Homebrew declarative management via nix-homebrew.
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./docker.nix
  ];

  # The user-agnostic HM bundle (Phase 2–7) applied to every declared
  # `home-manager.users.<name>`. It carries its own `_module.args` for the
  # vendored upstream flakes (herdr/opencode/hunk), so nothing further is
  # needed here — consumers only supply `home.username`/`home.homeDirectory`.
  home-manager.sharedModules = [ self.homeModules.default ];

  # ---- Homebrew (casks + the Colima formula) -------------------------------
  # nix-homebrew installs Homebrew itself declaratively; we declare the casks
  # below. They land on `darwin-rebuild switch` — first activation prompts the
  # user for `sudo` once (nix-homebrew's documented behaviour).
  nix-homebrew = {
    enable = true;
    # Apple Silicon and Intel both use `/opt/homebrew` under nix-homebrew
    # (it installs the appropriate prefix per arch). Casks downstream use
    # the standard brew paths.
    enableRosetta = false;  # No x86_64 casks in this set.
    # Follow `system.primaryUser` (which nix-darwin asserts is set when
    # homebrew is enabled); the caller can still override explicitly.
    user = lib.mkIf (config.system.primaryUser != null)
      (lib.mkDefault config.system.primaryUser);
  };

  homebrew = {
    enable = true;
    brews = [
      "colima"
      "docker"
      "docker-compose"
    ];
    casks = [
      "ghostty"
      "font-meslo-lg-nerd-font"
    ];
    onActivation = {
      # Don't auto-upgrade on every `darwin-rebuild switch` — that would
      # re-download GBs of casks. Pin via the nix-homebrew flake.lock +
      # `brew upgrade` is the user's manual call when they want a bump.
      autoUpdate = false;
      upgrade = false;
      # `cleanup` would uninstall anything not declared here — too aggressive
      # for a shareable config (the user may have other casks for unrelated
      # work). Leave it `none` and let the user opt-in per-host.
      cleanup = "none";
    };
  };
}
