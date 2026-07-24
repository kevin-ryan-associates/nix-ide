#!/usr/bin/env bash
# nix-ide dev mode — test the ported home-manager config in a sandbox
# without touching your real $HOME.
#
# Builds the activation package (no `home-manager switch`), lays out its
# files into a throwaway HOME, then `exec`s an interactive login zsh with
# HOME pointed at the sandbox. Exit the shell (Ctrl-D / `exit`) to tear
# it down; nothing persists.
#
# A custom .zprofile is written in the sandbox because HM's generated
# .zprofile sources a session-vars.sh that bakes in the REAL home path
# (e.g. STARSHIP_CONFIG=/Users/<you>/.config/starship.toml). We source
# it for the env vars (BAT_THEME, EDITOR, FZF_*, ...), prepend the built
# profile's bin/ (home-path) so the sandbox exercises the FLAKE's pinned
# tools rather than whatever the host has installed, then override
# STARSHIP_CONFIG to the sandbox path.
#
# The flake no longer ships user-specific `homeConfigurations`. The dev
# sandbox uses a private `legacyPackages.${system}.homeConfigurations.sandbox`
# attribute the flake publishes exclusively for this script — the consumer
# path is writing your own flake (see README.md "For other users").
#
# Usage:
#   ./dev.sh
#
# Requires: Nix installed, flakes enabled. See README.md.

set -euo pipefail

cd "$(dirname "$0")"

# Map this host to one of the supportedSystems the flake enumerates.
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   SYSTEM="aarch64-darwin" ;;
  Darwin-x86_64)  SYSTEM="x86_64-darwin"  ;;
  Linux-aarch64)  SYSTEM="aarch64-linux"  ;;
  Linux-x86_64)   SYSTEM="x86_64-linux"   ;;
  *) echo "ERROR: unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

ATTR="legacyPackages.${SYSTEM}.homeConfigurations.sandbox.activationPackage"

# GNU mktemp requires X's in the template even with -t; the XXXXXX form
# works on both BSD (macOS) and GNU (Linux) coreutils.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/nix-ide-dev.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "==> Building .#${ATTR} (no switch)..."
nix build --out-link "$WORK/activation" ".#${ATTR}"

# Lay out a fake $HOME containing only what HM would deploy.
# The activation package exposes `home-files/` as the directory of files
# HM would write into $HOME on `switch`. We mirror the whole `home-files`
# tree — top-level dotfiles + the entire `.config/` directory — so any
# new tool added in the home module is automatically picked up by the
# sandbox without a dev.sh edit. (Pre-Phase-7 dev.sh hardcoded four
# symlinks; that approach scaled badly as the HM bundle grew.)
mkdir -p "$WORK/home"
# Wrapper .zshrc instead of a bare symlink: the repo's zshrc prepends
# /usr/local/bin ahead of inherited PATH entries (and macOS path_helper in
# /etc/zprofile also reorders), which would let host-installed copies of
# starship/eza/bat/... shadow the sandbox's pinned tools. Re-prepending
# home-path AFTER the real .zshrc runs makes the sandbox deterministic —
# the flake's tools win regardless of what the host has installed.
cat > "$WORK/home/.zshrc" <<EOF
export PATH="$WORK/activation/home-path/bin:\$PATH"
. "$WORK/activation/home-files/.zshrc"
export PATH="$WORK/activation/home-path/bin:\$PATH"
EOF
ln -sf "$WORK/activation/home-files/.zshenv" "$WORK/home/.zshenv"
cp -R "$WORK/activation/home-files/.config" "$WORK/home/.config"
# The Nix store is read-only by design (dirs are mode 0555); `cp -R`
# preserves those modes, so the sandbox HOME's `~/.config/<tool>/` dirs
# would be read-only. `chmod -R u+w` re-enables write so subsequent
# `ln -sfn` re-links and the trap's `rm -rf "$WORK"` can clean up.
chmod -R u+w "$WORK/home"
# Replace the copied `starship.toml` (which itself is a Nix-store symlink)
# with a repo-relative symlink for clarity — same result either way, but
# the explicit re-link guards against the (theoretical) edge case where
# HM's `.config/starship.toml` is a real file rather than a symlink.
ln -sfn "$WORK/activation/home-files/.config/starship.toml" \
        "$WORK/home/.config/starship.toml"

# Write a custom .zprofile. HM's .zprofile sources session-vars.sh which
# exports STARSHIP_CONFIG=/Users/<username>/.config/starship.toml (hardcoded
# at build time), plus the XDG_*_HOME vars baked to the same build-time
# homeDirectory. We source HM's .zprofile for the other env vars then
# override every path-bearing var back to the sandbox HOME so tools that
# honor XDG (opencode, starship, nvim, ...) write into the sandbox rather
# than trying to mkdir the real homeDirectory on the host (which would fail
# with EACCES — HM's placeholder `nix-ide-dev` is not a real OS user).
cat > "$WORK/home/.zprofile" <<EOF
# dev-mode .zprofile (replaces HM-generated one with hardcoded paths)
# Source HM's session vars first (BAT_THEME, EDITOR, FZF_*, etc.).
. "$WORK/activation/home-files/.zprofile"
# Override HM's hardcoded paths to our sandbox HOME.
export STARSHIP_CONFIG="$WORK/home/.config/starship.toml"
export XDG_CONFIG_HOME="$WORK/home/.config"
export XDG_CACHE_HOME="$WORK/home/.cache"
export XDG_DATA_HOME="$WORK/home/.local/share"
export XDG_STATE_HOME="$WORK/home/.local/state"
export XDG_BIN_HOME="$WORK/home/.local/bin"
# The activation package carries the full HM profile at home-path/ — put it
# FIRST on PATH so the sandbox tests the flake's pinned tools, not whatever
# the host happens to have installed (on a fresh machine the host has none).
export PATH="$WORK/activation/home-path/bin:\$PATH"
export TERMINFO_DIRS="$WORK/activation/home-path/share/terminfo:\${TERMINFO_DIRS:-/usr/share/terminfo}"
# Prepend Nix profile bins so the Nix-installed tools win over Homebrew.
for __p in \${(z)NIX_PROFILES}; do
  PATH="\$__p/bin:\$PATH"
done
export PATH
EOF

echo
echo "==> Entering nix-ide dev shell (HOME=$WORK/home)"
echo "    Type 'exit' or Ctrl-D to leave. Your real ~/.zshrc is untouched."
echo

exec env -i \
  HOME="$WORK/home" \
  NIX_PROFILES="${NIX_PROFILES:-}" \
  PATH="$PATH" \
  NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-}" \
  COLORTERM="${COLORTERM:-truecolor}" \
  TERM="xterm-256color" \
  SHELL="$(command -v zsh)" \
  zsh -li