return {
    enabled = true,

    -- 页面宽度
    width = 65,

    preset = {
        -- 自定义 Logo
        header = [[
    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██║   ██║██║████╗ ████║
    ██╔██╗ ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
        ]],

        -- 首页快捷键
        keys = {
            {
                icon = " ",
                key = "f",
                desc = "搜索文件",
                action = function()
                    Snacks.picker.files()
                end,
            },
            {
                icon = " ",
                key = "n",
                desc = "新建文件",
                action = ":ene | startinsert",
            },
            {
                icon = " ",
                key = "g",
                desc = "全局文本搜索",
                action = function()
                    Snacks.picker.grep()
                end,
            },
            {
                icon = " ",
                key = "r",
                desc = "最近文件",
                action = function()
                    Snacks.picker.recent()
                end,
            },
            {
                icon = " ",
                key = "c",
                desc = "Neovim 配置",
                action = function()
                    Snacks.picker.files({
                        cwd = vim.fn.stdpath("config"),
                    })
                end,
            },
            {
                icon = " ",
                key = "q",
                desc = "退出",
                action = ":qa",
            },
        },
    },

    -- 首页布局
    sections = {
        { section = "header", padding = 1 },

        { section = "keys",   gap = 1,    padding = 1 },

        {
            icon = " ",
            title = "最近文件",
            section = "recent_files",
            limit = 5,
            indent = 2,
            padding = 1,
        },

        {
            icon = " ",
            title = "最近项目",
            section = "projects",
            limit = 5,
            indent = 2,
            padding = 1,
        },

        {
            icon = " ",
            title = "Git 状态",
            section = "terminal",
            enabled = function()
                return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch",
            height = 5,
            padding = 1,
            ttl = 300,
        },
    },
}
