local fzf = require("fzf-lua")


fzf.setup({
  "default",

  winopts = {
    height = 0.85,
    width = 0.85,
    row = 0.5,
    col = 0.5,
    border = "rounded",

    preview = {
      layout = "flex",
      vertical = "down:45%",
      horizontal = "right:55%",
    },
  },

  files = {
    fd_opts = table.concat({
      "--color=never",
      "--type=f",
      "--hidden",
      "--follow",
      "--exclude=.git",
      "--exclude=.idea",
      "--exclude=target",
      "--exclude=build",
      "--exclude=cmake-build-debug",
    }, " "),
  },

  grep = {
    rg_opts = table.concat({
      "--column",
      "--line-number",
      "--no-heading",
      "--color=always",
      "--smart-case",
      "--hidden",
      "--glob=!.git",
      "--glob=!.idea",
      "--glob=!target",
      "--glob=!build",
      "--glob=!cmake-build-debug",
    }, " "),
  },
})
