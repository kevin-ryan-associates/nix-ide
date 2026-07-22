# nix-darwin module bundle (Phase 8).
#
# Composable — a consumer imports this in their own `darwinConfigurations`
# via `nix-darwin.lib.darwinSystem { modules = [ nix-ide.darwinModules.default ]; }`
# and supplies their own `home.username`/`home.homeDirectory`/hostname.
#
# What this bundle does:
#   - Wires `home-manager.darwinModules.home-manager` so home-manager is
#     activated as part of `darwin-rebuild switch`.
#   - Imports the user-agnostic `homeModules.default` (Phase 2–7) so every
#     HM-managed config + tool lands at `darwin-rebuild` time.
#   - Enables Homebrew via `nix-homebrew` and declares the casks the HM
#     side of the config expects: Ghostty, 1password-cli, the Nerd Font,
#     plus the Colima formula. These live here rather than in
#     `homeModules.default` because they are system-level (Homebrew casks
#     touch `/Applications`, `/usr/local`, the TCC db, etc.).
#   - Sets up the `~/.docker/config.json` activation script that wires
#     `cliPluginsExtraDirs` to the running brew prefix so `docker compose`
#     resolves. Same idea as `install-mac.sh` did in the dotfiles repo, but
#     executes at `darwin-rebuild` time and uses the nix-homebrew prefix
#     rather than the ad-hoc `brew --prefix` of the old install script.
#
# What this bundle does NOT do:
#   - Set `home.username` / `home.homeDirectory` (caller does).
#   - Hardcode a hostname (caller does).
#   - Run `chsh` — home-manager already does that on activation when
#     `programs.zsh.enable = true`.

{ pkgs, lib, config, inputs, self, ... }:

{
  imports = [
    # Home-manager's darwin module — wires HM activation into darwin-rebuild.
    inputs.home-manager.darwinModules.home-manager
    # The user-agnostic HM bundle (Phase 2–7). Consumes
    # `home.username`/`home.homeDirectory` set by the caller, so we don't set
    # them here.
    self.homeModules.default
    # Homebrew declarative management via nix-homebrew.
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./docker.nix
  ];

  # Pass the vendored upstream flake inputs through to `home-manager.extraSpecialArgs`
  # so `home/herdr.nix` / `home/opencode.nix` / `home/hunk.nix` can `*.packages...`
  # resolve.
  home-manager.extraSpecialArgs = {
    herdr = inputs.herdr;
    opencode = inputs.opencode;
    hunk = inputs.hunk;
  };

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
    user = lib.mkDefault "you";  # Caller overrides — needed by nix-homebrew.
  };

  homebrew = {
    enable = true;
    brews = [
      "colima"
      "docker"
      "docker-compose"
    ];
    casks = [
      "1password-cli"
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