# Binaries invoked from .zshrc that aren't enrolled in their own
# `programs.*` HM module in this phase. starship and fzf and zoxide are
# added by their respective modules; the binaries below are still raw
# packages because:
#   - eza, fd, bat, git-delta: HM has a `programs.*` module for some of
#     these (eza, bat) but we don't need the option surface in phase 1 —
#     we just want the binary on PATH so the aliases resolve. The configs
#     (`bat/themes/`, `~/.config/git/config [delta] …`) land in later
#     phases alongside their full module ports.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    eza
    fd
    bat
    delta   # brew called this git-delta; nixpkgs uses the upstream name `delta`
  ];
}