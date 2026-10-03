local gh = function(repo)
    return "https://github.com/" .. repo
end

vim.pack.add({
    gh("folke/which-key.nvim"),
    gh("folke/tokyonight.nvim"),
    gh("nvim-lualine/lualine.nvim"),
    gh("ibhagwan/fzf-lua"),
    gh("Saghen/blink.lib"),
    gh("Saghen/blink.cmp"),
    gh("nvim-treesitter/nvim-treesitter"),
    gh("mfussenegger/nvim-dap"),
    gh("stevearc/overseer.nvim"),
    gh("nvim-tree/nvim-web-devicons"),
    gh("nvim-tree/nvim-tree.lua"),
    gh("akinsho/bufferline.nvim"),
})
require("plugins.theme")
require("plugins.fzf")
require("plugins.which-key")
require("plugins.lsp")

require("plugins.nvim-tree")
require("plugins.bufferline")
require("plugins.lualine")
