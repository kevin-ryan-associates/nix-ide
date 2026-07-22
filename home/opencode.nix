# opencode — coding agent. Upstream publishes a flake; we consume its
# `packages.${system}.opencode` attribute (version 1.18.4 at our pin).
# `packages.${system}.opencode-desktop` exists too — the GUI app, not wanted
# here. If a future pin breaks the upstream build for a particular system
# (x86_64-darwin in particular has flaky bun-fetch behaviour), fall back to
# `nixpkgs#opencode` (currently 1.15.10) by replacing the `home.packages`
# line below with `pkgs.opencode` and removing `opencode` from
# `flake.nix`'s `extraSpecialArgs`.
#
# Config tree: `~/dotfiles/opencode/.config/opencode/` ported minus runtime
# drag-in (node_modules, package.json, package-lock.json, .gitignore — see
# the dotfiles AGENTS.md for the directory-symlink note). 10 files kept:
#   opencode.jsonc, tui.json, themes/tokyonight-moon.json,
#   agents/sdd-01-product.md, agents/sdd-02-discover.md,
#   skills/sdd/SKILL.md, skills/sdd-discovery-authoring/*.md,
#   skills/sdd-product-authoring/*.md
# These deploy via `home.file.".config/opencode".source` — same directory
# shape the Stow package deployed, but as plain symlinks (Nix store → home).

{ opencode, pkgs, ... }:

{
  home.packages = [
    opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];

  home.file.".config/opencode".source = ../files/opencode;
}