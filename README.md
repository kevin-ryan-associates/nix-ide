# nix-ide

Nix-managed developer environment — a port of [`~/dotfiles`](https://github.com/kevin-ryan-associates/dotfiles) from GNU Stow + Homebrew to a Nix flake + home-manager. **Full replacement**: once parity is reached, `~/dotfiles` is archived and this repo is the single source of truth for the user environment.

## What this repo does

- Defines a single home-manager configuration (`#kevin`) keyed on the host's current system, so `home-manager switch --flake .#kevin` works on macOS (aarch64/x86_64) and Linux (aarch64/x86_64) without per-arch outputs.
- Uses native `programs.*` home-manager modules wherever HM models the tool cleanly (zsh, fzf, zoxide, starship); falls back to `home.file` for raw user-data that has no module (the ainative banner).
- Keeps **Zinit** as the zsh plugin manager (clone-on-first-run preserved verbatim in `programs.zsh.initExtra`). Plugin lazy-loading UX is unchanged from the dotfiles repo.

## Prerequisites

1. **Nix** with flakes enabled. On Intel macOS use the [official Nix installer](https://nixos.org/download.html#nix-install-macos) (Determinate dropped Intel Mac support November 2025). On Apple Silicon or Linux, either installer works. Enable flakes via `~/.config/nix/nix.conf`:

   ```bash
   mkdir -p ~/.config/nix
   printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf
   ```

2. **home-manager** is *not* required as a separate install — the flake exposes it via `nix run`.

## Dev mode (test without touching your shell)

`./dev.sh` builds the activation package, lays out the HM-managed files into a throwaway `mktemp` HOME, and `exec`s an interactive login zsh in that sandbox. Type `exit` or Ctrl-D to leave. Your real `~/.zshrc` is untouched.

```bash
./dev.sh
# inside the sandbox:
starship --version    # Nix-installed 1.25.1
zsh --version         # Nix-installed 5.9.1
eza --version         # Nix 0.72.0
# ...banner renders, Tokyo Night prompt renders
exit
```

## Activation (when ready to commit to the port)

When you've verified the port in dev mode and want to make it live, replace your shell with the HM-managed one (pick the attribute matching your host):

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
├── flake.nix              # inputs + per-system homeConfigurations.kevin-${system}
├── home/
│   ├── default.nix        # aggregator; sets username, homeDirectory, stateVersion
│   ├── zsh.nix            # programs.zsh (history, aliases, Zinit, initExtra)
│   ├── starship.nix       # programs.starship.settings (full Tokyo Night palette)
│   ├── fzf.nix            # programs.fzf (Tokyo Night defaultOptions)
│   ├── zoxide.nix         # programs.zoxide (zsh integration)
│   ├── packages.nix       # raw binary packages (eza, fd, bat, delta)
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