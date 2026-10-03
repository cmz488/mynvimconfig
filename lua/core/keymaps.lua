local map = vim.keymap.set
local fzf = require("fzf-lua")
local tree = require("nvim-tree.api")
-- 文件
map("n", "<leader>fs", "<cmd>w<cr>", {
    desc = "保存文件",
})

map("n", "<leader>fq", "<cmd>q<cr>", {
    desc = "退出文件",
})

-- 缓冲区
map("n", "<leader>bn", "<cmd>bnext<cr>", {
    desc = "下一个缓冲区",
})

map("n", "<leader>bp", "<cmd>bprevious<cr>", {
    desc = "上一个缓冲区",
})

map("n", "<leader>bd", "<cmd>bdelete<cr>", {
    desc = "关闭缓冲区",
})

-- 窗口
map("n", "<leader>wv", "<cmd>vsplit<cr>", {
    desc = "垂直分屏",
})

map("n", "<leader>wh", "<cmd>split<cr>", {
    desc = "水平分屏",
})

-- fzf
map("n", "<leader>ff", fzf.files, {
    desc = "查找文件",
})

map("n", "<leader>fg", fzf.live_grep, {
    desc = "全局文本搜索",
})

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
map("n", "<leader>ga", "<cmd>!git add .", { desc = "Git add" })

map("n", "<leader>gc", "<cmd>!git commit -m\"\"", { desc = "Git commit" })
-- 其他
map("n", "<leader>fh", fzf.helptags, {
    desc = "搜索帮助文档",
})

map("n", "<leader>fk", fzf.keymaps, {
    desc = "搜索快捷键",
})


map("n", "<leader>e", function()
    local api = require("nvim-tree.api")
    local view = require("nvim-tree.view")

    if not view.is_visible() then
        api.tree.open()
        api.tree.focus()
    elseif vim.bo.filetype == "NvimTree" then
        api.tree.close()
    else
        api.tree.focus()
    end
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


map("n", "<C-s>", "<cmd>w<cr>", { desc = "文件保存" })


map("n", "<leader>bp", "<cmd>BufferLinePick<cr>", { desc = "通过首字母自动跳转到对应buffer" })
