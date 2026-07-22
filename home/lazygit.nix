# lazygit Tokyo Night Moon colors. Verbatim port of
# `~/dotfiles/lazygit/.config/lazygit/config.yml`. lazygit reads XDG first on
# every platform, so the macOS `~/Library/Application Support/lazygit/...`
# symlink the dotfiles stowed in parallel is redundant — dropped here.

{ ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        theme = {
          activeBorderColor = [ "#ff966c" "bold" ];
          inactiveBorderColor = [ "#0db9d7" ];
          searchingActiveBorderColor = [ "#ff966c" "bold" ];
          optionsTextColor = [ "#82aaff" ];
          selectedLineBgColor = [ "#2f334d" ];
          cherryPickedCommitFgColor = [ "#82aaff" ];
          cherryPickedCommitBgColor = [ "#c099ff" ];
          markedBaseCommitFgColor = [ "#82aaff" ];
          markedBaseCommitBgColor = [ "#ffc777" ];
          unstagedChangesColor = [ "#c53b53" ];
          defaultFgColor = [ "#c8d3f5" ];
        };
      };
    };
  };
}