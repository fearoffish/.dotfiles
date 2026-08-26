return {
  "yetone/avante.nvim",
  opts = {
    provider = "claude",
    providers = {
      claude = { model = "claude-sonnet-5" },
    },
  },
  -- claudecode.nvim owns <leader>a, so move avante to <leader>A
  keys = {
    { "<leader>aa", false },
    { "<leader>ac", false },
    { "<leader>ae", false },
    { "<leader>af", false },
    { "<leader>ah", false },
    { "<leader>am", false },
    { "<leader>an", false },
    { "<leader>ap", false },
    { "<leader>ar", false },
    { "<leader>as", false },
    { "<leader>at", false },

    { "<leader>A", "", desc = "+avante", mode = { "n", "v" } },
    { "<leader>Aa", "<cmd>AvanteAsk<cr>", desc = "Ask Avante", mode = { "n", "v" } },
    { "<leader>Ac", "<cmd>AvanteChat<cr>", desc = "Chat with Avante" },
    { "<leader>Ae", "<cmd>AvanteEdit<cr>", desc = "Edit Avante", mode = { "n", "v" } },
    { "<leader>Af", "<cmd>AvanteFocus<cr>", desc = "Focus Avante" },
    { "<leader>Ah", "<cmd>AvanteHistory<cr>", desc = "Avante History" },
    { "<leader>Am", "<cmd>AvanteModels<cr>", desc = "Select Avante Model" },
    { "<leader>An", "<cmd>AvanteChatNew<cr>", desc = "New Avante Chat" },
    { "<leader>Ap", "<cmd>AvanteSwitchProvider<cr>", desc = "Switch Avante Provider" },
    { "<leader>Ar", "<cmd>AvanteRefresh<cr>", desc = "Refresh Avante" },
    { "<leader>As", "<cmd>AvanteStop<cr>", desc = "Stop Avante" },
    { "<leader>At", "<cmd>AvanteToggle<cr>", desc = "Toggle Avante" },
  },
}
