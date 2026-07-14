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
# (e.g. STARSHIP_CONFIG=/Users/kevinryan/.config/starship.toml). We source
# it for the env vars (BAT_THEME, EDITOR, FZF_*, ...), prepend Nix profile
# bins so the Nix-installed tools win over Homebrew, then override
# STARSHIP_CONFIG to the sandbox path.
#
# Usage:
#   ./dev.sh
#
# Requires: Nix installed, flakes enabled. See README.md.

set -euo pipefail

cd "$(dirname "$0")"

# Pick the homeConfiguration attribute matching this host.
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   ATTR="kevin-aarch64-darwin" ;;
  Darwin-x86_64)  ATTR="kevin-x86_64-darwin" ;;
  Linux-aarch64)  ATTR="kevin-aarch64-linux" ;;
  Linux-x86_64)   ATTR="kevin-x86_64-linux" ;;
  *) echo "ERROR: unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

WORK="$(mktemp -d -t nix-ide-dev)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Building .#homeConfigurations.${ATTR}.activationPackage (no switch)..."
nix build --no-link --out-link "$WORK/activation" \
  ".#homeConfigurations.${ATTR}.activationPackage"

# Lay out a fake $HOME containing only what HM would deploy.
# The activation package exposes `home-files/` as the directory of files
# HM would write into $HOME on `switch`.
mkdir -p "$WORK/home/.config/ainative"
ln -sf "$WORK/activation/home-files/.zshrc"                "$WORK/home/.zshrc"
ln -sf "$WORK/activation/home-files/.zshenv"               "$WORK/home/.zshenv"
ln -sf "$WORK/activation/home-files/.config/starship.toml" \
       "$WORK/home/.config/starship.toml"
ln -sf "$WORK/activation/home-files/.config/ainative/banner.sh" \
       "$WORK/home/.config/ainative/banner.sh"

# Write a custom .zprofile. HM's .zprofile sources session-vars.sh which
# exports STARSHIP_CONFIG=/Users/kevinryan/.config/starship.toml (hardcoded
# at build time), so we source HM's .zprofile for the other env vars and
# then override STARSHIP_CONFIG back to the sandbox path. We also prepend
# Nix profile bins to PATH so the HM-installed tools win over Homebrew.
cat > "$WORK/home/.zprofile" <<EOF
# dev-mode .zprofile (replaces HM-generated one with hardcoded paths)
# Source HM's session vars first (BAT_THEME, EDITOR, FZF_*, etc.).
. "$WORK/activation/home-files/.zprofile"
# Override HM's hardcoded STARSHIP_CONFIG to our sandbox path.
export STARSHIP_CONFIG="$WORK/home/.config/starship.toml"
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
  TERMINFO_DIRS="${TERMINFO_DIRS:-}" \
  COLORTERM="${COLORTERM:-truecolor}" \
  TERM="${TERM:-xterm-256color}" \
  SHELL="$(command -v zsh)" \
  zsh -li