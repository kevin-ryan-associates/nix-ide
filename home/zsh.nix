# Port of ~/dotfiles/zsh/.zshrc to home-manager native modules.
#
# Strategy:
#   - History, options, aliases: use programs.zsh.* options where HM models
#     them cleanly; fall back to initExtra for the raw `setopt …` line and
#     for everything Zinit owns (clone bootstrap, annexes, turbo plugin block,
#     zstyle completion styling, fzf-tab zstyles).
#   - fzf, zoxide, starship init lines are NOT in initExtra — those tools'
#     modules inject their own integration via `enableZshIntegration`.
#   - Aliases for not-yet-installed tools (kubectl, docker, terraform,
#     lazygit, opencode) are kept harmlessly; they land cleanly when later
#     phases add the binaries.

{ ... }:

{
  programs.zsh = {
    enable = true;

    # ---- History ---------------------------------------------------------
    history = {
      path = "$HOME/.zsh_history";
      size = 100000;
      save = 100000;
      ignoreDups = true;     # HIST_IGNORE_DUPS
      ignoreSpace = true;   # HIST_IGNORE_SPACE
      extended = true;      # EXTENDED_HISTORY
      share = true;          # SHARE_HISTORY (default)
      append = true;         # APPEND_HISTORY
      # HIST_REDUCE_BLANKS and INC_APPEND_HISTORY have no HM option — kept
      # as raw `setopt` in initExtra below.
    };

    # ---- Aliases (every alias from .zshrc) -------------------------------
    shellAliases = {
      # eza
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --git --group-directories-first";
      la = "eza -la --icons --git --group-directories-first";
      lt = "eza --tree --icons --level=2";
      # bat
      cat = "bat --paging=never";
      less = "bat --paging=always";
      # delta
      diff = "delta";
      grep = "grep --color=auto";
      # git
      g = "git";
      lg = "lazygit";
      # editor
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      # kubernetes / docker / terraform (binaries ship in later phases)
      k = "kubectl";
      d = "docker";
      dc = "docker compose";
      tf = "terraform";
      # opencode
      oc = "opencode";
      # safer defaults
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      # quick reload
      reload = "exec zsh";
    };

    # Everything below is preserved verbatim from .zshrc because HM has no
    # dedicated option for it (zstyles, Zinit bootstrap, plugin block, the
    # raw `setopt …` line, banner source). Order matches the original file.
    initExtra = ''
      # ---- Options (no HM mapping; raw setopt) ----------------------------
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
      setopt INTERACTIVE_COMMENTS NO_BEEP PROMPT_SUBST
      setopt COMPLETE_IN_WORD ALWAYS_TO_END
      setopt HIST_REDUCE_BLANKS INC_APPEND_HISTORY

      # ---- bun ------------------------------------------------------------
      export BUN_INSTALL="$HOME/.bun"

      # ---- PATH -----------------------------------------------------------
      typeset -U path
      path=(
        $HOME/.local/bin
        $HOME/.opencode/bin
        $HOME/.bun/bin
        /usr/local/bin
        $path
      )
      # bun completions
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

      # ---- Zinit (plugin manager) -----------------------------------------
      ZINIT_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
      if [[ ! -d $ZINIT_HOME ]]; then
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null
      fi
      source "$ZINIT_HOME/zinit.zsh"

      # Annexes (recommended)
      zinit light-mode for \
        zdharma-continuum/zinit-annex-as-monitor \
        zdharma-continuum/zinit-annex-bin-gem-node \
        zdharma-continuum/zinit-annex-patch-dl \
        zdharma-continuum/zinit-annex-rust

      # Plugins -- turbo loaded after prompt for snappy startup
      zinit wait lucid for \
        atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
          zdharma-continuum/fast-syntax-highlighting \
        atload"_zsh_autosuggest_start" \
          zsh-users/zsh-autosuggestions \
        blockf atpull'zinit creinstall -q .' \
          zsh-users/zsh-completions \
        Aloxaf/fzf-tab

      # ---- Completion styling ---------------------------------------------
      zstyle ':completion:*' menu no
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:git-checkout:*' sort false
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath'

      # ---- Banner ---------------------------------------------------------
      if [[ -o interactive && -f "$HOME/.config/ainative/banner.sh" ]]; then
        source "$HOME/.config/ainative/banner.sh"
      fi
    '';
  };

  # ---- Tool-specific env (was at the bottom of .zshrc) -------------------
  home.sessionVariables = {
    BAT_THEME = "tokyonight_moon";
    OPENSPEC_TELEMETRY = "0";
    OPENCODE_ENABLE_EXA = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R --use-color -Dd+r$Du+b";
  };
}