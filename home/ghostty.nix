# Ghostty terminal config. The 6-line config is shipped to
# `~/.config/ghostty/config`. The Ghostty binary itself is installed via
# nix-darwin's Homebrew cask on macOS (Phase 8) or `home.packages` on Linux
# (where `pkgs.ghostty` provides a working binary). Linux additionally gets
# a desktop launcher entry + icon so Ghostty shows up in the DE's
# application menu, not just from a terminal.

{ pkgs, lib, ... }:

{
  home.file.".config/ghostty/config".source = ../files/ghostty-config;

  # Linux gets the binary as a home package; macOS gets the cask via
  # nix-darwin in Phase 8.
  home.packages =
    lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.ghostty ];

  # Linux-only: launcher entry so Ghostty appears in the DE's application
  # menu. HM writes ~/.local/share/applications/ghostty.desktop — always
  # scanned by freedesktop menus, unlike the nix profile's own
  # share/applications. Guarded to Linux: on macOS the Homebrew cask
  # registers the .app, and a stray .desktop file would be pointless.
  xdg.desktopEntries = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    ghostty = {
      name = "Ghostty";
      comment = "Fast, native, GPU-accelerated terminal emulator";
      exec = "${pkgs.ghostty}/bin/ghostty";
      # `com.mitchellh.ghostty` is shipped by pkgs.ghostty itself — upstream
      # installs hicolor icons at 16/32/128/256/512/1024px (verified against
      # src/build/GhosttyResources.zig at v1.3.1).
      icon = "com.mitchellh.ghostty";
      terminal = false;
      categories = [ "System" "TerminalEmulator" "Utility" ];
    };
  };

  # The icon name resolves via the hicolor theme, but the package's icons
  # live in the nix profile — only scanned when the profile's share dir is
  # in XDG_DATA_DIRS (NixOS: yes; foreign-distro HM: not guaranteed). Ship
  # one icon into ~/.local/share/icons (always scanned) so the launcher
  # icon renders everywhere.
  home.file.".local/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" =
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = "${pkgs.ghostty}/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png";
    };
}
