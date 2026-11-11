-- 状态栏：单条全局栏（贴屏幕底边）+ 圆角模式胶囊 + 三级灰阶文字
vim.o.laststatus = 3

local palette = {
    crust = "#11111b",
    mantle = "#181825",
    overlay0 = "#6c7086",
    subtext0 = "#a6adc8",
    text = "#cdd6f4",
    blue = "#89b4fa",
    green = "#a6e3a1",
    mauve = "#cba6f7",
    red = "#f38ba8",
    peach = "#fab387",
    teal = "#94e2d5",
}

-- 模式色块不写死，按比例混进底板，得到"被染色玻璃"而不是实心色带
local CHIP_ALPHA = 0.2

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

local accents = {
    normal = palette.blue,
    insert = palette.green,
    visual = palette.mauve,
    replace = palette.red,
    command = palette.peach,
    terminal = palette.teal,
}

local chip = {}
for mode, accent in pairs(accents) do
    chip[mode] = blend(accent, palette.crust, CHIP_ALPHA)
end

local function theme_mode(mode)
    return {
        a = { fg = accents[mode], bg = chip[mode], gui = "bold" },
        b = { fg = palette.subtext0, bg = palette.crust },
        c = { fg = palette.text, bg = palette.crust },
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
        a = { fg = palette.overlay0, bg = palette.mantle },
        b = { fg = palette.overlay0, bg = palette.mantle },
        c = { fg = palette.overlay0, bg = palette.mantle },
    },
}

-- V-LINE -> V-Line，NORMAL -> Normal
local function titleize(label)
    return (label:lower():gsub("(%a)([%w]*)", function(a, b)
        return a:upper() .. b
    end))
end

-- 胶囊两端要跟着当前模式变色，所以颜色在渲染时求值
local function current_accent()
    local mode = vim.fn.mode(1):sub(1, 1)
    local map = {
        n = palette.blue,
        i = palette.green,
        v = palette.mauve,
        V = palette.mauve,
        ["\22"] = palette.mauve,
        R = palette.red,
        c = palette.peach,
        t = palette.teal,
    }
    return map[mode] or palette.blue
end

local function cap(glyph)
    return {
        function()
            return glyph
        end,
        padding = 0,
        draw_empty = true,
        color = function()
            return { fg = blend(current_accent(), palette.crust, CHIP_ALPHA), bg = palette.crust }
        end,
    }
end

require("lualine").setup({
    options = {
        theme = theme,
        globalstatus = true,
        icons_enabled = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "dashboard", "alpha" }, winbar = {} },
        refresh = { statusline = 100 },
    },
    sections = {
        lualine_a = {
            cap(""),
            {
                "mode",
                fmt = function(s)
                    return titleize(s)
                end,
                padding = { left = 1, right = 1 },
            },
            cap(""),
        },
        lualine_b = {
            { "branch", icon = "" },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
        },
        lualine_c = {
            { "filename", path = 0, symbols = { modified = " ●", readonly = " ", unnamed = "" } },
        },
        lualine_x = {
            {
                "diagnostics",
                sources = { "nvim_lsp" },
                colored = true,
                update_in_insert = false,
                symbols = { error = " ", warn = " ", info = " ", hint = "" },
            },
        },
        lualine_y = {
            { "filetype", icons_enabled = false },
            {
                "encoding",
                fmt = function(s)
                    return s:lower()
                end,
            },
        },
        lualine_z = { "location" },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 0 } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },
    extensions = { "nvim-tree", "fzf", "nvim-dap-ui", "overseer" },
})
