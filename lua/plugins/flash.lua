vim.pack.add({ "https://github.com/folke/flash.nvim" })
vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" },
    {
        pattern = "*",
        callback = function()
            local flash = require("flash")
            flash.setup({
                modes = {
                    char = {
                        enabled = true,
                        jump_labels = true,
                    },
                },
            })
        end
    }
)
