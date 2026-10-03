vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--query-driver=/usr/bin/arm-none-eabi-*",
    },

    filetypes = { "c", "cpp" },

    root_markers = {
        "compile_commands.json",
        "CMakeLists.txt",
        ".git",
    },
})

vim.lsp.enable("clangd")
vim.lsp.config("lua_ls",
    {
        cmd = { "lua-language-server" },

        filetypes = { "lua" },

        root_markers = {
            ".luarc.json",
            ".luarc.jsonc",
            ".git",
        },

        settings = {
            Lua = {
                runtime = {
                    version = "LuaJIT",
                },

                diagnostics = {
                    globals = { "vim" },
                },

                workspace = {
                    checkThirdParty = false,
                    library = vim.api.nvim_get_runtime_file("", true),
                },

                telemetry = {
                    enable = false,
                },
            },
        },
    })

vim.lsp.enable("lua_ls")
local lsp_group = vim.api.nvim_create_augroup("UserLspConfig",{clear = true,})

vim.api.nvim_create_autocmd("LspAttach",
    {
        group = lsp_group,

        callback = function(event)
            local opts = {
                buffer = event.buf,
                silent = true,
            }

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>cf",
                function()
                    vim.lsp.buf.format({ async = true })
                end, opts)
        end,
    })
