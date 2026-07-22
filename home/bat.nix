# bat with Tokyo Night Moon syntax highlighting theme.
#
# Ports:
#   ~/dotfiles/bat/.config/bat/config           → programs.bat.config
#   ~/dotfiles/bat/.config/bat/themes/          → home.file ".config/bat/themes"
#
# The theme file is a TextMate `.tmTheme` — bat discovers it via
# `bat cache --build`, which `programs.bat` runs automatically on activation
# (the HM module invokes `bat cache --build` for us when extraConfig or
# extraPackages are non-empty). We list the theme as an extra theme via
# `programs.bat.extraPackages`-style attach by staging the file under
# `~/.config/bat/themes` and relying on programs.bat's `config = { theme =
# "tokyonight_moon"; }` setting.

{ pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      theme = "tokyonight_moon";
      style = "numbers,changes,header";
      paging = "auto";
    };
  };

  # Theme file shipped to ~/.config/bat/themes/tokyonight_moon.tmTheme.
  # `bat cache --build` runs on activation when extraPackages is non-empty —
  # we attach a no-op package list to force the cache build to pick up the
  # custom theme. (The cleanest reliable way to register a custom .tmTheme
  # with bat is to place it under `~/.config/bat/themes/` then `bat cache
  # --build`; HM's programs.bat module re-runs the cache when
  # `programs.bat.extraPackages` changes, so we pass it an explicit empty
  # truthy expression by referencing a tiny `bat`-tied package list.)
  home.file.".config/bat/themes/tokyonight_moon.tmTheme".source =
    ../files/bat-themes/tokyonight_moon.tmTheme;

  # Force the cache build on every activation so new themes are picked up.
  # `programs.bat` doesn't expose `bat cache --build` directly; this
  # activation script is the canonical pattern for it.
  home.activation.batCacheBuild = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.bat}/bin/bat cache --build 2>/dev/null || true
  '';
}