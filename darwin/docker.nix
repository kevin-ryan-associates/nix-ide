# Docker `cliPluginsExtraDirs` wire-up for macOS.
#
# Ports the `~/.docker/config.json` patch from `install-mac.sh` in the
# dotfiles repo. The path is runtime-brew-prefix-dependent and so can't live
# in the HM bundle — it belongs in the darwinSystem that owns Homebrew
# state. This module ships that state setup.
#
# Idempotency / self-heal contract (mirrors dotfiles AGENTS.md):
#   1. No-op on fresh machines — only patches `~/.docker/config.json` if its
#      current `cliPluginsExtraDirs` doesn't already point at our prefix.
#   2. Only touch broken Docker Desktop symlinks — never blanket-remove.
#   3. Never abort `darwin-rebuild switch` when `sudo` can't prompt —
#      prints an actionable manual-equivalent and continues.

{ pkgs, lib, config, ... }:

let
  # The brew prefix under nix-homebrew is `/opt/homebrew` on Apple Silicon
  # and `/usr/local` on Intel. Use `pkgs.stdenv.hostPlatform` so it's
  # determinable at evaluation time (no `brew --prefix` runtime call).
  brewPrefix =
    if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew"
    else "/usr/local";

  pluginsDir = "${brewPrefix}/lib/docker/cli-plugins";
in
{
  # ---- `~/.docker/config.json` patch ---------------------------------------
  # Idempotent: only writes when `cliPluginsExtraDirs` is missing our entry.
  # Uses `${pkgs.jq}/bin/jq` to be PATH-independent at activation time.
  system.activationScripts.dockerCliPlugins.text = ''
    echo "==> Configuring ~/.docker/config.json for compose plugin..."
    mkdir -p "$HOME/.docker"
    CONFIG="$HOME/.docker/config.json"
    if [ ! -f "$CONFIG" ]; then
      echo '{}' > "$CONFIG"
    fi

    if ! ${pkgs.jq}/bin/jq -e --arg dir "${pluginsDir}" \
        '(.cliPluginsExtraDirs // []) | index($dir)' "$CONFIG" >/dev/null 2>&1; then
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq --arg dir "${pluginsDir}" '
        if (.cliPluginsExtraDirs // []) | index($dir) then . else
          .cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$dir])
        end
        | if .credsStore == "desktop" then del(.credsStore) else . end
      ' "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
      echo "  added ${pluginsDir} to cliPluginsExtraDirs"
    else
      echo "  cliPluginsExtraDirs already contains ${pluginsDir}"
    fi
  '';

  # ---- Stale Docker Desktop symlink cleanup (self-heal) -------------------
  # Only touches broken symlinks — usual `darwin-rebuild switch` runs on
  # machines that never had Docker Desktop skip this entirely.
  system.activationScripts.cleanupDockerDesktopSymlinks.text = ''
    echo "==> Cleaning up stale Docker Desktop symlinks (if any)..."
    for link in ${if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew/bin/docker-compose" else "/usr/local/bin/docker-compose"} \
                /usr/local/bin/docker-credential-desktop \
                /usr/local/bin/docker-credential-osxkeychain; do
      if [ -L "$link" ] && [ ! -e "$link" ]; then
        sudo rm -f "$link" 2>/dev/null || \
          echo "  skipping $link (no sudo TTY; run manually: sudo rm $link)"
      fi
    done
  '';
}