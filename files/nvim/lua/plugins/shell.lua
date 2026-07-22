-- Use zsh as the shell for :terminal, :!, and toggleterm.
-- macOS path: /bin/zsh
return {
  "AstroNvim/astrocore",
  opts = {
    options = {
      opt = {
        shell = vim.fn.exepath("zsh") ~= "" and vim.fn.exepath("zsh") or vim.o.shell,
        shellcmdflag = "-c",
      },
    },
  },
}
