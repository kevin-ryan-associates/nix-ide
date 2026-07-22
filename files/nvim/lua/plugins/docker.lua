-- Dockerfile support: syntax highlighting (treesitter), LSP (docker-language-server),
-- and linting (hadolint) via the AstroCommunity docker pack.
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.docker" },
}
