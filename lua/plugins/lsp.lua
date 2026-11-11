vim.pack.add {
    { src = 'https://github.com/neovim/nvim-lspconfig' },
}
require("core.mason-path").ensure()

-- 诊断显示。原先在 lua/core/lsp.lua，该文件从未被加载、且依赖不存在的
-- lua/plugins/snacks.lua，已删除，其中的能力并入本文件。
vim.diagnostic.config({
    virtual_text = true,
    virtual_lines = false,
    severity_sort = true,     -- 列表和 virtual text 都按严重度排序
    update_in_insert = false, -- 插入模式下不刷新诊断，避免光标乱跳
    float = { source = true },
})

local rust_home = vim.env.HOME or ""
local rust_cargo_home = vim.env.CARGO_HOME or vim.fs.joinpath(rust_home, ".cargo")
local rust_rustup_home = vim.env.RUSTUP_HOME or vim.fs.joinpath(rust_home, ".rustup")
local rust_bin = vim.fs.joinpath(rust_cargo_home, "bin")
local rust_analyzer_bin = vim.fs.joinpath(rust_bin, "rust-analyzer")
if vim.fn.executable(rust_analyzer_bin) ~= 1 then
    rust_analyzer_bin = "rust-analyzer"
end

local path_sep = vim.fn.has("win32") == 1 and ";" or ":"

local stm32_cubeclt = vim.fs.joinpath(vim.env.HOME or "", "st")
local clangd_query_driver = table.concat({
    "/usr/bin/cc",
    "/usr/bin/c++",
    "/usr/bin/gcc*",
    "/usr/bin/g++*",
    "/usr/bin/clang*",
    "/usr/bin/arm-none-eabi-g*",
    stm32_cubeclt .. "/stm32cubeclt_*/GNU-tools-for-STM32/bin/arm-none-eabi-g*",
}, ",")
-- qml lsp peizhi
local qmlls_bin = "/usr/lib/qt6/bin/qmlls"
local servers = {
    qmlls = {
        cmd = { qmlls_bin, "-I", "/usr/lib/qt6/qml" },
        filetypes = {
            "qml", "qmljs"
        },
        root_markers = {
            "shell.qml", ".git"
        },

    },
    clangd = {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--query-driver=" .. clangd_query_driver,
        },
        cmd_env = {
            LC_ALL = "C",
        },
        filetypes = { "c", "cpp" },
        root_markers = {
            "compile_commands.json",
            "CMakeLists.txt",
            ".git",
        },
    },

    lua_ls = {
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
    },

    -- Python：只启用 ruff（lint + format）。ruff 不做类型检查与定义跳转，
    -- 需要时把 mason 里的 basedpyright 按同样格式加进来即可。
    ruff = {
        cmd = { "ruff", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
    },

    bashls = {
        cmd = { "bash-language-server", "start" },
        filetypes = { "bash", "sh" },
        root_markers = { ".git" },
        settings = {
            bashIde = {
                -- 上游默认 **/*@(.sh|.inc|.bash|.command) 会在直接打开家目录下的
                -- 脚本时递归扫描整个家目录，这里限制成当前目录一层。
                globPattern = "*@(.sh|.inc|.bash|.command)",
            },
        },
    },

    marksman = {
        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".marksman.toml", ".git" },
    },

    yamlls = {
        cmd = { "yaml-language-server", "--stdio" },
        filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
        root_markers = { ".git" },
        settings = {
            redhat = { telemetry = { enabled = false } },
        },
    },

    jsonls = {
        cmd = { "vscode-json-language-server", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { ".git" },
        init_options = { provideFormatter = true },
    },

    vtsls = {
        cmd = { "vtsls", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = {
            "package-lock.json",
            "yarn.lock",
            "pnpm-lock.yaml",
            "bun.lockb",
            "bun.lock",
            ".git",
        },
        init_options = { hostInfo = "neovim" },
    },

    neocmakelsp = {
        cmd = { "neocmakelsp", "stdio" },
        filetypes = { "cmake" },
        root_markers = { ".neocmake.toml", ".git", "build", "cmake" },
    },

    rust_analyzer = {
        cmd = { rust_analyzer_bin },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json", ".git", ".Cargo" },
        cmd_env = {
            CARGO_HOME = rust_cargo_home,
            RUSTUP_HOME = rust_rustup_home,
            PATH = rust_bin .. path_sep .. (vim.env.PATH or ""),
        },
    },
}

for name, config in pairs(servers) do
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
end

local lsp_group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })
local highlight_group = vim.api.nvim_create_augroup("UserLspDocumentHighlight", { clear = false })

-- 取光标所在位置最内层的 documentSymbol，供 [f / ]f 使用
local function find_enclosing_symbol(bufnr)
    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
    if not responses then
        return nil
    end

    local line = vim.api.nvim_win_get_cursor(0)[1] - 1

    local function find(symbols)
        for _, symbol in ipairs(symbols) do
            local range = symbol.range or (symbol.location and symbol.location.range)
            if range and line >= range.start.line and line <= range["end"].line then
                local child = symbol.children and find(symbol.children)
                return child or symbol
            end
        end
    end

    for _, response in pairs(responses) do
        local symbol = find(response.result or {})
        if symbol and symbol.range then
            return symbol
        end
    end
end

local function jump_to_enclosing_symbol(edge)
    local symbol = find_enclosing_symbol(0)
    if not symbol then
        return
    end

    local line = edge == "start" and symbol.range.start.line or symbol.range["end"].line
    vim.api.nvim_win_set_cursor(0, { line + 1, 0 })
end

-- 只能注册一次：LspAttach 里重复注册会互相覆盖 augroup
vim.api.nvim_create_autocmd("LspDetach", {
    group = lsp_group,
    callback = function(event)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = event.buf })
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        local opts = {
            buffer = event.buf,
            silent = true,
        }
        -- 这里没有配置gr gd gD,走snacks的快捷键
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
        end, opts)


        if client:supports_method("textDocument/documentSymbol") then
            vim.keymap.set("n", "[f", function()
                jump_to_enclosing_symbol("start")
            end, { buffer = event.buf, desc = "Jump to start of current function" })
            vim.keymap.set("n", "]f", function()
                jump_to_enclosing_symbol("end")
            end, { buffer = event.buf, desc = "Jump to end of current function" })
        end

        if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            vim.keymap.set("n", "<leader>th", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, { buffer = event.buf, desc = "LSP: Toggle Inlay Hints" })
        end

        -- LSP 折叠。core/options.lua 没有配置任何 fold* 选项，foldlevel 默认是 0：
        -- 只设 foldexpr 不设 foldmethod 是完全无效的（原 core/lsp.lua 就是这样），
        -- 而设了 foldmethod 又不设 foldlevel 会导致文件一打开就全部折叠，
        -- 因此这里显式给 foldlevel = 99 —— 折叠可用，但默认全部展开。
        --
        -- 例外：缓冲区已经把折叠交给 treesitter 时（见 plugins/treesitter.lua 的
        -- Rust 分支，会置 vim.b.treesitter_folds）不让 LSP 覆盖它。
        if
            client:supports_method("textDocument/foldingRange")
            and not vim.b[event.buf].treesitter_folds
        then
            local win = vim.api.nvim_get_current_win()
            vim.wo[win][0].foldmethod = "expr"
            vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
            vim.wo[win][0].foldlevel = 99
        end

        -- 光标停留时高亮同名符号
        if
            client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight)
            and vim.bo[event.buf].filetype ~= "bigfile"
        then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = highlight_group,
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                group = highlight_group,
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})
