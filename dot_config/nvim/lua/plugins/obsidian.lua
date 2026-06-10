return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cmd = "Obsidian",
    ft = "markdown",
    keys = {
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New Obsidian note" },
      { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch Obsidian note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search Obsidian notes" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Show Obsidian backlinks" },
      { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Open today's Obsidian note" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image into Obsidian note" },
    },
    ---@module "obsidian"
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "default",
          path = "~/obvault",
        },
      },
      picker = {
        name = "snacks.picker",
      },
    },
  },
}
