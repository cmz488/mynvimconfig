-- 状态栏：Apple 设计语言 —— 圆角卡片、柔和色彩、丰富图标
-- 使用柔和粉彩配色，每个组件独立色调
vim.o.laststatus = 3

-- 柔和粉彩色系 + 丰富的组件配色
local palette = {
    -- 柔和背景色（每个组件独立色调）
    mode_normal_bg = "#4a5f7a",      -- 柔和蓝灰
    mode_insert_bg = "#507a58",      -- 柔和绿灰
    mode_visual_bg = "#705a7a",      -- 柔和紫灰
    mode_replace_bg = "#7a5558",     -- 柔和红灰
    mode_command_bg = "#7a6a50",     -- 柔和橙灰
    mode_terminal_bg = "#507a7a",    -- 柔和青灰
    
    git_branch_bg = "#4f586b",       -- Git 分支区背景
    git_diff_bg = "#485566",         -- Git diff 背景
    diagnostic_bg = "#5a4f66",       -- 诊断信息背景
    filetype_bg = "#5f5466",         -- 文件类型背景
    location_bg = "#556070",         -- 位置信息背景
    
    -- 柔和前景色
    mode_normal_fg = "#b8d5f0",      -- 柔和蓝
    mode_insert_fg = "#b8e5c0",      -- 柔和绿
    mode_visual_fg = "#d8c8f0",      -- 柔和紫
    mode_replace_fg = "#f0b8c0",     -- 柔和红
    mode_command_fg = "#f0d8b8",     -- 柔和橙
    mode_terminal_fg = "#b8e5e5",    -- 柔和青
    
    git_branch_fg = "#f0c8a8",       -- Git 分支橙色
    git_added = "#a0d098",           -- Git 添加绿色
    git_modified = "#d8b078",        -- Git 修改橙色
    git_removed = "#f08888",         -- Git 删除红色
    
    diagnostic_error = "#f08888",    -- 错误红色
    diagnostic_warn = "#e8d088",     -- 警告黄色
    diagnostic_info = "#78b8f0",     -- 信息蓝色
    diagnostic_hint = "#78c8d0",     -- 提示青色
    
    text_primary = "#e8e8ea",        -- 主文本
    text_secondary = "#c5c5ca",      -- 次要文本
    text_tertiary = "#959599",       -- 三级文本
}

local function hex2rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function blend(fg, bg, alpha)
    local fr, fgg, fb = hex2rgb(fg)
    local br, bgg, bb = hex2rgb(bg)
    local function mix(a, b)
        return math.floor(a * alpha + b * (1 - alpha) + 0.5)
    end
    return string.format("#%02x%02x%02x", mix(fr, br), mix(fgg, bgg), mix(fb, bb))
end

-- 各模式的颜色配置
local mode_colors = {
    normal = { fg = palette.mode_normal_fg, bg = palette.mode_normal_bg },
    insert = { fg = palette.mode_insert_fg, bg = palette.mode_insert_bg },
    visual = { fg = palette.mode_visual_fg, bg = palette.mode_visual_bg },
    replace = { fg = palette.mode_replace_fg, bg = palette.mode_replace_bg },
    command = { fg = palette.mode_command_fg, bg = palette.mode_command_bg },
    terminal = { fg = palette.mode_terminal_fg, bg = palette.mode_terminal_bg },
}

-- 各模式的图标
local mode_icons = {
    normal = "󰊕",    -- 编辑图标
    insert = "󰙏",    -- 输入图标
    visual = "󰒉",    -- 选择图标
    replace = "󰛔",   -- 替换图标  
    command = "󰘳",   -- 命令图标
    terminal = "",   -- 终端图标
}

local function theme_mode(mode)
    return {
        -- 模式区：独立配色
        a = { 
            fg = mode_colors[mode].fg, 
            bg = mode_colors[mode].bg, 
            gui = "bold" 
        },
        -- 次要信息区
        b = { 
            fg = palette.text_secondary, 
            bg = palette.git_branch_bg 
        },
        -- 主内容区
        c = { 
            fg = palette.text_primary, 
            bg = "NONE" 
        },
    }
end

local theme = {
    normal = theme_mode("normal"),
    insert = theme_mode("insert"),
    visual = theme_mode("visual"),
    replace = theme_mode("replace"),
    command = theme_mode("command"),
    terminal = theme_mode("terminal"),
    inactive = {
        a = { fg = palette.text_tertiary, bg = "NONE" },
        b = { fg = palette.text_tertiary, bg = "NONE" },
        c = { fg = palette.text_tertiary, bg = "NONE" },
    },
}

