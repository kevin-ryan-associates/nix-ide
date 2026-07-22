-- Only render the virtual-env segment of the heirline statusline when the
-- venv path actually exists on disk. Stale `VIRTUAL_ENV` env vars (left
-- over from a venv directory that has since been deleted) would otherwise
-- leak the orphaned project name into the statusline of every nvim
-- instance launched from that shell, regardless of cwd.
return {
  "AstroNvim/astroui",
  opts = function(_, opts)
    local ok, provider = pcall(require, "astroui.status.provider")
    if not ok then return end
    local astro = require "astrocore"
    local ui = require "astroui"
    local status_utils = require "astroui.status.utils"
    local config = assert(ui.config.status)

    provider.virtual_env = function(o)
      o = astro.extend_tbl(vim.tbl_get(config, "providers", "virtual_env"), o)
      return function()
        local function venv_str(path_str)
          local parts = vim.fn.split(path_str, "/")
          local name = parts[#parts]
          if #parts > 1 and vim.tbl_contains(o.env_names, name) then return parts[#parts - 1] end
          return name
        end
        local venv = vim.env.VIRTUAL_ENV
        local conda = vim.env.CONDA_DEFAULT_ENV
        local env_str
        if venv then
          if not (vim.uv or vim.loop).fs_stat(venv) then return end
          env_str = venv_str(venv)
        elseif o.conda.enabled and conda then
          if conda ~= "base" or not o.conda.ignore_base then env_str = conda end
        end
        if env_str then
          return status_utils.stylize(o.format and o.format:format(env_str) or env_str, o)
        end
      end
    end
  end,
}