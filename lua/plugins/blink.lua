local bk = require("blink.cmp")


bk.build():pwait()
-- 智能补全分析
local kinds = require("blink.cmp.types").CompletionItemKind

local weights = {
    cpp = {
        [kinds.Method] = 1,
        [kinds.Field] = 2,
        [kinds.Property] = 2,
        [kinds.Class] = 3,
        [kinds.Struct] = 3,
        [kinds.Constructor] = 4,
        [kinds.Function] = 5,
        [kinds.Variable] = 6,
        [kinds.Module] = 7,
        [kinds.Keyword] = 8,
    },

    rust = {
        [kinds.Method] = 1,
        [kinds.Field] = 2,
        [kinds.Struct] = 3,
        [kinds.Interface] = 4,
        [kinds.Function] = 5,
        [kinds.Variable] = 6,
        [kinds.Module] = 7,
        [kinds.Keyword] = 8,
    },

    python = {
        [kinds.Method] = 1,
        [kinds.Property] = 2,
        [kinds.Field] = 2,
        [kinds.Class] = 3,
        [kinds.Function] = 4,
        [kinds.Variable] = 5,
        [kinds.Module] = 6,
        [kinds.Keyword] = 7,
    },

    c = {
        [kinds.Function] = 1,
        [kinds.Variable] = 2,
        [kinds.Struct] = 3,
        [kinds.Enum] = 4,
        [kinds.Field] = 5,
        [kinds.Keyword] = 6,
    },

    lua = {
        [kinds.Method] = 1,
        [kinds.Function] = 2,
        [kinds.Field] = 3,
        [kinds.Property] = 3,
        [kinds.Module] = 4,
        [kinds.Variable] = 5,
        [kinds.Keyword] = 6,
    },
}

local function get_weight(item, lang)
    local label = item.label or ""
    local config = weights[lang] or {}
    local weight = config[item.kind] or 7

    -- 降低内部标识符优先级
    if label:match("^__") then
        weight = weight + 8
    elseif label:match("^_") then
        weight = weight + 3
    end

    -- 降低宏优先级
    if item.kind == kinds.Constant
        and label:match("^[A-Z][A-Z%d_]+$") then
        weight = weight + 5
    end

    -- Lua 中提升 Neovim API
    if lang == "lua" then
        if label:match("^nvim_") then
            weight = math.min(weight, 1)
        elseif label == "vim" then
            weight = 1
        end
    end

    return weight
end

local function semantic_sort(a, b)
    local lang = vim.bo.filetype

    if lang == "c++" then
        lang = "cpp"
    end

    local wa = get_weight(a, lang)
    local wb = get_weight(b, lang)

    if wa ~= wb then
        return wa < wb
    end

    return nil
end

bk.setup({
    appearance = {
        nerd_font_variant = "mono", -- 使用等宽 Nerd Font 图标

    },
    sources = {
        -- 补全来源：LSP、文件路径、代码片段、当前缓冲区
        default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
        -- 使用rust
        implementation = "prefer_rust_with_warning",
        sorts = {
            "exact",
            semantic_sort,
            "score",
            "sort_text",
        },

    },
    cmdline = {
        keymap = { preset = 'inherit' },
        completion = {
            menu = { auto_show = true },
            ghost_text = { enabled = true }

        },

    },


    keymap = {
        preset = "super-tab",
    },
})
