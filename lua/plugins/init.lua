local gh = function(repo, name)
    local label = {
        src = "https://github.com/" .. repo,
        name = name
    }
    return label
end

vim.pack.add({
    gh("folke/which-key.nvim", "which-key"),
    gh("folke/tokyonight.nvim", "tokyonight"),
    gh("nvim-lualine/lualine.nvim", "lualine"),
    gh("ibhagwan/fzf-lua", "fzf"),
    gh("Saghen/blink.lib", "blink.lib"),
    gh("Saghen/blink.cmp", "blink.cmp"),
    -- nvim-dap 由 lua/plugins/dap.lua 按 FileType 延迟加载，此处不要重复声明
    gh("stevearc/overseer.nvim", "overseer"),
    gh("nvim-tree/nvim-web-devicons", "nvim-icon"),
    gh("nvim-tree/nvim-tree.lua", "nvim-tree"),
    gh("akinsho/bufferline.nvim", "bufferline"),
    gh("xiyaowong/transparent.nvim", "transparent"),
    gh("catppuccin/nvim", "catppuccin"),
    gh("windwp/nvim-autopairs", "autopairs"),
    gh("OXY2DEV/markview.nvim", "markview"),
    -- 暴露编辑器状态给 pi 的 /ide(/tmp/pi-ide/<pid>.json),plugin/pi-ide.lua 自带 setup
    gh("Andy8647/pi-ide-context", "pi-ide-context")
})
require("plugins.theme")
require("plugins.snacks")
require("plugins.nvim-tree")
require("plugins.mini")
require("plugins.fzf")
require("plugins.lsp")
require("plugins.bufferline")
require("plugins.lualine")
require("plugins.blink")
require("plugins.markview")
require("plugins.autopairs")
-- require("plugins.TODO-comment")
require("plugins.treesitter")
require("plugins.dap")
require("plugins.cmake")
require("plugins.emberprobe")
require("plugins.flash")
require("plugins.which-key")
