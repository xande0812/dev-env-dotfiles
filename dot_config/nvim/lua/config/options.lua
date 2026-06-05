-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- clipboard: OSC52 を明示有効化 (managed by chezmoi)。
-- LazyVim は clipboard=unnamedplus なので全 yank が + レジスタ = system clipboard 行き。
-- nvim 0.10+ は SSH 検出時に自動で OSC52 を使うが、tmux 越しだと $SSH_TTY が伝わらず
-- 自動検出が発動しないことがあるため、provider を明示する。lazygit / tmux と同じく
-- nvim → tmux (set-clipboard on) → Ghostty と端末経由で手元クリップボードに載せる。
-- copy は確実。paste (OSC52 read) は端末側の clipboard-read 許可に依存し不安定なので
-- 過度に期待しない (通常の端末ペーストは影響なし)。
local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = osc52.copy("+"),
    ["*"] = osc52.copy("*"),
  },
  paste = {
    ["+"] = osc52.paste("+"),
    ["*"] = osc52.paste("*"),
  },
}
