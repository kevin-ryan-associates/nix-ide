# Port of `eval "$(zoxide init zsh)"` from .zshrc.
# `enableZshIntegration` injects the init line for us.

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}