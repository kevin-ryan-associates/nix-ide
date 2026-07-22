# htop with Black Night color scheme (closest to Tokyo Night in htop's
# fixed color palette). The dotfiles repo contains a single
# `~/dotfiles/htop/.config/htop/htoprc` line: `color_scheme=6`. HM's
# `programs.htop.settings.colorScheme = 6;` writes the same value.

{ ... }:

{
  programs.htop = {
    enable = true;
    settings.colorScheme = 6;
  };
}