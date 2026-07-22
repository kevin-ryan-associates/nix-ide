# AstroNvim config tree. The whole `~/dotfiles/nvim/.config/nvim/` tree is
# vendored verbatim into `files/nvim/` (24 files, ~104K), then deployed via
# `home.file.".config/nvim".source` — a directory source. HM recurses and
# symlinks each file individually, mirroring the dotfiles Stow deployment.
#
# Lazy.nvim is the plugin manager and stays in charge: plugins install on
# first `nvim` launch from the lockfile in `files/nvim/lazy-lock.json`.
# Rewriting it through `pkgs.vimPlugins` was considered and rejected — the
# AstroNvim layout is bespoke and lazy.nvim's runtime-update UX is the
# existing contract (no regression from dotfiles).
#
# Tool inventory for the plugin build deps:
#   - `neovim`            — the editor.
#   - `nodejs`            — npm ships with it; required by Mason for LSPs.
#   - `ripgrep`           — telescope dependency.
#   - `cmake`             — required by some Neovim plugin C builds.
#
# The Nerd Font (MesloLGS) is NOT installed here — it is runtime font
# rendering and lives in Phase 8:
#   - macOS: `homebrew.casks` via nix-darwin (`font-meslo-lg-nerd-font`)
#   - Linux: `fonts.fonts = [pkgs.nerd-fonts.meslo-lg]` via NixOS module

{ pkgs, ... }:

{
  home.file.".config/nvim".source = ../files/nvim;

  home.packages = with pkgs; [
    neovim
    nodejs
    ripgrep
    cmake
  ];
}