-- 格式化模式名称并添加图标
local function format_mode()
    local mode = vim.fn.mode()
    local mode_map = {
        n = "Normal",
        i = "Insert",
        v = "Visual",
        V = "V-Line",
        ["\22"] = "V-Block",
        c = "Command",
        s = "Select",
        S = "S-Line",
        ["\19"] = "S-Block",
        R = "Replace",
        t = "Terminal",
    }
    local mode_name = mode_map[mode] or "Unknown"
    
    -- 根据模式获取图标
    local icon_map = {
        Normal = mode_icons.normal,
        Insert = mode_icons.insert,
        Visual = mode_icons.visual,
        ["V-Line"] = mode_icons.visual,
        ["V-Block"] = mode_icons.visual,
        Replace = mode_icons.replace,
        Command = mode_icons.command,
        Terminal = mode_icons.terminal,
    }
    local icon = icon_map[mode_name] or mode_icons.normal
    
    return icon .. "  " .. mode_name
end

require("lualine").setup({
    options = {
        theme = theme,
        globalstatus = true,
        icons_enabled = true,
        -- 使用圆形字符模拟圆角卡片
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        disabled_filetypes = { statusline = { "dashboard", "alpha" }, winbar = {} },
        refresh = { statusline = 100 },
    },
    sections = {
        -- 左侧：模式 + Git 信息
        lualine_a = {
            { 
                format_mode, 
                padding = { left = 2, right = 2 },
                separator = { right = "" },
            },
        },
        lualine_b = {
            { 
                "branch", 
                icon = { "", color = { fg = palette.git_branch_fg } },
                color = { fg = palette.text_primary, bg = palette.git_branch_bg },
                padding = { left = 2, right = 2 },
            },
            { 
                "diff", 
                symbols = { 
                    added = "  ", 
                    modified = "  ", 
                    removed = "  " 
                },
                diff_color = {
                    added = { fg = palette.git_added },
                    modified = { fg = palette.git_modified },
                    removed = { fg = palette.git_removed },
                },
                color = { fg = palette.text_secondary, bg = palette.git_diff_bg },
                padding = { left = 1, right = 2 },
                separator = { right = "" },
            },
        },
        -- 中间：文件信息
        lualine_c = {
            { 
                "filename", 
                path = 1,  -- 显示相对路径
                symbols = { 
                    modified = "  ", 
                    readonly = "  ", 
                    unnamed = "  ",
                    newfile = "  ",
                },
                color = { fg = palette.text_primary },
                padding = { left = 2, right = 1 },
            },
        },
        -- 右侧：诊断 + 文件类型 + 位置
        lualine_x = {
            {
                "diagnostics",
                sources = { "nvim_lsp" },
                colored = true,
                update_in_insert = false,
                symbols = { 
                    error = "  ", 
                    warn = "  ", 
                    info = "  ", 
                    hint = "  " 
                },
                diagnostics_color = {
                    error = { fg = palette.diagnostic_error },
                    warn = { fg = palette.diagnostic_warn },
                    info = { fg = palette.diagnostic_info },
                    hint = { fg = palette.diagnostic_hint },
                },
                color = { bg = palette.diagnostic_bg },
                padding = { left = 2, right = 2 },
                separator = { left = "" },
            },
        },
        lualine_y = {
            { 
                "filetype", 
                icons_enabled = true,
                icon_only = false,
                color = { fg = palette.text_primary, bg = palette.filetype_bg },
                padding = { left = 2, right = 2 },
            },
        },
        lualine_z = {
            {
                "progress",
                icon = "󰦨",
                color = { fg = palette.text_secondary, bg = palette.location_bg },
                padding = { left = 2, right = 1 },
            },
            { 
                "location",
                icon = "󰆤",
                color = { fg = palette.text_primary, bg = palette.location_bg },
                padding = { left = 1, right = 2 },
                separator = { left = "" },
            },
        },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 
            { 
                "filename", 
                path = 1,
                color = { fg = palette.text_tertiary },
            } 
        },
        lualine_x = { 
            { 
                "location",
                color = { fg = palette.text_tertiary },
            } 
        },
        lualine_y = {},
        lualine_z = {},
    },
    extensions = { "nvim-tree", "fzf", "nvim-dap-ui", "overseer" },
})
