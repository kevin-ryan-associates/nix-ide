# hunk — review-first terminal diff viewer (https://hunk.dev/).
# Upstream publishes a flake; we consume its `packages.${system}.hunk`
# attribute (version 0.17.3 at our pin). Vendored rather than nixpkgs
# because hunk is not packaged in our pinned `nixpkgs-26.05-darwin` (we're
# pinned for Intel Mac support through end of 2026; present in nixpkgs
# unstable, but moving the whole flake back to unstable is a larger
# decision than this one tool warrants).
#
# No config to ship — hunk is config-light (optional `--theme` flag, no
# required `~/.config/hunk/` tree). If you want `hunk` as your default
# git pager, set it yourself in your consumer flake:
#     programs.git.extraConfig.core.pager = "hunk pager";
# We deliberately don't bake that into home/git.nix — it's a per-user
# preference that overrides existing git config without consent.

{ hunk, pkgs, ... }:

{
  home.packages = [
    hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk
  ];
}