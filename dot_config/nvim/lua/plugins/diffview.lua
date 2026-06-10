local review_base_ref = "origin/HEAD"

local function review_merge_base()
  local result = vim.fn.systemlist({ "git", "merge-base", review_base_ref, "HEAD" })
  if vim.v.shell_error ~= 0 or result[1] == nil or result[1] == "" then
    vim.notify("Failed to resolve merge-base for " .. review_base_ref .. " and HEAD", vim.log.levels.ERROR)
    return nil
  end

  return result[1]
end

local function change_gitsigns_base(base)
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.change_base(base, true)
  end
end

local function reset_gitsigns_base()
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.reset_base(true)
  end
end

local function open_review_diffview()
  local base = review_merge_base()
  if not base then
    return
  end

  change_gitsigns_base(base)
  vim.cmd("DiffviewOpen " .. review_base_ref .. "...HEAD")
end

local function close_review_diffview()
  reset_gitsigns_base()
  vim.cmd("DiffviewClose")
end

return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gdf", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gdm", open_review_diffview, desc = "Diff against origin/HEAD" },
      { "<leader>gdc", close_review_diffview, desc = "Close Diffview and reset base" },
      { "<leader>gdr", reset_gitsigns_base, desc = "Reset Gitsigns diff base" },
    },
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      numhl = true,
    },
  },
}
