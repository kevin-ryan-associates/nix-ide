# nix-ide

Nix-managed developer environment — a port of [`~/dotfiles`](https://github.com/kevin-ryan-associates/dotfiles) from GNU Stow + Homebrew to a Nix flake + home-manager. **Full replacement**: once parity is reached, `~/dotfiles` is archived and this repo is the single source of truth for the user environment.

## What this repo does

- Defines per-system home-manager configurations (`homeConfigurations.kevin-${system}`) plus a shareable `homeModules.default` so other users can import the tool config with their own `home.username`.
- Uses native `programs.*` home-manager modules wherever HM models the tool cleanly (zsh, fzf, zoxide, starship); falls back to `home.file` for raw user-data that has no module (the ainative banner).
- Keeps **Zinit** as the zsh plugin manager (clone-on-first-run preserved verbatim in `programs.zsh.initExtra`). Plugin lazy-loading UX is unchanged from the dotfiles repo.

## Prerequisites

1. **Nix** with flakes enabled. On Intel macOS use the [official Nix installer](https://nixos.org/download.html#nix-install-macos) (Determinate dropped Intel Mac support November 2025). On Apple Silicon or Linux, either installer works. Enable flakes via `~/.config/nix/nix.conf`:

   ```bash
   mkdir -p ~/.config/nix
   printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf
   ```

2. **home-manager** is *not* required as a separate install — the flake exposes it via `nix run`.

## Three ways to try this repo

### 1. `nix develop` — quick tool check, no setup

Drops into a bash shell with the Phase 1 tools on PATH (zsh, starship, fzf, zoxide, eza, bat, fd, delta). No home-manager, no `$HOME` writes — the simplest path for someone to try the tool inventory.

```bash
# From GitHub (anyone, no checkout needed):
nix develop github:kevin-ryan-associates/nix-ide

# From a local clone:
git clone git@github.com:kevin-ryan-associates/nix-ide.git
cd nix-ide && nix develop .
```

Inside the dev shell, `starship --version` / `eza --icons` / etc. work. Exit with Ctrl-D to return to your normal shell.

### 2. `./dev.sh` — full port sandbox, still no `$HOME` writes

Builds the home-manager activation package (without switching), lays out the HM-managed files into a throwaway `mktemp` HOME, and `exec`s an interactive login zsh in that sandbox. Banner renders, Tokyo Night prompt renders, aliases work. Your real `~/.zshrc` is untouched.

```bash
git clone git@github.com:kevin-ryan-associates/nix-ide.git
cd nix-ide && ./dev.sh
# inside the sandbox:
starship --version    # Nix-installed 1.25.1
zsh --version         # Nix-installed 5.9.1
eza --version         # Nix 0.72.0
# ...banner renders, Tokyo Night prompt renders
exit
```

The maintainer's `home.username` is baked into the build (`kevinryan`), so the sandbox's `[username]` module will show "kevinryan" — but `home.homeDirectory` is overridden by `dev.sh` so file writes stay in the sandbox. Works for anyone.

### 3. `home-manager switch` — permanent activation (advanced)

When you've verified the port in dev mode and want to make it live, replace your shell with the HM-managed one. **Caveat: the maintainer's `homeConfigurations.kevin-${system}` is hardcoded to `/Users/kevinryan` or `/home/kevinryan` — it will not work for you directly.** Use the shareable module path in "For other users" below.

For the maintainer (pick the attribute matching your host):

```bash
nix run home-manager/release-24.11 -- switch --flake .#kevin-aarch64-darwin -b backup   # macOS Apple Silicon
nix run home-manager/release-24.11 -- switch --flake .#kevin-x86_64-darwin -b backup     # macOS Intel
nix run home-manager/release-24.11 -- switch --flake .#kevin-aarch64-linux -b backup    # Linux aarch64
nix run home-manager/release-24.11 -- switch --flake .#kevin-x86_64-linux -b backup     # Linux x86_64
```

`-b backup` moves any conflicting existing files (e.g. `~/.zshrc`, `~/.zprofile`) to `*.backup` instead of failing. Subsequent activations can use the activated `home-manager` binary directly:

```bash
home-manager switch --flake .#kevin-x86_64-darwin -b backup
```

To roll back to your previous shell, `home-manager uninstall` and restore the `.backup` files.

## For other users — rolling your own `homeConfigurations`

The flake exports `homeModules.default` — a home-manager module containing all the zsh/starship/fzf/zoxide/banner config from `home/` WITHOUT setting `home.username`/`home.homeDirectory`. You import it in your own flake and provide those values yourself.

Create a `flake.nix` in e.g. `~/my-nix-ide/`:

```nix
{
  description = "my nix-ide config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ide.url = "github:kevin-ryan-associates/nix-ide";
  };

  outputs = { self, nixpkgs, home-manager, nix-ide, ... }:
    let
      system = "x86_64-darwin";  # change to your system
      pkgs = nixpkgs.legacyPackages.${system};
      username = "alice";        # change to your username
      homeDirectory = "/Users/${username}";  # /home/${username} on Linux
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-ide.homeModules.default
          { home = { inherit username homeDirectory; }; }
        ];
      };
    };
}
```

Then:

```bash
nix run home-manager/release-24.11 -- switch --flake .#alice -b backup
```

You get the full nix-ide config (zsh, Tokyo Night prompt, banner, fzf, zoxide, eza/bat/delta) deployed to your own `$HOME`. The banner's ASCII art and "AI NATIVE" branding stay (it's a static file shipped via `home.file`); the starship `[username]` module shows your OS username, not "kevinryan".

## Phase status

- [x] **Phase 1 — zsh + runtime deps**: `.zshrc` (history, options, initExtra, aliases), fzf, zoxide, starship (Tokyo Night palette transcribed to `programs.starship.settings`), banner, plus the binaries zsh directly invokes at startup (`eza`, `fd`, `bat`, `git-delta`).
- [ ] **Phase 2 — git + delta**: `~/.config/git/config` (delta Tokyo Night colors), `gh`, `glab`, `lazygit`, `lazydocker` configs.
- [ ] **Phase 3 — nvim**: AstroNvim config subtree, neovim, node, npm, ripgrep, cmake, Nerd Font.
- [ ] **Phase 4 — system tooling**: bat theme, btop, htop, herdr, tree, jq, yq, `1password-cli`, Ghostty.
- [ ] **Phase 5 — k8s**: kubectl, helm, k9s.
- [ ] **Phase 6 — Docker runtime**: native Docker on Linux; Colima on macOS.
- [ ] **Phase 7 — AI tooling**: opencode (config + agents + theme), openspec.
- [ ] **Phase 8 — system modules**: `darwinConfigurations` (nix-darwin: Colima cask, Nerd Font cask, Ghostty cask, chsh) and `nixosConfigurations` (native Docker, fontconfig).

## Layout

```
nix-ide/
├── flake.nix              # inputs + outputs: homeConfigurations.kevin-${system}, homeModules.default, devShells.${system}.default
├── home/                  # also exported as `homeModules.default` — the shareable module bundle
│   ├── default.nix        # aggregator: imports all sub-modules, sets stateVersion + global shell integration flags
│   ├── zsh.nix            # programs.zsh (history, aliases, Zinit, initExtra)
│   ├── starship.nix       # programs.starship.settings (full Tokyo Night palette)
│   ├── fzf.nix            # programs.fzf (Tokyo Night defaultOptions)
│   ├── zoxide.nix         # programs.zoxide (zsh integration)
│   ├── packages.nix        # raw binary packages (eza, fd, bat, delta)
│   └── files.nix          # home.file for the banner
├── files/
│   └── ainative-banner.sh # verbatim copy of dotfiles/zsh/.config/ainative/banner.sh
└── dev.sh                 # throwaway-HOME dev-mode entry point
```

## Verification (in dev mode)

After `./dev.sh`:

1. Banner renders ("AI NATIVE" ASCII, version line) — Zinit clones on first run (~10-30s).
2. Prompt renders in Tokyo Night colors via `programs.starship.settings`.
3. `z <dir>` works (zoxide).
4. `Ctrl-T` / `Alt-C` fzf widgets work with Tokyo Night palette.
5. `eza` aliases (`ls`, `ll`, `la`, `lt`) render with icons.
6. `cat`/`less` use bat (with `BAT_THEME=tokyonight_moon`).
7. `diff` uses git-delta.
8. `starship print-config` matches the source toml's intent (palette keys + values identical to `~/dotfiles/starship/.config/starship.toml`; HM reformats whitespace).
9. `exit` returns you to your real shell — `ls -l ~/.zshrc` should show the dotfiles symlink unchanged.

## License

Personal config — take whatever's useful.