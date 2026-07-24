# Port of fzf config from .zshrc.
#
# Replaces:
#   export FZF_DEFAULT_COMMAND=...
#   export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
#   export FZF_ALT_C_COMMAND=...
#   export FZF_DEFAULT_OPTS="..."
#   source <(fzf --zsh)
#
# `enableZshIntegration` injects the `source <(fzf --zsh)` line for us.
# Tokyo Night Moon palette is preserved verbatim as one --color=… entry
# per list item.

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";

    defaultOptions = [
      "--highlight-line"
      "--info=inline-right"
      "--ansi"
      "--layout=reverse"
      "--border=none"
      "--color=bg+:#2f334d"
      "--color=bg:#222436"
      "--color=border:#0db9d7"
      "--color=fg:#c8d3f5"
      "--color=gutter:#222436"
      "--color=header:#ff966c"
      "--color=hl+:#86e1fc"
      "--color=hl:#86e1fc"
      "--color=info:#636da6"
      "--color=marker:#c099ff"
      "--color=pointer:#c099ff"
      "--color=prompt:#86e1fc"
      "--color=query:#c8d3f5:regular"
      "--color=scrollbar:#0db9d7"
      "--color=separator:#ff966c"
      "--color=spinner:#c099ff"
    ];
  };
}