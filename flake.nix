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
      # Pinned to the release branch matching our nixpkgs (26.05). Tracking
      # HM master against a pinned nixpkgs makes every `nix flake update` an
      # option-removal lottery (programs.git.delta rename, fonts.fonts
      # removal, ...). `nix flake update` now moves within 26.05 backports.
      url = "github:nix-community/home-manager/release-26.05";
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
    # hunk — review-first terminal diff viewer (https://hunk.dev/), v0.17.3.
    #   Not in nixpkgs at our `nixpkgs-26.05-darwin` pin (present in
    #   unstable, but we're pinned for Intel Mac support through end of
    #   2026). Upstream publishes a flake with `packages.${system}.hunk`
    #   for all four supportedSystems — same vendor pattern as herdr/opencode.
    hunk = {
      url = "github:modem-dev/hunk/v0.17.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin + nix-homebrew for Phase 8 system modules (macOS casks,
    # Colima, the Docker `cliPluginsExtraDirs` activation script). Imported
    # only by consumers who activate a darwinConfiguration; sharing them
    # means they follow our nixpkgs.
    nix-darwin = {
      # nix-darwin has release branches matching nixpkgs releases and HARD
      # asserts the correspondence (eval-config.nix: nix-darwin 26.11 vs
      # nixpkgs 26.05 is a throw, not a warning). Pin the 26.05 branch to
      # match our nixpkgs. Note the org moved lnl7 -> nix-darwin.
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
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

      # Home-manager configuration builder — the public instantiation layer.
      # Exported as `lib.mkHome`. Takes the user's identity/system and returns
      # a `home-manager.lib.homeManagerConfiguration` importing the wrapped
      # `homeModules.default` bundle (which carries `_module.args` for the
      # vendored upstream flakes, so no extraSpecialArgs are needed).
      #
      # `homeDirectory` defaults to the platform convention (/Users on macOS,
      # /home on Linux) but may be given explicitly. `extraModules` lets a
      # consumer inject per-user overrides (git user.name/email, secrets
      # wiring, ...) without dropping to a raw homeManagerConfiguration.
      #
      # Used by: the `homeConfigurations."example@x86_64-linux"` template
      # below, and `dev.sh`'s private sandbox config. Consumers call
      # `nix-ide.lib.mkHome` from their own flake — see README "For other
      # users".
      mkHome = { username, system
               , homeDirectory ?
                   (if nixpkgs.legacyPackages.${system}.stdenv.hostPlatform.isDarwin
                    then "/Users/${username}"
                    else "/home/${username}")
               , extraModules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            self.homeModules.default
            { home = { inherit username homeDirectory; }; }
          ] ++ extraModules;
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
      # Shareable module bundles + the instantiation layer. The repo is keyed
      # off the three module bundles below; `lib.mkHome` is the builder that
      # wires `homeModules.default` into a ready-to-switch
      # `home-manager.lib.homeManagerConfiguration` for a caller-supplied
      # identity. The only `homeConfigurations` entry published here is the
      # `example@x86_64-linux` template (see its comment) — no real
      # `darwinConfigurations` / `nixosConfigurations` are published at all.
      # A consumer writes their own flake, calls `nix-ide.lib.mkHome` (or
      # imports the system bundles), and supplies their own username,
      # homeDirectory, and hostname.
      #
      # See README.md "For other users" for the canonical example flake.
      # -------------------------------------------------------------------------

      # Home-manager bundle (Phase 2–7): zsh, starship, fzf, zoxide, git/delta,
      # lazygit, lazydocker, bat, btop, htop, ghostty config, herdr, opencode,
      # nvim (AstroNvim), k8s binaries, tree/jq/yq, gh/glab.
      #
      # Wrapped in a module that injects the vendored upstream flakes via
      # `_module.args`, so consumers NEVER need `extraSpecialArgs` — the
      # bundle is self-contained from this flake's own inputs.
      homeModules.default = { ... }: {
        imports = [ ./home ];
        _module.args = {
          inherit (inputs) herdr opencode hunk;
        };
      };

      # nix-darwin bundle (Phase 8): Homebrew casks (ghostty,
      # font-meslo-lg-nerd-font), Colima + Docker compose, the Docker
      # `cliPluginsExtraDirs` activation script, and home-manager wired in
      # via `home-manager.sharedModules`.
      #
      # `import`ed with this flake's `inputs`/`self` closed over — module
      # arguments would otherwise resolve against the CONSUMER's flake
      # (missing `homeModules`, missing vendored inputs) or fail as unbound
      # arguments. Consumers need zero `specialArgs`.
      darwinModules.default = import ./darwin { inherit inputs self; };

      # NixOS bundle (Phase 8): native Docker, Meslo Nerd Font via
      # `fonts.packages`, and home-manager wired in via
      # `home-manager.sharedModules`. Same closure pattern as darwin.
      nixosModules.default = import ./nixos { inherit inputs self; };

      # -------------------------------------------------------------------------
      # Instantiation layer: the builder consumers call from their own flake
      # to get a ready-to-switch home-manager target for their identity.
      #
      #   homeConfigurations."alice@x86_64-linux" = nix-ide.lib.mkHome {
      #     username = "alice";
      #     system = "x86_64-linux";
      #     homeDirectory = "/home/alice";   # optional — platform default
      #     extraModules = [ ... ];          # optional — per-user overrides
      #   };
      # -------------------------------------------------------------------------
      lib.mkHome = mkHome;

      # -------------------------------------------------------------------------
      # Example / template only. This entry demonstrates `lib.mkHome` against
      # a clearly placeholder identity so consumers have a working config to
      # copy and adapt — it is NOT meant to be activated as-is (there is no
      # "example" user anywhere). Copy it into your own flake with your own
      # username/system/homeDirectory; see README "For other users".
      # -------------------------------------------------------------------------
      homeConfigurations."example@x86_64-linux" = mkHome {
        username = "example";
        system = "x86_64-linux";
      };

      # -------------------------------------------------------------------------
      # DevShell — the only non-module output we publish ourselves. Anyone
      # can `nix develop github:<this-repo>` to get the tool inventory on
      # PATH with no setup, no home-manager, no $HOME writes.
      # -------------------------------------------------------------------------
      devShells = builtins.listToAttrs (map (s: {
        name = s;
        value.default = mkDevShell s;
      }) supportedSystems);

      # A debug-only homeConfigurations builder for `dev.sh` against a
      # sandbox HOME. NOT for direct consumer use. The canonical path for a
      # new user is to write their own flake that calls `lib.mkHome` (or
      # imports `darwinModules.default` / `nixosModules.default`).
      #
      # This is a per-system factory wrapped in `lib hydraJobs`-style
      # enumeration so it evaluates clean but does not pollute the user's
      # `nix flake show` listing — it's only consumed by `dev.sh`.
      legacyPackages = builtins.listToAttrs (map (s: {
        name = s;
        value = rec {
          # Sandbox-only HM config using a placeholder username, built by the
          # same `mkHome` consumers use. The `homeDirectory` is overridden by
          # `dev.sh` at runtime to point at a throwaway `mktemp` HOME.
          homeConfigurations.sandbox = mkHome {
            system = s;
            username = "nix-ide-dev";
          };
        };
      }) supportedSystems);
    };
}