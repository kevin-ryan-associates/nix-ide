{
  description = "nix-ide — Nix-managed developer environment (port of ~/dotfiles)";

  inputs = {
    # Pinned to nixpkgs-26.05-darwin: nixpkgs unstable (26.11) dropped
    # x86_64-darwin (Intel macOS) support. This branch supports both
    # aarch64-darwin and x86_64-darwin through end of 2026, plus Linux.
    # When Intel Mac support is no longer needed, switch back to
    # nixos-unstable. See https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.11
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      # Pure-evaluation-safe enumeration of supported platforms. Flakes cannot
      # use `builtins.currentSystem` under `nix build`/`nix run` (pure mode), so
      # we expose one homeConfigurations output per system:
      #   .#homeConfigurations.kevin-aarch64-darwin   (macOS Apple Silicon)
      #   .#homeConfigurations.kevin-x86_64-darwin    (macOS Intel)
      #   .#homeConfigurations.kevin-aarch64-linux
      #   .#homeConfigurations.kevin-x86_64-linux
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # Per-(system, username) home-manager configuration factory.
      # `username` flows into `home.username`/`home.homeDirectory`, which
      # HM bakes into session-vars (STARSHIP_CONFIG, TERMINFO_DIRS, …).
      mkHomeConfig = system: username:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "/Users/${username}"
            else "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home
            { home = { inherit username homeDirectory; }; }
          ];
        };

      # Convenience: devShell per system. `nix develop .` or
      # `nix develop github:kevin-ryan-associates/nix-ide` drops the user
      # into an interactive bash with the Phase 1 tools (zsh, starship, fzf,
      # zoxide, eza, bat, delta) on PATH. No home-manager, no $HOME writes —
      # the simplest path for someone to try the tool inventory.
      mkDevShell = system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        pkgs.mkShellNoCC {
          packages = with pkgs; [ zsh starship fzf zoxide eza bat fd delta ];
          shellHook = ''
            echo "nix-ide dev shell — Phase 1 tools on PATH"
            echo "  zsh/starship/fzf/zoxide/eza/bat/fd/delta"
            echo
            echo "Try: eza --icons | head -5"
            echo "Or:  starship config 2>&1 | head -5"
            echo "Exit with Ctrl-D to return to your normal shell."
          '';
        };
    in
    {
      # Maintainer's own home configs.
      homeConfigurations = builtins.listToAttrs (map (s: {
        name = "kevin-${s}";
        value = mkHomeConfig s "kevinryan";
      }) supportedSystems);

      # Shareable home-manager module bundle. Other users import this in
      # their own flake and set their own `home.username`/`home.homeDirectory`.
      # See README.md "For other users" section.
      homeModules.default = ./home;

      # Quick-test shell. `nix develop .` for local, `nix develop
      # github:kevin-ryan-associates/nix-ide` for anyone, no setup.
      devShells = builtins.listToAttrs (map (s: {
        name = s;
        value.default = mkDevShell s;
      }) supportedSystems);

      # ---------------------------------------------------------------------------
      # Phase 2+ scaffolding (intentionally not wired up yet):
      #
      #   darwinConfigurations.kevin-mac = nix-darwin.lib.darwinSystem { … }
      #     - Colima, font casks, Ghostty cask, system-level packages,
      #       `chsh` to zsh is already done by home-manager.
      #
      #   nixosConfigurations.kevin-linux = nixpkgs.lib.nixosSystem { … }
      #     - Native Docker, fontconfig, system packages.
      #
      # Both land when their respective phases ship. Until then the flake
      # exposes only what actually evaluates cleanly.
      # ---------------------------------------------------------------------------
    };
}