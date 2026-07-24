# Git config + delta Tokyo Night colors. Ports `git/.config/git/config` from
# the dotfiles repo. The delta `[delta]` block maps directly onto
# `programs.delta.options`; no `home.file` raw config is needed.
#
# `programs.delta` (not the old `programs.git.delta` shim — renamed upstream
# in home-manager; the shim also auto-enabled the git integration with a
# deprecation warning, so we set `enableGitIntegration` explicitly).
#
# The username/email are mkDefault placeholders so any consumer can override:
#   { programs.git.settings.user.name = "Real Name"; programs.git.settings.user.email = "real@example.com"; }
# …in their own `homeConfigurations` module produces the merged final config.
# Nothing baked into this repo so the flake stays shareable.

{ lib, ... }:

{
  programs.git = {
    enable = true;

    settings.user = {
      name = lib.mkDefault "Your Name";
      email = lib.mkDefault "you@example.com";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
}
