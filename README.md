# nix-ide

Nix-managed developer environment — a port of [`~/dotfiles`](https://github.com/kevin-ryan-associates/dotfiles) from GNU Stow + Homebrew to a Nix flake + home-manager. **Full replacement**: once parity is reached, `~/dotfiles` is archived and this repo is the single source of truth for the user environment.

## What this repo does

- Publishes **shareable module bundles** consumers compose in their own flake:
  - `homeModules.default` — the home-manager config (zsh, starship, fzf, zoxide, git/delta, lazygit, lazydocker, bat, btop, htop, ghostty config, herdr, opencode, nvim, k8s binaries, jq/yq/tree, gh/glab).
  - `darwinModules.default` — nix-darwin module: Homebrew casks (Ghostty, 1password-cli, Nerd Font), Colima, the Docker `cliPluginsExtraDirs` activation script, and `home-manager` wired in.
  - `nixosModules.default` — NixOS module: native Docker, Nerd Font via `fonts.fonts`, `1password-cli`, and `home-manager` wired in.
  - `devShells.${system}.default` — quick tool check via `nix develop .`, no `$HOME` writes.
- Uses native `programs.*` home-manager modules wherever HM models the tool cleanly (zsh, fzf, zoxide, starship, git, bat, htop, lazygit, lazydocker). Falls back to `home.file` for raw user-data that has no module (the ainative banner, the btop themes directory, the herdr config, the AstroNvim tree, the opencode config directory).
- Keeps **Zinit** as the zsh plugin manager (clone-on-first-run preserved verbatim in `programs.zsh.initExtra`). Plugin lazy-loading UX is unchanged from the dotfiles repo.
- Uses [AstroNvim](https://astronvim.com/) for Neovim, vendored into `files/nvim/` and deployed via `home.file`. Lazy.nvim is the plugin manager and stays in charge — plugins install on first `nvim` launch (~30s).
- Uses **vendored** upstream flake packages for `herdr` (v0.7.5) and `opencode` (v1.18.4), keeping vendor hashes upstream's problem.

## Prerequisites

1. **Nix** with flakes enabled. On Intel macOS use the [official Nix installer](https://nixos.org/download.html#nix-install-macos) (Determinate dropped Intel Mac support November 2025). On Apple Silicon or Linux, either installer works. Enable flakes via `~/.config/nix/nix.conf`:

   ```bash
   mkdir -p ~/.config/nix
   printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf
   ```

2. **home-manager**, **nix-darwin**, **nix-homebrew** are NOT required as separate installs — the consumer's flake exposes them through inputs.

3. **On macOS only:** `nix-homebrew` activates Homebrew declaratively on `darwin-rebuild switch`. The first activation prompts the user once for `sudo` (nix-homebrew's documented behaviour). After that, Homebrew is along for the ride and the casks (Ghostty, 1password-cli, Nerd Font) deploy automatically.

## Three ways to try this repo

### 1. `nix develop` — quick tool check, no setup

Drops into a bash shell with the always-on tools on PATH (zsh, starship, fzf, zoxide, eza, bat, fd, delta). No home-manager, no `$HOME` writes.

```bash
# From GitHub (anyone, no checkout needed):
nix develop github:kevin-ryan-associates/nix-ide

# From a local clone:
git clone git@github.com:kevin-ryan-associates/nix-ide.git
cd nix-ide && nix develop .
```

Exit with Ctrl-D.

### 2. `./dev.sh` — full port sandbox, still no `$HOME` writes

Builds the home-manager activation package (without switching), lays out the HM-managed files into a throwaway `mktemp` HOME, and `exec`s an interactive login zsh in that sandbox. Banner renders, Tokyo Night prompt renders, aliases work. Your real `~/.zshrc` is untouched.

```bash
git clone git@github.com:kevin-ryan-associates/nix-ide.git
cd nix-ide && ./dev.sh
# inside the sandbox:
starship --version
zsh --version
eza --version
# ...banner renders, Tokyo Night prompt renders
exit
```

The flake exposes a private `legacyPackages.${system}.homeConfigurations.sandbox` attribute exclusively for this script. Consumers don't use it — the canonical path is writing your own flake (see "For other users" below).

### 3. Permanent activation — macOS via `nix-darwin`

Once you've verified the port in dev mode, your own flake wires up `darwinConfigurations.<your-hostname>`. See "For other users" below for the full example.

```bash
nix run nix-darwin -- switch --flake ./my-flake#<your-hostname> -b backup
```

`-b backup` moves any conflicting existing files to `*.backup` instead of failing. To roll back, `darwin-rebuild --rollback` (or restore the `*.backup` files).

## For other users — rolling your own configurations

The flake exposes shareable module bundles. You import the bundle that matches your platform and supply your own `home.username` / `home.homeDirectory` / hostname / username.

### `flake.nix` for a macOS user

```nix
{
  description = "my nix-ide config — macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/v1.18.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, ... }:
    let
      system = "aarch64-darwin";  # or "x86_64-darwin"
      username = "alice";
    in {
      darwinConfigurations.alice-mac = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          inputs.nix-ide.darwinModules.default
          {
            # Tell nix-homebrew which user owns `brew` on the host.
            nix-homebrew.user = username;

            # Home-manager needs username + homeDirectory.
            home-manager.users.${username} = {
              home = {
                inherit username;
                homeDirectory = "/Users/${username}";
                stateVersion = "24.11";
              };
            };

            # Any nix-darwin-level overrides go here (hostname, etc.).
            networking.hostName = "alice-mac";

            # Override `git.userEmail` etc. here — the bundle sets
            # placeholder `mkDefault` values.
            home-manager.users.${username}.programs.git = {
              userName = "Alice Example";
              userEmail = "alice@example.com";
            };
          }
        ];
      };
    };
}
```

### `flake.nix` for a Linux user

```nix
{
  description = "my nix-ide config — Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/v1.18.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";  # or "aarch64-linux"
      username = "alice";
    in {
      nixosConfigurations.alice-linux = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.nix-ide.nixosModules.default
          {
            # The user account MUST exist before home-manager activates.
            users.users.${username} = {
              isNormalUser = true;
              extraGroups = [ "wheel" "docker" ];
              shell = nixpkgs.legacyPackages.${system}.zsh;
            };

            home-manager.users.${username} = {
              home = {
                inherit username;
                homeDirectory = "/home/${username}";
                stateVersion = "24.11";
              };
              programs.git = {
                userName = "Alice Example";
                userEmail = "alice@example.com";
              };
            };

            networking.hostName = "alice-linux";
          }
        ];
      };
    };
}
```

### A minimal `homeConfigurations`-only consumer (no nix-darwin, no NixOS)

If you don't want a full system module and are happy running `home-manager switch` yourself:

```nix
{
  description = "my nix-ide config — home-manager only";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/v1.18.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = { nixpkgs, home-manager, nix-ide, herdr, opencode, ... }:
    let
    system = "x86_64-darwin";  # or your system
    username = "alice";
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [
        nix-ide.homeModules.default
        { home = { inherit username;
                   homeDirectory = "/Users/${username}";
                   stateVersion = "24.11"; }; }
      ];
      extraSpecialArgs = { inherit herdr opencode; };
    };
  };
}
```

Run `nix run home-manager/release-24.11 -- switch --flake .#alice -b backup`. The HM-only path skips Colima, the casks, native Docker — those land via the nix-darwin / NixOS modules.

## Phase status

All phases shipped. Ticked = port complete.

- [x] **Phase 1 — zsh + runtime deps**: `.zshrc` (history, options, initExtra, aliases), fzf, zoxide, starship (Tokyo Night palette transcribed to `programs.starship.settings`), banner, and the binaries zsh directly invokes at startup (`eza`, `fd`, `bat`, `git-delta`).
- [x] **Phase 2 — git + delta + git TUIs**: `programs.git.delta` (Tokyo Night options), `gh`, `glab`, `programs.lazygit.settings` (Tokyo Night Moon colors), `programs.lazydocker.settings`. Dropped the redundant macOS `~/Library/Application Support/{lazygit,lazydocker}/` symlinks (XDG-first makes them no-ops).
- [x] **Phase 3 — nvim (AstroNvim)**: the whole `~/dotfiles/nvim/.config/nvim/` tree vendored into `files/nvim/` and deployed via `home.file.".config/nvim".source`. `neovim`, `nodejs`, `ripgrep`, `cmake` shipped to `home.packages`. Lazy.nvim stays in charge of plugins — first `nvim` launch downloads them (~30s, same UX as the dotfiles repo).
- [x] **Phase 4 — system tooling**: `programs.bat` + Tokyo Night tmTheme + `bat cache --build` activation, `btop` (config + theme via `home.file`), `programs.htop` (color scheme 6), Ghostty config via `home.file`, `herdr` (vendored upstream `github:ogulcancelik/herdr/v0.7.5`), `tree`/`jq`/`yq`/`gh`, plus `glow` (markdown renderer), `bandwhich` (per-process bandwidth TUI; needs `sudo` on macOS for live capture), `dust` (du + tree, Rust), `hunk` (review-first terminal diff viewer, vendored upstream `github:modem-dev/hunk/v0.17.3` — not in `nixpkgs-26.05-darwin` at our pin, so vendored rather than holding the flake back on unstable).
- [x] **Phase 5 — k8s**: `kubectl`, `kubernetes-helm` (the `helm` CLI; nixpkgs' `helm` attribute is unrelated), `k9s`. No per-tool config to port (the dotfiles repo has none).
- [ ] **Phase 6 — Docker runtime**: deferred to Phase 8. The HM bundle doesn't ship a Docker runtime — that's system territory.
- [x] **Phase 7 — AI tooling**: `opencode` vendored upstream (`github:anomalyco/opencode/v1.18.4`), config directory ported minus the runtime drag-in (`node_modules`, `package.json`, `package-lock.json`, `.gitignore`). **OpenSpec dropped entirely** — removed the `OPENSPEC_TELEMETRY=0` env-var the dotfiles repo carried; users wire their own spec-driven workflow tools.
- [x] **Phase 8 — system modules**: `darwinModules.default` (nix-darwin + nix-homebrew + Docker activation script + HM wired in importing `homeModules.default`), `nixosModules.default` (native Docker + Nerd Font via `fonts.fonts` + `_1password-cli` + HM wired in). The flake exports NO `homeConfigurations` / `darwinConfigurations` / `nixosConfigurations` directly — consumers compose them in their own flake from these modules.

## Layout

```
nix-ide/
├── flake.nix              # inputs + shareable module bundles (no kevin- or username-here)
├── home/                  # `homeModules.default` — shareable home-manager config (Phase 2–7)
│   ├── default.nix        # aggregator: imports all sub-modules, sets stateVersion + global shell integration flags
│   ├── zsh.nix            # programs.zsh (history, aliases, Zinit, initExtra, sessionVariables)
│   ├── starship.nix       # programs.starship.settings (full Tokyo Night palette)
│   ├── fzf.nix            # programs.fzf (Tokyo Night defaultOptions)
│   ├── zoxide.nix         # programs.zoxide (zsh integration)
│   ├── git.nix            # programs.git + delta Tokyo Night options
│   ├── lazygit.nix        # programs.lazygit.settings (Tokyo Night Moon colors)
│   ├── lazydocker.nix     # programs.lazydocker.settings
│   ├── nvim.nix           # home.file.".config/nvim".source + neovim/node/ripgrep/cmake
│   ├── bat.nix            # programs.bat + custom tmTheme + bat cache build activation
│   ├── btop.nix           # home.packages.btop + home.file btop config + themes
│   ├── htop.nix           # programs.htop
│   ├── ghostty.nix        # home.file ghostty config + Linux `pkgs.ghostty` binary
│   ├── herdr.nix          # vendored herdr upstream + herdr config
│   ├── opencode.nix       # vendored opencode upstream + opencode config dir
│   ├── packages.nix       # raw binaries (eza, fd, bat, delta, gh, glab, tree, jq, yq, k8s)
│   └── files.nix          # home.file for the banner
├── darwin/                # `darwinModules.default` — shared nix-darwin config (Phase 8)
│   ├── default.nix        # home-manager + nix-homebrew + casks (ghostty, 1password-cli, Nerd Font) + Colima
│   └── docker.nix         # ~/.docker/config.json cliPluginsExtraDirs activation script + self-heal
├── nixos/                 # `nixosModules.default` — shared NixOS config (Phase 8)
│   └── default.nix        # native Docker + Nerd Font + _1password-cli + home-manager wired in
├── files/
│   ├── ainative-banner.sh # verbatim copy of dotfiles/zsh/.config/ainative/banner.sh
│   ├── nvim/              # AstroNvim config (verbatim vendored tree, 24 files)
│   ├── bat-themes/        # tokyonight_moon.tmTheme
│   ├── btop/              # btop.conf + themes/tokyo-night-moon.theme
│   ├── herdr/             # herdr config.toml
│   ├── opencode/          # opencode.jsonc, tui.json, themes/, agents/, skills/
│   └── ghostty-config     # 6-line Ghostty config
└── dev.sh                 # throwaway-HOME dev-mode entry point (sandbox)
```

## Verification

### Quick (in dev mode)

After `./dev.sh`:

1. Banner renders ("AI NATIVE" ASCII, version line) — Zinit clones on first run (~10-30s).
2. Prompt renders in Tokyo Night colors via `programs.starship.settings`.
3. `z <dir>` works (zoxide).
4. `Ctrl-T` / `Alt-C` fzf widgets work with Tokyo Night palette.
5. `eza` aliases (`ls`, `ll`, `la`, `lt`) render with icons.
6. `cat`/`less` use bat (with `BAT_THEME=tokyonight_moon`).
7. `diff` uses git-delta.
8. `git config --get-regexp 'delta\.'` shows the Tokyo Night color options.
9. `lazygit --version && lazydocker --version` resolve.
10. `nvim --headless '+Lazy! sync' +qa'` runs (plugins install the first time, ~30s).
11. `btop --version`, `htop --version`, `herdr --version`, `opencode --version` resolve.
12. `kubectl version --client`, `helm version`, `k9s version` resolve.
13. `ls ~/.config/opencode/agents` shows the two SDD agent files; `opencode auth` is a manual post-step.
14. `exit` returns you to your real shell — `ls -l ~/.zshrc` should show the dotfiles symlink unchanged.

### Full (after `darwin-rebuild switch` on a real Mac)

1. `open -a Ghostty` launches the terminal (cask landed).
2. `op --version` works (1password-cli cask landed).
3. `colima start; docker ps; docker compose version` (Colima + Docker compose + the `cliPluginsExtraDirs` activation).
4. `opencode auth` interactive (auth tokens stored in `~/.local/share/opencode/`, outside the repo).
5. Neovim's Nerd Font icons render in Ghostty (Meslo Nerd Font cask landed).

Linux equivalent via `nixos-rebuild switch --flake .#<hostname>`, plus `docker ps`, `fc-list | grep -i meslo` for the Nerd Font.

## Secret hygiene

A user-config repo lives one careless commit away from leaking credentials. The standing rules, ported from the dotfiles repo:

- **Never put API keys or tokens in Nix config.** Reference environment variables instead, and set them yourself via your password manager CLI at shell startup — e.g. `export NEBIUS_API_KEY="$(op read 'op://vault/nebius/api_key')"` in a file you own (outside the repo). The key is fetched at shell startup, never touches the repo.
- **The repo's `.zshrc` ships no `op read` calls.** Users wire their own secret-fetch lines in `home-manager.users.<name>.programs.zsh.initExtra` (or anywhere else in their flake). The bundle is secret-agnostic.
- **Never blanket-add.** Always `git add -p` or add specific files. A `.gitignore` that excludes `*.token`, `*secret*`, `*key*`, `auth.json` patterns is cheap insurance.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember anything ever committed stays in history — scrub with `git filter-repo` and rotate the key.
- **OpenCode auth lives outside the repo.** Tokens are stored in `~/.local/share/opencode/` — not tracked.

## OpenSpec

Dropped entirely in this migration. The dotfiles repo shipped OpenSpec + telemetry opt-out; this repo removes both. Users who want spec-driven workflow tooling install it per-project themselves.

## License

Personal config — take whatever's useful.