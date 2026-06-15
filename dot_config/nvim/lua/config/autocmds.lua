-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- markdown 等で日本語に大量の波線が出るのを抑止する。
-- LazyVim の lazyvim_wrap_spell が markdown で spell=true にするが spelllang は en のまま。
-- spelllang に cjk を足すと Vim が CJK 文字をスペルチェック対象から除外する（波線が消える）。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_spelllang_cjk", { clear = true }),
  pattern = "markdown",
  callback = function()
    vim.opt_local.spelllang = "en,cjk"
  end,
})
