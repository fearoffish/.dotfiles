-- Ruby LSP only supports Ruby >= 3.0 (since ruby-lsp 0.6.0), so Ruby 2.7
-- projects fall back to solargraph 0.52.0, the last release supporting 2.6+.
-- Servers are launched via `mise x` so each project gets its own Ruby.
local cache = {}

local function ruby_major(root)
  if cache[root] == nil then
    local res = vim.system({ "mise", "current", "ruby" }, { cwd = root, text = true }):wait()
    cache[root] = tonumber((res.stdout or ""):match("(%d+)")) or 0
  end
  return cache[root]
end

local function when_major(lo, hi)
  return function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "Gemfile", ".git" })
    if not root then
      return
    end
    local m = ruby_major(root)
    if m >= lo and m <= hi then
      on_dir(root)
    end
  end
end

-- Mason's bin dir sits ahead of the mise Ruby on PATH and its binstubs hardcode
-- a shebang, so resolve the executable to an absolute path per project first.
local bins = {}

local function resolve(bin, cwd)
  local key = bin .. "\0" .. (cwd or "")
  if bins[key] == nil then
    local res = vim.system({ "mise", "which", bin }, { cwd = cwd, text = true }):wait()
    local path = vim.trim(res.stdout or "")
    bins[key] = (res.code == 0 and path ~= "") and path or false
  end
  return bins[key]
end

local function mise(bin, ...)
  local args = { ... }
  return function(dispatchers, config)
    local cwd = config and (config.cmd_cwd or config.root_dir)
    local argv = { "mise", "x", "--", resolve(bin, cwd) or bin }
    vim.list_extend(argv, args)
    return vim.lsp.rpc.start(argv, dispatchers, { cwd = cwd })
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    ---@type PluginLspOpts
    opts = {
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = mise("ruby-lsp"),
          root_dir = when_major(3, 99),
        },
        solargraph = {
          enabled = true,
          mason = false,
          cmd = mise("solargraph", "stdio"),
          root_dir = when_major(0, 2),
        },
        rubocop = {
          mason = false,
          cmd = mise("bundle", "exec", "rubocop", "--lsp"),
        },
      },
    },
  },
}
