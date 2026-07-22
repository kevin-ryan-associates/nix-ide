# herdr — agent multiplexer from https://herdr.dev/
# Upstream publishes a flake. We consume the upstream package per system so
# vendor hashes stay upstream's problem.
#
# Binary: `inputs.herdr.packages.${system}.herdr` (the upstream flake's
# exported package attribute — verified at first build). If upstream flips
# the attribute name, this is the single binding to update.
#
# Config: `~/dotfiles/herdr/.config/herdr/config.toml` shipped verbatim via
# `home.file` (no HM module exists for herdr).

{ lib, herdr, pkgs, ... }:

{
  home.packages = [
    # herdr upstream package attribute — see comment block above.
    herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];

  home.file.".config/herdr".source = ../files/herdr;
}