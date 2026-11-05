local wk = require("which-key")

wk.setup({
    preset = "modern",

    delay = 300,

    win = {
        border = "rounded",
        padding = { 1, 2 },
    },

    icons = {
        mappings = true,
    },
})

-- 注册快捷键分组��,
wk.add({
    { "<leader>f", group = "文件与搜索" },
    { "<leader>b", group = "缓冲区" },
    { "<leader>g", group = "Git" },
    { "<leader>c", group = "代码" },
    { "<leader>d", group = "调试" },
    { "<leader>r", group = "运行与构建" },
    { "<leader>t", group = "切换" },
    { "<leader>w", group = "窗口" },
    { "s", group = "搜索跳转或者sourround" }
})
