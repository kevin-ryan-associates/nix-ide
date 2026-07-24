# nix-ide

Nix-managed developer environment — a port of [`~/dotfiles`](https://github.com/kevin-ryan-associates/dotfiles) from GNU Stow + Homebrew to a Nix flake + home-manager. **Full replacement**: once parity is reached, `~/dotfiles` is archived and this repo is the single source of truth for the user environment.

## What this repo does

- Publishes **shareable module bundles** consumers compose in their own flake:
  - `homeModules.default` — the home-manager config (zsh, starship, fzf, zoxide, git/delta, lazygit, lazydocker, bat, btop, htop, ghostty config, herdr, opencode, hunk, nvim, k8s binaries, jq/yq/tree, gh/glab).
  - `darwinModules.default` — nix-darwin module: Homebrew casks (Ghostty, Nerd Font), Colima, the Docker `cliPluginsExtraDirs` activation, and `home-manager` wired in.
  - `nixosModules.default` — NixOS module: native Docker, Nerd Font via `fonts.packages`, system zsh, and `home-manager` wired in.
  - `devShells.${system}.default` — quick tool check via `nix develop .`, no `$HOME` writes.
- Publishes the **instantiation layer** on top of the HM bundle:
  - `lib.mkHome { username, system, homeDirectory?, extraModules? }` — a builder that wires `homeModules.default` into a ready-to-switch `home-manager.lib.homeManagerConfiguration` for the caller's identity. `homeDirectory` defaults to the platform convention (`/Users/<name>` on macOS, `/home/<name>` on Linux); `extraModules` carries per-user overrides (git identity, secret wiring, ...).
  - `homeConfigurations."example@x86_64-linux"` — a working template built by `lib.mkHome` against a placeholder identity. Copy and adapt it in your own flake; it's not meant to be activated as-is.

  All three bundles are **self-contained**: the vendored upstream input (hunk), home-manager, nix-darwin and nix-homebrew are closed over from this flake's own inputs. Consumers declare none of them and pass no `specialArgs` / `extraSpecialArgs`.
- Uses native `programs.*` home-manager modules wherever HM models the tool cleanly (zsh, fzf, zoxide, starship, git, bat, htop, lazygit, lazydocker). Falls back to `home.file` for raw user-data that has no module (the ainative banner, the btop themes directory, the herdr config, the AstroNvim tree, the opencode config directory).
- Keeps **Zinit** as the zsh plugin manager (clone-on-first-run preserved verbatim in `programs.zsh.initContent`). Plugin lazy-loading UX is unchanged from the dotfiles repo.
- Uses [AstroNvim](https://astronvim.com/) for Neovim, vendored into `files/nvim/` and deployed via `home.file`. Lazy.nvim is the plugin manager and stays in charge — plugins install on first `nvim` launch (~30s).
- Installs `herdr` (v0.7.5) and `opencode` (v1.18.4) from **prebuilt upstream release binaries** — hash-verified `fetchurl` from GitHub Releases, installed straight to `$out/bin` via `pkgs.stdenv.mkDerivation` (with `autoPatchelfHook` for opencode's glibc Linux builds). `hunk` (v0.17.3) remains a **vendored** upstream flake package, keeping vendor hashes upstream's problem.
- **Why prebuilt binaries for herdr/opencode:** source builds of Bun/JS-toolchain binaries are unreliable in virtualized environments (Parallels/UTM/VMware VMs, some CI runners) — Bun's CPU feature detection mismatches the hypervisor's virtual CPU and the compiled binary dies with SIGSEGV on its smoke test (`opencode --version`). Prebuilt releases are compiled on upstream CI's bare metal, so they're the default for portability; opencode additionally uses the `-baseline` x64 builds (no AVX2-era instruction-set assumptions) so the embedded Bun runtime stays VM-safe at runtime too.

## Prerequisites

1. **Nix** with flakes enabled. On Intel macOS use the [official Nix installer](https://nixos.org/download.html#nix-install-macos) (Determinate dropped Intel Mac support November 2025). On Apple Silicon or Linux, either installer works. Enable flakes via `~/.config/nix/nix.conf`:

   ```bash
   mkdir -p ~/.config/nix
   printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf
   ```

2. **home-manager**, **nix-darwin**, **nix-homebrew** are NOT required as separate installs — they come from this flake's inputs, closed over by the bundles. A consumer flake only declares `nixpkgs`, `nix-ide`, and (macOS) `nix-darwin` / (HM-only) `home-manager`.

3. **On macOS only:** `nix-homebrew` activates Homebrew declaratively on `darwin-rebuild switch`. The first activation prompts the user once for `sudo` (nix-homebrew's documented behaviour). After that, Homebrew is along for the ride and the casks (Ghostty, Nerd Font) deploy automatically.

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
nix run github:nix-darwin/nix-darwin/nix-darwin-26.05 -- switch --flake ./my-flake#<your-hostname> -b backup
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
      # Release branch matching our nixpkgs — nix-darwin asserts the
      # correspondence (26.05 vs 26.05). Branch list: nix-darwin-YY.MM.
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = { nix-darwin, nix-ide, ... }:
    let
      system = "aarch64-darwin";  # or "x86_64-darwin"
      username = "alice";
    in {
      darwinConfigurations.alice-mac = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          nix-ide.darwinModules.default
          {
            # Required by nix-darwin itself (asserted). stateVersion 7 is
            # current at nix-darwin master; pick the release you installed
            # with and don't bump it casually.
            system.stateVersion = 7;
            # Required because the bundle enables Homebrew. Also feeds
            # `nix-homebrew.user`.
            system.primaryUser = username;

            # HM's darwin module reads home.username/homeDirectory defaults
            # from users.users.<name>, so the account must be declared.
            # knownUsers marks it pre-existing — nix-darwin won't create it.
            # uid 501 is the first regular account on a default macOS install;
            # check yours with `id -u`.
            users.knownUsers = [ username ];
            users.users.${username} = {
              uid = 501;
              home = "/Users/${username}";
            };

            # Home-manager needs username + homeDirectory per user. The
            # bundle's sharedModules apply the whole HM config to every
            # user declared here.
            home-manager.users.${username} = {
              home = {
                inherit username;
                homeDirectory = "/Users/${username}";
                stateVersion = "24.11";
              };

              # Override git identity — the bundle sets placeholder
              # `mkDefault` values.
              programs.git.settings.user = {
                name = "Alice Example";
                email = "alice@example.com";
              };
            };

            networking.hostName = "alice-mac";
          }
        ];
      };
    };
}
```

Note what's NOT there: no `specialArgs`, no `home-manager` / `nix-homebrew` / `hunk` inputs — the bundle closes over nix-ide's own.

### `flake.nix` for a Linux user

```nix
{
  description = "my nix-ide config — Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = { nixpkgs, nix-ide, ... }:
    let
      system = "x86_64-linux";  # or "aarch64-linux"
      username = "alice";
    in {
      nixosConfigurations.alice-linux = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nix-ide.nixosModules.default
          {
            # Required by NixOS itself.
            system.stateVersion = "26.05";

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
              programs.git.settings.user = {
                name = "Alice Example";
                email = "alice@example.com";
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

If you don't want a full system module and are happy running `home-manager switch` yourself, call the `lib.mkHome` builder. It takes your identity/system and returns a ready-to-switch `home-manager.lib.homeManagerConfiguration` with `homeModules.default` already wired in:

```nix
{
  description = "my nix-ide config — home-manager only";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = { nix-ide, ... }: {
    homeConfigurations."alice@x86_64-linux" = nix-ide.lib.mkHome {
      username = "alice";
      system = "x86_64-linux";              # or aarch64-darwin, x86_64-darwin, aarch64-linux
      homeDirectory = "/home/alice";        # optional — defaults to /home/<name> or /Users/<name>

      # Optional per-user overrides, applied after the bundle:
      extraModules = [
        {
          programs.git.settings.user = {
            name = "Alice Example";
            email = "alice@example.com";
          };
        }
      ];
    };
  };
}
```

Note what's NOT there: no `pkgs`, no module list, no `extraSpecialArgs` — `mkHome` closes over nix-ide's own nixpkgs and the bundle injects the vendored upstream flake (hunk) itself via `_module.args`.

This repo's own `homeConfigurations."example@x86_64-linux"` output is exactly this call against a placeholder identity — a working template to copy from, not an activation target.

Run `nix run home-manager/release-26.05 -- switch --flake .#alice@x86_64-linux -b backup`. The HM-only path skips Colima, the casks, native Docker — those land via the nix-darwin / NixOS modules.

If you need something `mkHome` doesn't model, the raw `home-manager.lib.homeManagerConfiguration { pkgs = ...; modules = [ nix-ide.homeModules.default { home = { ... }; } ]; }` pattern still works — `homeModules.default` remains the underlying public surface.

## Phase status

Ticked = port complete. (Phase 6 was folded into Phase 8 — a Docker runtime is system territory, not HM.)

- [x] **Phase 1 — zsh + runtime deps**: `.zshrc` (history, options, initContent, aliases), fzf, zoxide, starship (Tokyo Night palette transcribed to `programs.starship.settings`), banner, and the binaries zsh directly invokes at startup (`eza`, `fd`, `bat`, `git-delta`).
- [x] **Phase 2 — git + delta + git TUIs**: `programs.git.delta` (Tokyo Night options), `gh`, `glab`, `programs.lazygit.settings` (Tokyo Night Moon colors), `programs.lazydocker.settings`. Dropped the redundant macOS `~/Library/Application Support/{lazygit,lazydocker}/` symlinks (XDG-first makes them no-ops).
- [x] **Phase 3 — nvim (AstroNvim)**: the whole `~/dotfiles/nvim/.config/nvim/` tree vendored into `files/nvim/` and deployed via `home.file.".config/nvim".source`. `neovim`, `nodejs`, `ripgrep`, `cmake` shipped to `home.packages`. Lazy.nvim stays in charge of plugins — first `nvim` launch downloads them (~30s, same UX as the dotfiles repo).
- [x] **Phase 4 — system tooling**: `programs.bat` + Tokyo Night tmTheme + `bat cache --build` activation, `btop` (config + theme via `home.file`), `programs.htop` (color scheme 6), Ghostty config via `home.file`, `herdr` (prebuilt v0.7.5 binary from GitHub Releases, hash-verified `fetchurl`), `tree`/`jq`/`yq`/`gh`, plus `glow` (markdown renderer), `bandwhich` (per-process bandwidth TUI; needs `sudo` on macOS for live capture), `dust` (du + tree, Rust), `hunk` (review-first terminal diff viewer, vendored upstream `github:modem-dev/hunk/v0.17.3` — not in `nixpkgs-26.05-darwin` at our pin, so vendored rather than holding the flake back on unstable).
- [x] **Phase 5 — k8s**: `kubectl`, `kubernetes-helm` (the `helm` CLI; nixpkgs' `helm` attribute is unrelated), `k9s`. No per-tool config to port (the dotfiles repo has none).
- [x] **Phase 6 — Docker runtime**: folded into Phase 8. The HM bundle doesn't ship a Docker runtime — that's system territory.
- [x] **Phase 7 — AI tooling**: `opencode` as a prebuilt v1.18.4 release binary (hash-verified `fetchurl` from GitHub Releases; `-baseline` x64 variants + `autoPatchelfHook` on Linux — Bun source builds SIGSEGV under virtualized CPUs), config directory ported minus the runtime drag-in (`node_modules`, `package.json`, `package-lock.json`, `.gitignore`). **OpenSpec dropped entirely** — removed the `OPENSPEC_TELEMETRY=0` env-var the dotfiles repo carried; users wire their own spec-driven workflow tools.
- [x] **Phase 8 — system modules**: `darwinModules.default` (nix-darwin + nix-homebrew + Docker activation + HM wired in via `home-manager.sharedModules`), `nixosModules.default` (native Docker + Nerd Font via `fonts.packages` + system zsh + HM wired in). Both bundles close over this flake's inputs — consumers pass no `specialArgs`. The only `homeConfigurations` the flake exports is the placeholder `example@x86_64-linux` template built by `lib.mkHome`; real `homeConfigurations` / `darwinConfigurations` / `nixosConfigurations` are composed by consumers in their own flake from these modules.

## Layout

```
nix-ide/
├── flake.nix              # inputs + shareable module bundles + lib.mkHome builder + example template (no real identity here)
├── home/                  # `homeModules.default` — shareable home-manager config (Phase 2–7)
│   ├── default.nix        # aggregator: imports all sub-modules, sets stateVersion + global shell integration flags
│   ├── zsh.nix            # programs.zsh (history, aliases, Zinit, initContent, sessionVariables)
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
│   ├── herdr.nix          # prebuilt herdr binary (fetchurl) + herdr config
│   ├── opencode.nix       # prebuilt opencode binary (fetchurl) + opencode config dir
│   ├── packages.nix       # raw binaries (eza, fd, delta, gh, glab, tree, jq, yq, k8s)
│   └── files.nix          # home.file for the banner
├── darwin/                # `darwinModules.default` — shared nix-darwin config (Phase 8)
│   ├── default.nix        # home-manager + nix-homebrew + casks (ghostty, Nerd Font) + Colima
│   └── docker.nix         # ~/.docker/config.json cliPluginsExtraDirs (home.activation) + self-heal (system)
├── nixos/                 # `nixosModules.default` — shared NixOS config (Phase 8)
│   └── default.nix        # native Docker + Nerd Font + system zsh + home-manager wired in
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
2. `colima start; docker ps; docker compose version` (Colima + Docker compose + the `cliPluginsExtraDirs` activation).
3. `opencode auth` interactive (auth tokens stored in `~/.local/share/opencode/`, outside the repo).
4. Neovim's Nerd Font icons render in Ghostty (Meslo Nerd Font cask landed).

Linux equivalent via `nixos-rebuild switch --flake .#<hostname>`, plus `docker ps`, `fc-list | grep -i meslo` for the Nerd Font.

## Secret hygiene

A user-config repo lives one careless commit away from leaking credentials. The standing rules, ported from the dotfiles repo:

- **Never put API keys or tokens in Nix config.** Reference environment variables instead, and set them yourself via your password manager CLI at shell startup — e.g. `export NEBIUS_API_KEY="$(op read 'op://vault/nebius/api_key')"` in a file you own (outside the repo). The key is fetched at shell startup, never touches the repo.
- **The repo's `.zshrc` ships no `op read` calls.** Users wire their own secret-fetch lines in `home-manager.users.<name>.programs.zsh.initContent` (or anywhere else in their flake). The bundle is secret-agnostic.
- **Never blanket-add.** Always `git add -p` or add specific files. A `.gitignore` that excludes `*.token`, `*secret*`, `*key*`, `auth.json` patterns is cheap insurance.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember anything ever committed stays in history — scrub with `git filter-repo` and rotate the key.
- **OpenCode auth lives outside the repo.** Tokens are stored in `~/.local/share/opencode/` — not tracked.

## OpenSpec

Dropped entirely in this migration. The dotfiles repo shipped OpenSpec + telemetry opt-out; this repo removes both. Users who want spec-driven workflow tooling install it per-project themselves.

## License

Personal config — take whatever's useful.