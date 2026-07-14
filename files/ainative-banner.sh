#!/usr/bin/env zsh
# ainative startup banner -- shown once per interactive shell session.
# Disable with: export AINATIVE_NO_BANNER=1

[[ -n "$AINATIVE_NO_BANNER" ]] && return 0
[[ -n "$AINATIVE_BANNER_SHOWN" ]] && return 0
# Skip the banner when running inside Neovim's :terminal / :! / toggleterm.
[[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]] && return 0
export AINATIVE_BANNER_SHOWN=1

# Clear the screen before rendering for a clean stage on every launch.
# Use ANSI escape directly so it works even when TERM is unset (e.g. some
# non-interactive shells docker spawns).
if [[ -t 1 ]]; then
  if [[ -n "$TERM" ]] && command -v clear >/dev/null 2>&1; then
    clear
  else
    printf '\e[H\e[2J\e[3J'
  fi
fi

# Tokyo Night Moon palette.
local C_BLUE=$'\e[38;2;130;170;255m'      # #82aaff
local C_BLUE_D=$'\e[38;2;96;140;235m'     # deep blue
local C_CYAN=$'\e[38;2;134;225;252m'      # #86e1fc
local C_CYAN_D=$'\e[38;2;100;190;230m'     # deep cyan
local C_GREEN=$'\e[38;2;195;232;141m'     # #c3e88d
local C_PURPLE=$'\e[38;2;192;153;255m'    # #c099ff
local C_TEXT=$'\e[38;2;200;211;245m'      # #c8d3f5
local C_DIM=$'\e[38;2;99;109;166m'        # #636da6
local BOLD=$'\e[1m'
local DIM=$'\e[2m'
local RST=$'\e[0m'

# "AI NATIVE" rendered in ANSI Shadow style, all in Tokyo Night blue.
print
print "${C_BLUE} █████╗ ██╗${C_DIM}    ${C_BLUE}███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗${RST}"
print "${C_BLUE}██╔══██╗██║${C_DIM}    ${C_BLUE}████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝${RST}"
print "${C_BLUE}███████║██║${C_DIM}    ${C_BLUE}██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗  ${RST}"
print "${C_BLUE_D}██╔══██║██║${C_DIM}    ${C_BLUE_D}██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝  ${RST}"
print "${C_BLUE_D}██║  ██║██║${C_DIM}    ${C_BLUE_D}██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗${RST}"
print "${C_DIM}╚═╝  ╚═╝╚═╝    ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝${RST}"
print

# Sub-banner: tools / versions
local nvim_v=$(nvim --version 2>/dev/null | head -n 1 | awk '{print $2}')
local zsh_v=$ZSH_VERSION
local node_v=$(node -v 2>/dev/null)
local py_v=$(python3 -V 2>/dev/null | awk '{print $2}')

print "  ${BOLD}${C_CYAN}»${RST} ${C_TEXT}nvim${RST} ${C_DIM}${nvim_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}zsh${RST} ${C_DIM}${zsh_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}node${RST} ${C_DIM}${node_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}python${RST} ${C_DIM}${py_v}${RST}"
print "  ${DIM}${C_DIM}// ai-native development environment${RST}"
print
