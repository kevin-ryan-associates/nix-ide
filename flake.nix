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

    # Vendored upstream binaries not packaged in nixpkgs at our pin.
    #   herdr — agent multiplexer (https://herdr.dev/), v0.7.5.
    #     Upstream publishes a flake — consume `packages.${system}.herdr`.
    #   opencode — coding agent (https://opencode.ai/), v1.18.4.
    #     Same pattern, `packages.${system}.opencode`. Falls back to
    #     `nixpkgs#opencode` (1.15.10) if upstream vendor hashes break on a
    #     given system — see home/opencode.nix.
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/v1.18.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin + nix-homebrew for Phase 8 system modules (macOS casks,
    # Colima, `1password-cli`, the Docker `cliPluginsExtraDirs` activation
    # script). Imported only by consumers who activate a darwinConfiguration;
    # sharing them means they follow our nixpkgs.
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # No `inputs.nixpkgs.follows` here — nix-homebrew doesn't expose a
      # nixpkgs input (only `brew-src`). Following it spams an "override for
      # a non-existent input" warning.
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, ... }:
    let
      # Pure-evaluation-safe enumeration of supported platforms. Flakes
      # cannot use `builtins.currentSystem` under `nix build`/`nix run`
      # (pure mode), so we expose outputs per system explicitly.
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # Home-manager config factory. User-agnostic — the caller supplies
      # `username` (which flows into `home.username`/`home.homeDirectory`).
      # This is no longer wired into a default `homeConfigurations.${name}`
      # output; consumers build their own. It is kept as a convenience for
      # `dev.sh` (sandbox) and for downstream users who want a builder.
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
          # Thread vendored upstream flake inputs into the home module so
          # `home/herdr.nix`/`home/opencode.nix` can consume their packages.
          extraSpecialArgs = {
            herdr = inputs.herdr;
            opencode = inputs.opencode;
          };
        };

      # Convenience: devShell per system. `nix develop .` drops the user into
      # an interactive bash with the always-on tools (zsh, starship, fzf,
      # zoxide, eza, bat, fd, delta) on PATH. No home-manager, no $HOME
      # writes — the simplest path for someone to try the tool inventory.
      mkDevShell = system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        pkgs.mkShellNoCC {
          packages = with pkgs; [ zsh starship fzf zoxide eza bat fd delta ];
          shellHook = ''
            echo "nix-ide dev shell — always-on tools on PATH"
            echo "  zsh/starship/fzf/zoxide/eza/bat/fd/delta"
            echo
            echo "Try: eza --icons | head -5"
            echo "Or:  starship config 2>&1 | head -5"
            echo "Exit with Ctrl-D to return to your normal shell."
          '';
        };
    in
    {
      # -------------------------------------------------------------------------
      # Shareable module bundles. The whole repo is keyed off these — no
      # `homeConfigurations.${name}` or `darwinConfigurations.${name}` are
      # published here. A consumer writes their own flake and imports the
      # bundle that matches their platform, supplying their own username,
      # homeDirectory, and hostname.
      #
      # See README.md "For other users" for the canonical example flake.
      # -------------------------------------------------------------------------

      # Home-manager bundle (Phase 2–7): zsh, starship, fzf, zoxide, git/delta,
      # lazygit, lazydocker, bat, btop, htop, ghostty config, herdr, opencode,
      # nvim (AstroNvim), k8s binaries, tree/jq/yq, gh/glab.
      homeModules.default = ./home;

      # nix-darwin bundle (Phase 8): Homebrew casks (ghostty, 1password-cli,
      # font-meslo-lg-nerd-font), Colima + Docker compose, the Docker
      # `cliPluginsExtraDirs` activation script, and home-manager wired in
      # importing `self.homeModules.default`.
      darwinModules.default = ./darwin;

      # NixOS bundle (Phase 8): native Docker, Meslo Nerd Font via
      # `fonts.fonts`, and home-manager wired in importing
      # `self.homeModules.default`.
      nixosModules.default = ./nixos;

      # -------------------------------------------------------------------------
      # DevShell — the only non-module output we publish ourselves. Anyone
      # can `nix develop github:<this-repo>` to get the tool inventory on
      # PATH with no setup, no home-manager, no $HOME writes.
      # -------------------------------------------------------------------------
      devShells = builtins.listToAttrs (map (s: {
        name = s;
        value.default = mkDevShell s;
      }) supportedSystems);

      # A debug-only hostConfigurations builder for `dev.sh` against a
      # sandbox HOME. NOT for direct consumer use. The canonical path for a
      # new user is to write their own flake that imports `homeModules.default`
      # (or `darwinModules.default` / `nixosModules.default`).
      #
      # This is a per-system factory wrapped in `lib hydraJobs`-style
      # enumeration so it evaluates clean but does not pollute the user's
      # `nix flake show` listing — it's only consumed by `dev.sh`.
      legacyPackages = builtins.listToAttrs (map (s: {
        name = s;
        value = rec {
          # Sandbox-only HM config using a placeholder username. The
          # `homeDirectory` is overridden by `dev.sh` at runtime to point
          # at a throwaway `mktemp` HOME.
          homeConfigurations.sandbox = mkHomeConfig s "nix-ide-dev";
        };
      }) supportedSystems);
    };
}