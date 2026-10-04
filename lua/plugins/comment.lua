-- 创建一个自动命令组，避免重复定义
local augroup = vim.api.nvim_create_augroup("CommentNvimLazyLoad", { clear = true })

-- 定义触发加载的事件
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = augroup,
    -- 只执行一次，避免每次打开文件都重复加载
    once = true,
    callback = function()
        -- 1. 声明并安装插件
        vim.pack.add({
            {
                src = "https://github.com/numToStr/Comment.nvim"
            }
        })

        -- 2. 插件加载后，进行初始化配置
        require("Comment").setup({
            ignore = '^$', -- 忽略空行
        })
    end,
})
