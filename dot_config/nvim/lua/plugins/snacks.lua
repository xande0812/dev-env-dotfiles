return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          -- <leader>e で開く snacks explorer の挙動を上書きする。
          explorer = {
            actions = {
              -- nvim の cwd(起動ディレクトリ)からの相対パスを yank する。
              -- 既定の explorer_yank は item.file の絶対パスを yank するため、
              -- fnamemodify(_, ":.") で cwd 相対に変換したものを register へ入れる。
              yank_relative_path = function(picker)
                local items = picker:selected({ fallback = true })
                local paths = {}
                for _, item in ipairs(items) do
                  local full = Snacks.picker.util.path(item) or item.file
                  if full then
                    paths[#paths + 1] = vim.fn.fnamemodify(full, ":.")
                  end
                end
                if #paths == 0 then
                  return
                end
                local value = table.concat(paths, "\n")
                -- vim.v.register を尊重("ay 等)。clipboard=unnamedplus なので
                -- 既定レジスタへの書き込みは system clipboard にも同期される。
                vim.fn.setreg(vim.v.register, value)
                Snacks.notify.info("Yanked (relative):\n" .. value)
              end,
            },
            win = {
              list = {
                keys = {
                  -- y: cwd 相対パス / Y: 絶対パス(既定の explorer_yank)
                  ["y"] = { "yank_relative_path", mode = { "n", "x" } },
                  ["Y"] = { "explorer_yank", mode = { "n", "x" } },
                },
              },
            },
          },
        },
      },
    },
  },
}
