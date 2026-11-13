-- pi.nvim: pi coding agent 的 Neovim 前端
-- 键位约定: <leader>a 组全部留给 pi, 避开已占用的 d(调试)/c(代码)/f(文件)
local ok, pi = pcall(require, "pi")
if not ok then
    vim.notify("pi.nvim 未安装, 跳过加载", vim.log.levels.WARN)
    return
end

pi.setup({
    -- --approve 让 RPC 模式加载项目本地资源(否则跳过项目级配置)
    process = {
        cmd = { "pi", "--approve", "--mode", "rpc" },
    },
    -- 默认 <Leader>da/dr 与 DAP 的 <leader>ds/dr 冲突, 全部迁到 <leader>a 组
    diff = {
        keys = {
            accept = "<leader>aa",
            reject = "<leader>ar",
            edit_note = "<leader>an",
            delete_note = "<leader>ax",
            list_notes = "<leader>aN",
            expand_context = "<leader>ae",
            shrink_context = "<leader>as",
        },
    },
})

-- 键位在 VimEnter 后注册: 本配置先 require plugins 后 core, 顶层执行时 mapleader 尚未设置
local function setup_keymaps()
    local keymaps = {
        { { "n", "v" }, "<leader>ap", "<Cmd>Pi layout=side<CR>",        "Pi 侧栏" },
        { { "n", "v" }, "<leader>af", "<Cmd>Pi layout=float<CR>",       "Pi 浮窗" },
        { { "n", "v" }, "<leader>al", "<Cmd>PiToggleLayout<CR>",        "Pi 切换布局" },
        { { "n", "v" }, "<leader>ao", "<Cmd>PiToggleChat<CR>",          "Pi 开关聊天窗" },
        { { "n", "v" }, "<leader>ac", "<Cmd>PiContinue<CR>",            "Pi 继续最近会话" },
        { { "n", "v" }, "<leader>aR", "<Cmd>PiResume<CR>",              "Pi 恢复历史会话" },
        { { "n", "v" }, "<leader>am", "<Cmd>PiSendMention<CR>",         "Pi 引用文件/选区" },
        { { "n", "v" }, "<leader>aw", "<Cmd>PiAttention<CR>",           "Pi 处理下一个待审请求" },
        { { "n", "v" }, "<leader>an", "<Cmd>PiNewSession<CR>",          "Pi 新会话" },
        { { "n", "v" }, "<leader>aM", "<Cmd>PiCycleModel<CR>",          "Pi 切换模型" },
        { { "n", "v" }, "<leader>aT", "<Cmd>PiCycleThinking<CR>",       "Pi 切换思考档位" },
        { { "n", "v" }, "<leader>aq", "<Cmd>PiAbort<CR>",               "Pi 中断当前轮" },
    }

    for _, km in ipairs(keymaps) do
        vim.keymap.set(km[1], km[2], km[3], { desc = "Pi: " .. km[4], silent = true })
    end

    local which_key_ok, wk = pcall(require, "which-key")
    if which_key_ok then
        wk.add({
            { "<leader>a", group = "AI (pi)" },
            { "<leader>aa", group = "diff 审查" },
        })
    end
end

local group = vim.api.nvim_create_augroup("pi-nvim-keymaps", { clear = true })
local keymaps_done = false

local function setup_keymaps_once()
    if keymaps_done then return end
    keymaps_done = true
    setup_keymaps()
end

-- 触发点双保险: VimEnter(交互启动) + UIEnter(异步/远程 UI), 已注册则跳过
vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
    group = group,
    once = false,
    callback = setup_keymaps_once,
})
-- headless/脚本场景兜底: 首次空闲时注册
vim.schedule(setup_keymaps_once)