-- Ruby LSP only supports Ruby >= 3.0 (since ruby-lsp 0.6.0), so Ruby 2.x
-- projects fall back to solargraph 0.52.0, the last release supporting 2.6+.
-- Servers are launched via `mise x` so each project gets its own Ruby.
local majors = {}

local function ruby_major(root)
  if majors[root] == nil then
    local res = vim.system({ "mise", "current", "ruby" }, { cwd = root, text = true }):wait()
    majors[root] = tonumber((res.stdout or ""):match "(%d+)") or 0
  end
  return majors[root]
end

local function when_major(lo, hi)
  return function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "Gemfile", ".git" })
    if not root then return end
    local major = ruby_major(root)
    if major >= lo and major <= hi then on_dir(root) end
  end
end

-- Terminals spawned under Homebrew's Ruby inherit BUNDLER_VERSION (its own
-- bundler 4.x), which Bundler treats as mandatory and no project Ruby has.
local function mise(...)
  local args = { "env", "-u", "BUNDLER_VERSION", "mise", "x", "--", ... }
  return function(dispatchers, config)
    return vim.lsp.rpc.start(args, dispatchers, { cwd = config.cmd_cwd or config.root_dir })
  end
end

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    servers = { "ruby_lsp", "solargraph" },
    config = {
      ruby_lsp = {
        cmd = mise "ruby-lsp",
        root_dir = when_major(3, math.huge),
      },
      solargraph = {
        cmd = mise("solargraph", "stdio"),
        root_dir = when_major(0, 2),
      },
    },
  },
}
