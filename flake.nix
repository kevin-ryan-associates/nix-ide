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

      # Per-system home-manager configuration factory.
      mkHomeConfig = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          username = "kevinryan";
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "/Users/${username}"
            else "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home ];
          extraSpecialArgs = {
            inherit nixpkgs;
            inherit username homeDirectory;
          };
        };
    in
    {
      homeConfigurations = builtins.listToAttrs (map (s: {
        name = "kevin-${s}";
        value = mkHomeConfig s;
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