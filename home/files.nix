# User-data files that don't fit a `programs.*` module. Phase 1 has one:
# the ainative banner, sourced from .zshrc's initExtra.
#
# The starship.toml used to live here as a raw home.file — it now lives in
# programs.starship.settings (see home/starship.nix), which writes the toml
# from a Nix attrset.

{
  home.file.".config/ainative/banner.sh".source = ../files/ainative-banner.sh;
}