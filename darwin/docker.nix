# Docker `cliPluginsExtraDirs` wire-up for macOS.
#
# Ports the `~/.docker/config.json` patch from `install-mac.sh` in the
# dotfiles repo. The path is brew-prefix-dependent, resolved at evaluation
# time via `pkgs.stdenv.hostPlatform` (no runtime `brew --prefix`).
#
# Two different execution contexts, deliberately:
#
#   1. The `~/.docker/config.json` patch runs as a home-manager activation
#      (`home.activation`). HM's darwin module activates each user via
#      `launchctl asuser … sudo -u <user> --set-home`, so `$HOME` is the
#      real user home. It CANNOT be a `system.activationScripts` block:
#      nix-darwin system activation runs as root with `HOME=~root`
#      (modules/system/activation-scripts.nix exports it explicitly), so
#      the patch would silently land in /var/root and never take effect.
#
#   2. The stale Docker Desktop symlink cleanup stays in
#      `system.activationScripts`: it touches /usr/local/bin and
#      /opt/homebrew/bin — system territory — and activation is already
#      root there, so no `sudo` is needed (or wanted).
#
# Idempotency / self-heal contract (mirrors dotfiles AGENTS.md):
#   1. No-op on fresh machines — only patches `~/.docker/config.json` if its
#      current `cliPluginsExtraDirs` doesn't already point at our prefix,
#      and only removes symlinks that are actually broken.
#   2. Never aborts activation on an unparsable pre-existing config.json —
#      warns and continues.

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
  # ---- `~/.docker/config.json` patch (user context) ------------------------
  # Applied to every declared `home-manager.users.<name>` — no username
  # needed here. Idempotent: only writes when `cliPluginsExtraDirs` is
  # missing our entry. Uses `${pkgs.jq}/bin/jq` to be PATH-independent.
  home-manager.sharedModules = [
    ({ lib, pkgs, ... }: {
      home.activation.dockerCliPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONFIG="$HOME/.docker/config.json"
        if ! ${pkgs.jq}/bin/jq -e --arg dir "${pluginsDir}" \
            '(.cliPluginsExtraDirs // []) | index($dir)' "$CONFIG" >/dev/null 2>&1; then
          if [[ ! -v DRY_RUN ]]; then
            mkdir -p "$HOME/.docker"
            [ -f "$CONFIG" ] || echo '{}' > "$CONFIG"
            if ${pkgs.jq}/bin/jq --arg dir "${pluginsDir}" '
                if (.cliPluginsExtraDirs // []) | index($dir) then . else
                  .cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$dir])
                end
                | if .credsStore == "desktop" then del(.credsStore) else . end
              ' "$CONFIG" > "$CONFIG.tmp" 2>/dev/null; then
              mv "$CONFIG.tmp" "$CONFIG"
              echo "  added ${pluginsDir} to cliPluginsExtraDirs"
            else
              rm -f "$CONFIG.tmp"
              echo "  WARNING: $CONFIG is not valid JSON; skipping cliPluginsExtraDirs patch" >&2
            fi
          fi
        fi
      '';
    })
  ];

  # ---- Stale Docker Desktop symlink cleanup (system context, root) --------
  # Only touches broken symlinks — usual `darwin-rebuild switch` runs on
  # machines that never had Docker Desktop skip this entirely. Both prefixes
  # are checked on every arch: Docker Desktop always wrote its CLI symlinks
  # to /usr/local/bin (even on Apple Silicon), while brew's docker-compose
  # formula links from its own prefix. Working links fail the `[ ! -e ]`
  # test and are left alone; nonexistent prefixes fail `[ -L ]`.
  system.activationScripts.cleanupDockerDesktopSymlinks.text = ''
    echo "==> Cleaning up stale Docker Desktop symlinks (if any)..."
    for link in /opt/homebrew/bin/docker-compose \
                /usr/local/bin/docker-compose \
                /usr/local/bin/docker-credential-desktop \
                /usr/local/bin/docker-credential-osxkeychain; do
      if [ -L "$link" ] && [ ! -e "$link" ]; then
        rm -f "$link" 2>/dev/null || \
          echo "  could not remove $link — run manually: sudo rm $link"
      fi
    done
  '';
}
