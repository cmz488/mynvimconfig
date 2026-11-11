local bk = require("blink.cmp")


bk.build():pwait()
-- 智能补全分析
local kinds = require("blink.cmp.types").CompletionItemKind

-- 补全排序分三档：
--   0 = 当前文件里已经出现过的词（Buffer 源）
--   1 = 类成员 / 对象（方法、字段、属性、变量）
--   nil = 不干预，交给 blink 默认的 score / sort_text
local RANK_FILE = 0
local RANK_MEMBER = 1

local member_kinds = {
    [kinds.Method] = true,
    [kinds.Field] = true,
    [kinds.Property] = true,
    [kinds.Variable] = true,
}

local function rank(item)
    if item.source_name == "Buffer" then
        return RANK_FILE
    end
    if member_kinds[item.kind] then
        return RANK_MEMBER
    end
end

local function priority_sort(a, b)
    local ra, rb = rank(a), rank(b)

    if ra == nil and rb == nil then
        return nil
    end
    if ra == nil then
        return false
    end
    if rb == nil then
        return true
    end
    if ra ~= rb then
        return ra < rb
    end
    return nil
end

bk.setup({
    appearance = {
        nerd_font_variant = "mono", -- 使用等宽 Nerd Font 图标

    },
    completion = {
        menu = {
            border = "rounded", -- 补全菜单的边框
            scrollbar = false,  -- 禁用滚动条指示器
            -- 跟 hover 浮窗统一：粉色边框、透明背景。
            -- blink 自己会为这些组设默认链接，必须直接覆盖而不是链接。
            winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None,CurSearch:None",
        },
        documentation = {
            window = {
                border = "rounded", -- 文档窗口的边框
                winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc,Separator:BlinkCmpDocSeparator",
            },
        },
    },
    signature = {
        -- 签名窗口由 noice 渲染（自动触发和文档渲染都在那边），
        -- blink 自己这个保持关闭，否则两个窗口会同时弹出。
        enabled = false,
        window = {
            border = "rounded", -- 签名帮助窗口的边框
            winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
        },
    },
    sources = {
        -- 补全来源：LSP、文件路径、代码片段、当前缓冲区
        default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
        -- 使用rust
        implementation = "prefer_rust_with_warning",
        -- 先按上面的三档优先级分，同档内交给 blink 默认的 score / sort_text。
        sorts = {
            priority_sort,
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
