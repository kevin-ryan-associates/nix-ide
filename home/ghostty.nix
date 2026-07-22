# Ghostty terminal config. The 6-line config is shipped to
# `~/.config/ghostty/config`. The Ghostty binary itself is installed via
# nix-darwin's Homebrew cask on macOS (Phase 8) or `home.packages` on Linux
# (where `pkgs.ghostty` provides a working binary). Phase 8 wires the binary;
# this file only ships the config.

{ pkgs, lib, ... }:

{
  home.file.".config/ghostty/config".source = ../files/ghostty-config;

  # Linux gets the binary as a home package; macOS gets the cask via
  # nix-darwin in Phase 8.
  home.packages =
    lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.ghostty ];
}