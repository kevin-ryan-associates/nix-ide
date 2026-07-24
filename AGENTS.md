# AGENTS.md

Guidance for AI coding agents working in this repository. Read this before making any change.

## What this repo is

A Nix flake + home-manager port of the [`~/dotfiles`](https://github.com/kevin-ryan-associates/dotfiles) repo. Its purpose is repeatable development workflow across different machine installations. Three mechanisms carry that purpose:

- **Shareable module bundles** publish via the flake's outputs: `homeModules.default`, `darwinModules.default`, `nixosModules.default`. Consumers compose their own `homeConfigurations` / `darwinConfigurations` / `nixosConfigurations` in their own flake — they supply username, homeDirectory, hostname, and per-user overrides (git user.name/email, etc.).
- **`lib.mkHome { username, system, homeDirectory?, extraModules? }`** is the instantiation layer for the HM bundle: it returns a ready-to-switch `home-manager.lib.homeManagerConfiguration` importing `homeModules.default`, with `homeDirectory` defaulting to the platform convention and `extraModules` carrying per-user overrides. `homeConfigurations."example@x86_64-linux"` is the one published example entry — a placeholder-identity template for consumers to copy, NOT an activation target. Aside from that placeholder, the repo contains NO username, NO hostname, NO homeDirectory hard-coded anywhere.
- **`dev.sh`** is the dev-mode sandbox entrypoint. It uses a private `legacyPackages.${system}.homeConfigurations.sandbox` attribute the flake publishes exclusively for it. Builds the activation package (no `switch`), lays out the HM-managed files into a throwaway `mktemp` HOME, `exec`s an interactive login zsh. Exit returns you to your real shell.
- **`flake.nix`** is the public surface. It is the only entry point. There are no install scripts (`bootstrap.sh`, `install-mac.sh`, `install-linux.sh`, `brew-packages.sh` from the dotfiles repo are explicitly NOT ported — the flake replaces all four).

A machine that has Nix installed and flakes enabled reaches a known-good state by running `darwin-rebuild switch --flake <user-flake>#<hostname>` (macOS) or `nixos-rebuild switch --flake <user-flake>#<hostname>` (Linux), or `nix run home-manager/release-24.11 -- switch --flake <user-flake>#<username> -b backup` (HM-only sandbox). The user writes that `<user-flake>` themselves — see README "For other users" for the canonical example.

## The prime directive

**Every change to machine state must be reproducible by editing a Nix module in this repo and re-running `darwin-rebuild switch` (macOS), `nixos-rebuild switch` (Linux), or `home-manager switch` (HM-only). The fix is always a repo edit; the live effect comes from running the rebuild. Never patch the live machine directly.**

If you are about to type a command that modifies a file outside this repo and that modification is meant to be permanent, stop. Instead:

1. Edit the Nix module (`home/*.nix`, `darwin/*.nix`, `nixos/*.nix`).
2. Run `nix flake check --all-systems` to confirm evaluation is clean.
3. Run `./dev.sh` to exercise the HM activation in a sandbox `mktemp` HOME.
4. If system-level (`darwin/`, `nixos/`): verify `darwin-rebuild switch` / `nixos-rebuild switch` works on the real target (a sandbox can't exercise casks or native Docker).
5. Verify the originally-failing command now works.

Diagnosing on the live machine is fine — `cat`, `ls -l`, `nix flake show`, `nix eval`, `darwin-rebuild dry-activate`, `nixos-rebuild dry-build` are all read-only and encouraged. **Mutating** the live machine outside the rebuild is not.

## Where each kind of change belongs

| Change | Location | Why |
|---|---|---|
| A tool's HM-managed config (zsh, starship, fzf, zoxide, git, bat, htop, lazygit, lazydocker) | `home/<tool>.nix` via the matching `programs.<tool>` module | HM modules give us free binaries + activation hooks; this is the cleanest path |
| A tool's raw config file the HM module doesn't cover (btop themes, ghostty config, herdr config, opencode config directory) | `files/<tool>/` shipped via `home.file` in `home/<tool>.nix` | No HM module for these — `home.file` is the fallback |
| A vendored upstream source flake (hunk) | `inputs.hunk.url` in `flake.nix` and `home/hunk.nix`'s `hunk.packages.${system}.hunk` | Not in nixpkgs at our pin; keeps vendor hashes upstream's problem |
| A prebuilt upstream release binary (herdr, opencode) | `home/<tool>.nix` `stdenv.mkDerivation` + hash-verified `fetchurl` from GitHub Releases (pinned tag URL, per-system sha256 in the module) | Bun-toolchain source builds SIGSEGV under virtualized CPUs (VMs, some CI) — prebuilt is the portable default. No flake input; version + hashes live in the module |
| A macOS Homebrew cask (Ghostty, Nerd Font) | `darwin/default.nix` `homebrew.casks` | Casks touch `/Applications`, `/usr/local`, the TCC db — system territory, not HM |
| A Linux system-level service/package (Docker, fonts, system zsh) | `nixos/default.nix` `virtualisation.docker.enable` / `fonts.packages` / `programs.zsh.enable` | System territory; mirrors macOS casks |
| An architecture-conditional runtime value (e.g. `~/.docker/config.json`'s `cliPluginsExtraDirs`) | `darwin/docker.nix` `home.activation` block (user context) | The value is `brewPrefix`-dependent (`/opt/homebrew` vs `/usr/local`); resolve via `pkgs.stdenv.hostPlatform` so it's still eval-time deterministic, unlike the dotfiles repo's runtime `brew --prefix`. Per-user state must run in HM activation — nix-darwin system activation is root with `HOME=~root` (see "Self-heal convention") |
| Cleanup of stale state from a tool the install explicitly replaces (Docker Desktop symlinks) | `darwin/docker.nix` guarded self-heal block (see convention below) | Old machines with the replaced tool have cruft; fresh machines have none. The block must no-op on fresh machines. |
| Random pre-existing cruft unrelated to a replaced tool | README "Manual cleanup" mention, never an activation script | Not the rebuild's job to clean arbitrary user state |

## Why some state lives in `darwin/` and `nixos/`, not `home/`

The HM bundle (`homeModules.default`) is platform-agnostic. Anything requiring system-level services (casks, native Docker, `fonts.packages`) can't live there. Splitting cleanly keeps the HM bundle composable for users who only need `home-manager switch` without a full system build.

The Docker `cliPluginsExtraDirs` patch is the canonical example of why this split matters: it touches `~/.docker/config.json` with a path that depends on the running brew prefix (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel). Under the dotfiles repo's `install-mac.sh` this was a runtime `brew --prefix` call; here it's eval-time `pkgs.stdenv.hostPlatform`. It lives in `darwin/docker.nix` (not `home/*.nix`) because it's only meaningful where nix-homebrew owns Homebrew — but it runs as a `home.activation` (user context), because nix-darwin system activation runs as **root with `HOME=~root`** (`modules/system/activation-scripts.nix` exports it explicitly). A `system.activationScripts` block would silently patch `/var/root/.docker/config.json` and never take effect.

## Self-heal convention

`darwin/docker.nix` replaces Docker Desktop with Colima (system territory). On machines that previously had Docker Desktop, stale state may linger (broken symlinks pointing at a removed `.app`). On fresh machines that state doesn't exist. The self-heal block must:

1. **No-op on fresh machines** — guard on the existence of the stale state, not on a blanket remove.
2. **Only act on broken symlinks** — `[ -L "$link" ] && [ ! -e "$link" ]`. A working brew link for the same name must be left alone.
3. **Run in the right context.** nix-darwin system activation runs as root with `HOME=~root` — so per-user state (`~/.docker/config.json`) belongs in a `home.activation` block (HM activates as the user), and system-path state (`/usr/local/bin`, `/opt/homebrew/bin`) belongs in `system.activationScripts` where root needs no `sudo`.
4. **Never abort the rebuild** — a failing removal prints an actionable manual-equivalent hint and continues (`rm -f ... || echo "hint"`); a failing `jq` write warns and skips.

See `darwin/docker.nix`'s `cleanupDockerDesktopSymlinks` block for the reference pattern.

## Module conventions

- **Idempotent.** Running the rebuild twice produces the same state. `nix-darwin.activationScripts` blocks must guard against duplicates; `home.file` writes are Nix-atomic (the generation swap).
- **No secrets.** Never inline an API key, token, or password. The repo's `.zshrc` ships no `op read` calls — users wire their own secret-fetch lines in their own flake's `home-manager.users.<name>.programs.zsh.initContent`. See README "Secret hygiene".
- **Architecture-agnostic.** Use `pkgs.stdenv.hostPlatform.isAarch64` rather than hardcoding `/opt/homebrew` or `/usr/local`. Where the HM bundle genuinely doesn't care (most `home/packages.nix` lines), don't branch.
- **No `kevin` anywhere.** No username, no hostname, no email, no homeDirectory is baked into any module. The flake exposes no `homeConfigurations.kevin-*`, no `darwinConfigurations.kevin-mac`, no `nixosConfigurations.kevin-linux`. The single exception is `homeConfigurations."example@x86_64-linux"` — a deliberately placeholder identity that demos `lib.mkHome` as a copy-paste template, documented as not-for-activation. Consumers build their own real entries; see README "For other users".
- **One tool per concept.** Don't install two tools that do the same job unless one explicitly replaces the other (and there's a self-heal block for the replaced one). Examples: `kubernetes-helm` (NOT `helm` — that's a different unrelated tool in nixpkgs); `delta` (the upstream name; brew called this `git-delta`).
- **`dev.sh` is a sandbox only.** Never wire user-visible `homeConfigurations` through `legacyPackages.${system}.homeConfigurations.sandbox` — that attribute is the private entrypoint the dev script builds, not a consumer surface.

## Flake convention

- **`nix flake check --all-systems` must pass clean.** This is the pre-commit gate. Evaluation errors are the only class of bug the sandbox can't catch — squashing them at the gate matters more than running `dev.sh`.
- **`flake.lock` is committed.** Pinned to `nixpkgs-26.05-darwin` so Intel macOS support runs through end of 2026. When Intel Mac support is no longer needed, switch back to `nixos-unstable` and bump the lock.
- **`inputs.<tool>.inputs.nixpkgs.follows = "nixpkgs"`** for every vendored upstream that allows it (currently just `hunk`). Reduces rebuild cost. `nix-homebrew` doesn't expose a `nixpkgs` input — don't try to follow it there (spams a warning).
- **Vendored upstream flakes pin a tag**, not a branch — currently just `github:modem-dev/hunk/v0.17.3`. Bump the tag explicitly when you want a new release; never float against `master`/`dev`. **Prebuilt binaries (herdr, opencode) pin the release tag in the `fetchurl` URL** with a sha256 per supported system, embedded in `home/<tool>.nix`; bump `version` + re-prefetch all hashes together (`nix store prefetch-file --json <url> | jq -r .hash` — each module's header comment has the exact loop).
- **home-manager pins the release branch matching nixpkgs** (`release-26.05`). Tracking HM master against a pinned nixpkgs makes every `nix flake update` an option-removal lottery. **nix-darwin pins its matching release branch too** (`github:nix-darwin/nix-darwin/nix-darwin-26.05` — org moved from `lnl7`) — its `eval-config.nix` hard-throws when the nix-darwin and nixpkgs releases disagree.

## Repo-file conventions

- **`home/*.nix`** — one module per tool / concern. File names mirror the tool name (e.g. `home/lazygit.nix` configures `programs.lazygit`).
- **`files/<tool>/`** — raw config files for tools with no HM module or where a directory of files is shipped via `home.file`. File names mirror the deployed layout (e.g. `files/nvim/lua/plugins/docker.lua` deploys to `~/.config/nvim/lua/plugins/docker.lua`).
- **No runtime drag-in from upstream.** When porting a directory from the old dotfiles repo that was deployed via a Stow directory symlink (so runtime writes entered the repo tree), exclude the runtime artifacts. The canonical example: `files/opencode/` excludes `node_modules/`, `package.json`, `package-lock.json`, `.gitignore` — see the dotfiles AGENTS.md note on the `opencode` Stow shape. Only the *config* files come along; the runtime artifacts are regenerated on activation.
- **Editing a deployed file edits the repo.** Because HM's `home.file.source` symlinks from the Nix store. Edit the repo source so the next rebuild ships the change; don't edit the deployed path directly — it works, but obscures what changed in git.

## Workflow for fixing an environment issue

1. **Diagnose** with read-only commands (`nix flake show`, `nix eval`, `nix build --dry-run`, `darwin-rebuild dry-activate`, `./dev.sh`). Don't mutate.
2. **Identify the location** using the decision table above.
3. **Edit the Nix module** — `home/*.nix`, `darwin/*.nix`, `nixos/*.nix`, or `flake.nix` for input bumps.
4. **Run `nix flake check --all-systems`** — must pass clean.
5. **Run `./dev.sh`** end-to-end. Don't skip steps; don't run only the new lines. Verify the originally-failing command now works in the sandbox.
6. **For system-level changes** (`darwin/*`, `nixos/*`): the sandbox can't exercise casks or native Docker. Verify `darwin-rebuild dry-activate --flake <user-flake>#<hostname>` or `nixos-rebuild dry-build --flake <user-flake>#<hostname>` evaluates clean, then ask the user to run the real `switch` on the target machine.
7. **Update README** if a phase landed or a behavior changed. AGENTS.md treats drift between README and the actual flake outputs as a defect.

## Verification rule (hard)

Before declaring a task done, run:

1. `nix flake check --all-systems` from the repo root. Must pass clean — evaluation errors are the sandbox's blind spot.
2. `./dev.sh` end-to-end (for any change touching `home/` or inputs feeding `home/`). Don't declare success from reading the module; run it.

For changes touching `darwin/` or `nixos/`:

- `darwin-rebuild dry-activate --flake <user-flake>#<hostname>` must succeed on the real target (sandbox can't exercise it).
- The sudo / cask path (`sudo brew install --cask ...`) must be exercised on a real Mac. Sandbox runs skip this — see "Sudo-path rule" below.

False success claims are the worst AGENTS.md violation. Ambient silence about a skipped verification path is the second-worst.

## System-activation rule (replaces the old sudo-path rule)

nix-darwin system activation runs as **root** with `HOME=~root` (verified against the pinned nix-darwin: `modules/system/activation-scripts.nix` exports `USER=root`/`HOME=~root`, and `darwin-rebuild` re-execs through sudo). Consequences:

- **Per-user state never goes in `system.activationScripts`.** The `~/.docker/config.json` patch lives in a `home.activation` block inside `darwin/docker.nix` (HM's darwin module activates each user via `launchctl asuser … sudo -u <user> --set-home`). Putting it in system activation silently patches `/var/root/.docker/config.json`.
- **No `sudo` in activation blocks.** System activation is already root; HM activation must never need it. The old "sudo can't prompt under dry-activate" concern is moot — don't reintroduce it.
- **The sandbox and dry runs still can't exercise everything.** `./dev.sh` and `nix flake check` never run cask installs, `nix-homebrew`'s first-run sudo prompt, Colima, or a real activation. After changing `darwin/` or `nixos/`, report exactly which paths went unexercised and ask the user to run `darwin-rebuild switch` / `nixos-rebuild switch` on the real target.

## Don'ts

- Don't mutate live machine state outside the rebuilds / `home-manager switch` / `dev.sh`. Diagnose freely; mutate via the rebuild.
- Don't edit deployed files (`~/.zshrc`, `~/.config/nvim/init.lua`) directly — edit the repo source (`home/nvim.nix` + `files/nvim/`) so the change is version-controlled and re-deploys on the next rebuild.
- Don't commit secrets. Audit `home/zsh.nix` and any config with `op read` references before pushing anywhere public — though the repo's `.zshrc` deliberately ships no `op read` calls, so this should be a non-issue.
- Don't add a tool without checking the nixpkgs attribute name. nixpkgs has surprise names — `kubernetes-helm` (not `helm`), `delta` (not `git-delta`). Use `nix eval --raw github:NixOS/nixpkgs/<branch>#legacyPackages.${system}.<attr>.version` to probe before adding.
- Don't bake a username, hostname, or `homeDirectory` into any module. The repo is shareable — any user must be able to import it without forking. Per-user overrides live in the consumer's flake.
- Don't claim a fix works without running `nix flake check --all-systems` + sandbox `./dev.sh`. For `darwin`/`nixos` changes, also request a real-machine `darwin-rebuild dry-activate` from the user.
- Don't float vendored upstream flake inputs against a branch. Pin a tag — `github:<owner>/<repo>/<tag>`. Bump the tag explicitly when you want a new release.
- Don't reintroduce source builds for opencode/herdr. Bun toolchains SIGSEGV under virtualized CPUs (Parallels/UTM/VMware, some CI runners) — prebuilt release binaries are the default; opencode uses `-baseline` x64 variants (and glibc + `autoPatchelfHook` on Linux, never the musl builds — they need a musl-linked libstdc++ nixpkgs can't cleanly provide) for the same reason.

## Pointers

- **README.md** — full project context, phase status, the canonical "For other users" example flake. Read it for the big picture; AGENTS.md is for *how to make changes safely*.
- **flake.nix** — inputs (pinned nixpkgs, vendored hunk, nix-darwin, nix-homebrew, home-manager) + shareable module outputs + the instantiation layer. `homeModules.default` is a wrapper module injecting the vendored hunk flake via `_module.args` (so consumers need no `extraSpecialArgs`); `darwinModules.default` / `nixosModules.default` are `import`ed with this flake's `inputs`/`self` closed over (so consumers need no `specialArgs`). `lib.mkHome` builds a `homeManagerConfiguration` from `homeModules.default` + caller identity; `homeConfigurations."example@x86_64-linux"` is its placeholder demo; `dev.sh`'s sandbox config is built by the same `mkHome`.
- **home/** — Phase 1–7 HM config. One file per tool. `default.nix` imports the rest; `packages.nix` is the raw-bin grab bag; `files.nix` is the banner-only `home.file`.
- **darwin/** — `darwinModules.default`: nix-darwin bundle. `default.nix` wires `home-manager.darwinModules.home-manager` + `nix-homebrew.darwinModules.nix-homebrew` + applies `self.homeModules.default` via `home-manager.sharedModules` + declares the casks and Colima. `docker.nix` is the `~/.docker/config.json` patch (a `home.activation`, user context) + the broken-symlink self-heal (`system.activationScripts`, root).
- **nixos/** — `nixosModules.default`: NixOS bundle. `default.nix` wires `home-manager.nixosModules.home-manager` + applies `self.homeModules.default` via `home-manager.sharedModules` + native Docker + Nerd Font (`fonts.packages`) + system zsh.
- **files/** — vendored tool config trees: `nvim/` (AstroNvim, 24 files), `bat-themes/`, `btop/`, `herdr/`, `opencode/`, plus the `ainative-banner.sh` and the 6-line `ghostty-config`.
- **dev.sh** — throwaway-HOME sandbox entry. Uses the private `legacyPackages.${system}.homeConfigurations.sandbox` flake attribute. NOT a consumer surface.