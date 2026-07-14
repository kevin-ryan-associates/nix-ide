# Full transcription of ~/dotfiles/starship/.config/starship.toml to
# programs.starship.settings. `enableZshIntegration` injects
# `eval "$(starship init zsh)"` for us (so zsh.nix doesn't carry it).
#
# The Tokyo Night Moon palette is preserved verbatim. The `format` string
# below is the runtime string the original toml produced after TOML's
# backslash-newline continuations were resolved — no newlines, no
# backslashes; `lib.concatStringsSep "" [ … ]` joins it for readability.

{ lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = lib.concatStringsSep "" [
        "[](color_panel)"
        "$username"
        "[](bg:color_dir fg:color_panel)"
        "$directory"
        "[](fg:color_git bg:color_lang)"
        "$git_branch"
        "$git_status"
        "[](fg:color_lang bg:color_time)"
        "$time"
        "[ ](fg:color_time)"
        "$character"
      ];

      palette = "tokyo_night";

      palettes.tokyo_night = {
        # panel backgrounds (dark)
        color_panel = "#1e2030";
        color_dir = "#222436";
        color_git = "#2f334d";
        color_lang = "#222436";
        color_time = "#2f334d";
        # accents
        color_cyan = "#86e1fc";
        color_green = "#c3e88d";
        color_magenta = "#c099ff";
        color_blue = "#82aaff";
        color_amber = "#ffc777";
        color_red = "#ff757f";
        color_text = "#c8d3f5";
        color_dim = "#636da6";
      };

      os = { disabled = true; };

      username = {
        show_always = true;
        style_user = "bg:color_panel fg:color_text";
        style_root = "bg:color_panel fg:color_red";
        format = "[ $user ]($style)";
      };

      directory = {
        style = "bg:color_dir fg:color_cyan";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = "󰇚";
          Music = "󰝚";
          Pictures = "󰉏";
          workspace = "󰙴";
        };
      };

      git_branch = {
        symbol = "󰊢";
        style = "bg:color_git fg:color_amber";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:color_git fg:color_magenta";
        format = "[$all_status$ahead_behind ]($style)";
      };

      python = {
        symbol = "󰌠";
        style = "bg:color_lang fg:color_green";
        format = "[ $symbol($version)(\\($virtualenv\\)) ]($style)";
      };

      nodejs = {
        symbol = "󰎙";
        style = "bg:color_lang fg:color_green";
        format = "[ $symbol($version) ]($style)";
      };

      rust = {
        symbol = "󱘗";
        style = "bg:color_lang fg:color_amber";
        format = "[ $symbol($version) ]($style)";
      };

      golang = {
        symbol = "󰟓";
        style = "bg:color_lang fg:color_cyan";
        format = "[ $symbol($version) ]($style)";
      };

      lua = {
        symbol = "󰢱";
        style = "bg:color_lang fg:color_blue";
        format = "[ $symbol($version) ]($style)";
      };

      docker_context = {
        symbol = "󰡨";
        style = "bg:color_lang fg:color_blue";
        format = "[ $symbol$context ]($style)";
      };

      kubernetes = {
        disabled = false;
        symbol = "󱃾";
        style = "bg:color_lang fg:color_magenta";
        format = "[ $symbol$context( \\($namespace\\)) ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_time fg:color_cyan";
        format = "[ 󰥔 $time ]($style)";
      };

      character = {
        success_symbol = "[❯](bold #c3e88d)";
        error_symbol = "[❯](bold #ff757f)";
        vimcmd_symbol = "[❮](bold #ffc777)";
      };

      cmd_duration = {
        min_time = 500;
        format = "[ took $duration]($style) ";
        style = "fg:#ffc777";
      };
    };
  };
}