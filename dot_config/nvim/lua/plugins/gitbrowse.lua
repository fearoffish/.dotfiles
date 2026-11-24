local function copy_git_url()
  require("snacks").gitbrowse {
    open = function(url)
      vim.fn.setreg("+", url)
      vim.notify(url, vim.log.levels.INFO, { title = "Copied git URL" })
    end,
    notify = false,
  }
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = { ["<Leader>gy"] = { copy_git_url, desc = "Copy git URL" } },
      x = { ["<Leader>gy"] = { copy_git_url, desc = "Copy git URL" } },
    },
  },
}
