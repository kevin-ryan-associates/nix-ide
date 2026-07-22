# Git config + delta Tokyo Night colors. Ports `git/.config/git/config` from
# the dotfiles repo. The delta `[delta]` block maps directly onto
# `programs.git.delta.options`; no `home.file` raw config is needed.
#
# The username/email are mkDefault placeholders so any consumer can override:
#   { programs.git.userName = "Real Name"; programs.git.userEmail = "real@example.com"; }
# …in their own `homeConfigurations` module produces the merged final config.
# Nothing baked into this repo so the flake stays shareable.

{ lib, ... }:

{
  programs.git = {
    enable = true;

    userName = lib.mkDefault "Your Name";
    userEmail = lib.mkDefault "you@example.com";

    delta = {
      enable = true;
      options = {
        minus-style = "syntax \"#4b2a3d\"";
        minus-non-emph-style = "syntax \"#4b2a3d\"";
        minus-emph-style = "syntax \"#713137\"";
        minus-empty-line-marker-style = "syntax \"#4b2a3d\"";
        line-numbers-minus-style = "#c53b53";
        plus-style = "syntax \"#2a4556\"";
        plus-non-emph-style = "syntax \"#2a4556\"";
        plus-emph-style = "syntax \"#2c5a66\"";
        plus-empty-line-marker-style = "syntax \"#2a4556\"";
        line-numbers-plus-style = "#4fd6be";
        line-numbers-zero-style = "#3b4261";
      };
    };
  };
}