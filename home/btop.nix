# btop resource monitor with Tokyo Night Moon theme + vim keys.
# Ports:
#   ~/dotfiles/btop/.config/btop/btop.conf                  → home.file
#   ~/dotfiles/btop/.config/btop/themes/tokyo-night-moon.theme → home.file
#
# The HM `programs.btop` module does NOT support shipping custom theme files
# cleanly (its `settings` attrset maps to `btop.conf` but theme files live in
# a sibling `themes/` dir that the module doesn't manage). So we ship the
# whole `~/.config/btop/` directory via `home.file` — same approach as nvim.

{ pkgs, ... }:

{
  home.packages = [ pkgs.btop ];

  home.file.".config/btop".source = ../files/btop;
}