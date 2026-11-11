local map = vim.keymap.set
local fzf = require("fzf-lua")
local Snacks = require("snacks")
local buffers = require("core.buffers")
pcall(vim.keymap.del, "n", "grr")
pcall(vim.keymap.del, "n", "gri")
pcall(vim.keymap.del, "n", "grt")
pcall(vim.keymap.del, "n", "grn")
pcall(vim.keymap.del, "n", "grx")
pcall(vim.keymap.del, { "n", "x" }, "gra") -- gra 同时映射了 n 和 x
-- 文件
map("n", "<leader>fs", "<cmd>w<cr>", {
    desc = "保存文件",
})

map("n", "<leader>fq", "<cmd>q<cr>", {
    desc = "退出文件",
})

-- 缓冲区
-- 用 BufferLineCycleNext/Prev 而不是 :bnext/:bprevious：后者按 bufnr 走，
-- bufferline 排序或手动移动过位置后两者会不一致。
map("n", "<leader>bn", "<cmd>BufferLineCycleNext<cr>", {
    desc = "下一个缓冲区",
})

map("n", "<leader>bp", "<cmd>BufferLineCyclePrev<cr>", {
    desc = "上一个缓冲区",
})

map("n", "<leader>bd", function()
    buffers.delete()
end, {
    desc = "关闭当前缓冲区（保持窗口）",
})

map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", {
    desc = "关闭左侧缓冲区",
})

map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", {
    desc = "关闭右侧缓冲区",
})

map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", {
    desc = "关闭其它缓冲区",
})

map("n", "<leader>bc", "<cmd>BufferLinePickClose<cr>", {
    desc = "按键选择要关闭的缓冲区",
})

map("n", "<leader>bt", "<cmd>BufferLineTogglePin<cr>", {
    desc = "钉住/取消钉住当前缓冲区",
})

-- 真实调整缓冲区在标签栏里的位置（persist_buffer_sort 会把顺序记到 ShaDa 里）
map("n", "<leader>bK", "<cmd>BufferLineMovePrev<cr>", {
    desc = "缓冲区左移",
})

map("n", "<leader>bJ", "<cmd>BufferLineMoveNext<cr>", {
    desc = "缓冲区右移",
})

-- 按序号直达第 N 个可见缓冲区（对应 bufferline 的 numbers = "ordinal"）
for i = 1, 9 do
    map("n", "<leader>" .. i, ("<cmd>BufferLineGoToBuffer %d<cr>"):format(i), {
        desc = ("跳到第 %d 个缓冲区"):format(i),
    })
end

map("n", "<leader>0", "<cmd>BufferLineGoToBuffer -1<cr>", {
    desc = "跳到最后一个缓冲区",
})

-- 窗口
map("n", "<leader>wv", "<cmd>vsplit<cr>", {
    desc = "垂直分屏",
})

map("n", "<leader>wh", "<cmd>split<cr>", {
    desc = "水平分屏",
})
map("n", "<leader><leader>", function()
    fzf.files()
end, { desc = "搜索文件" })

-- 全局文本搜索
map("n", "<leader>fg", function()
    fzf.live_grep()
end, { desc = "全局文本搜索" })
-- LSP 引用搜索
map("n", "gr", function()
    Snacks.picker.lsp_references()
end, { desc = "查找引用" })
-- 智能文件搜索
map("n", "<leader>fs", function()
    Snacks.picker.smart()
end, { desc = "智能搜索" })
-- LSP 定义跳转
map("n", "gd", function()
    Snacks.picker.lsp_definitions()
end, { desc = "跳转定义" })
map("n", "<leader>fw", fzf.grep_cword, {
    desc = "搜索光标所在单词",
})

-- Buffer
map("n", "<leader>fb", fzf.buffers, {
    desc = "搜索缓冲区",
})

-- Git
map("n", "<leader>gs", fzf.git_status, {
    desc = "Git 状态",
})

map("n", "<leader>gc", fzf.git_commits, {
    desc = "Git 提交记录",
})
-- 其他
map("n", "<leader>fh", fzf.helptags, {
    desc = "搜索帮助文档",
})

map("n", "<leader>fk", fzf.keymaps, {
    desc = "搜索快捷键",
})


map("n", "<leader>e", function()
    local api = require("nvim-tree.api")

    -- 树开着但焦点在编辑窗口时先聚焦，避免一次按键就把树关掉
    if api.tree.is_visible() and not api.tree.is_tree_buf(0) then
        api.tree.focus()
        return
    end

    -- 打开时自动在树里定位到当前文件，关闭时直接收起
    api.tree.toggle({ find_file = true })
end, {
    desc = "打开、聚焦或关闭文件树",
})
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>",
    {
        desc = "上一个 buffer",
    })

map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>",
    {
        desc = "下一个 buffer",
    })


map({ "v", "n", "i" }, "<C-s>", "<cmd>w<cr>", { desc = "文件保存" })


map("n", "<leader>bb", "<cmd>BufferLinePick<cr>", { desc = "通过首字母自动跳转到对应buffer" })


-- 全局诊断列表
map("n", "<leader>xx", function() Snacks.picker.diagnostics() end, { desc = "全局诊断" })
map("n", "<leader>xX", function() Snacks.picker.diagnostics_buffer() end, { desc = "当前缓冲区诊断" })

-- 单行浮窗 + 跳转（LazyVim 同款）
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "当前行诊断" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "下一个诊断" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "上一个诊断" })
map("n", "]e", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "下一个错误" })
