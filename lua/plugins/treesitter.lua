-- Neovim 只为 lua/markdown/help/query 自带了 vim.treesitter.start()
-- （见 $VIMRUNTIME/ftplugin/*.lua），其余文件类型必须显式启用，
-- 否则 parser 装了也不会有 treesitter 高亮。
-- 用 nvim_get_runtime_file 探测 parser 是否存在，避免让 pcall 承担正常控制流。
local function start_treesitter_highlight(buf)
    if vim.treesitter.highlighter.active[buf] then
        return
    end

    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if lang == nil or lang == "" then
        return
    end

    if #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0 then
        return
    end

    vim.treesitter.start(buf, lang)
end

vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup("SetupTreesitter", { clear = true }),
    once = true,
    callback = function()
        vim.pack.add({
            { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
            { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
        })
        -- 编译 parser 依赖 `tree-sitter build`，它只装在 mason 里，
        -- 需要先把 mason/bin 接进 PATH，否则 install()/:TSInstall 会 ENOENT。
        require("core.mason-path").ensure()

        -- 新版 main 分支的 setup() 只接受 install_dir（默认值已是 stdpath('data')/site），
        -- 旧 API 的 ensure_installed 已被移除且会被 tbl_deep_extend 静默吞掉，
        -- parser 安装必须改用 install()（已安装的语言会被跳过）。
        require("nvim-treesitter").install({ "diff", "snakemake", "rust" })
        require("core.treesitter-compat").setup()

        -- 必须在 nvim-treesitter 进入 runtimepath 之后注册：
        -- plugin/filetypes.lua 会补充 filetype -> language 的映射（如 ts -> typescript）。
        vim.api.nvim_create_autocmd("FileType", {
            group = "SetupTreesitter",
            pattern = "*",
            callback = function(ev)
                start_treesitter_highlight(ev.buf)
            end,
            desc = "启用 treesitter 语法高亮",
        })

        -- Rust 专属：语法树驱动的缩进与折叠（其它语言维持各自的默认缩进与 LSP foldingRange）。
        vim.api.nvim_create_autocmd("FileType", {
            group = "SetupTreesitter",
            pattern = "rust",
            callback = function(ev)
                local buf = ev.buf

                -- 覆盖 $VIMRUNTIME/indent/rust.vim 里基于正则的 GetRustIndent()。
                -- 引号形式是上游文档要求的：v:lua.require'nvim-treesitter'.indentexpr()
                -- 注意上游把 treesitter 缩进标注为 experimental。
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

                -- core/options.lua 没有任何 fold* 设置，foldlevel 默认是 0，
                -- 只设 foldmethod 会让 .rs 一打开就全部折叠，所以同时给 foldlevel = 99。
                local win = vim.api.nvim_get_current_win()
                vim.wo[win][0].foldmethod = "expr"
                vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[win][0].foldlevel = 99

                -- 告知 plugins/lsp.lua：本缓冲区的折叠已经交给 treesitter，
                -- 不要让 LSP 的 foldexpr 覆盖掉。
                vim.b[buf].treesitter_folds = true
            end,
            desc = "Rust: treesitter 缩进与折叠",
        })
        require("treesitter-context").setup({
            enable = false,
            separator = nil,
            max_lines = 5,
            multiwindow = true,
            min_window_height = 15,
            multiline_threshold = 2,
        })
        vim.api.nvim_set_hl(0, "TreesitterContext", { link = "CursorLine" }) -- remove existing link
        vim.api.nvim_set_hl(0, "TreesitterContextBottom", {
            -- underline = true,
            sp = "#b4befe",
        })
        vim.keymap.set("n", "<leader>tc", "<cmd>TSContext toggle<cr>")
        -- vim.api.nvim_set_hl(0, "TreesitterContextBottom", { link = "CursorLine" }) -- remove existing link
    end,
})
