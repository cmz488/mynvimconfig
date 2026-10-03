-- nvim-dap-ui 的配置：会话自动打开、面板布局、程序终端与 UI 键位。
-- 不在这里 packadd：dapui 依赖 nvim-dap，插件组统一由 lua/plugins/dap.lua 声明，
-- 并在 packadd 之后调用本模块的 setup()。
local M = {}

function M.setup()
    local dap = require("dap")
    local dapui = require("dapui")

    -- 开始调试时显示 UI；最终关闭与数据清理交给 dap-cleanup 的 on_close 钩子。
    dap.listeners.before.attach.dapui_config = function()
        dapui.open({ reset = true })
    end
    dap.listeners.before.launch.dapui_config = function()
        dapui.open({ reset = true })
    end
    -- 不在 exited 时抢先清理：此时连接可能仍有效，或会话正在 restart。
    dap.listeners.before.event_terminated.dapui_config = nil
    dap.listeners.before.event_exited.dapui_config = nil

    -- 上游运行时会补默认值，但 dapui.Config 的类型声明要求这些字段完整。
    ---@type dapui.Config
    local config = {
        wrap = false,
        icons = { expanded = "", collapsed = "", current_frame = "" },
        mappings = {
            expand = { "<CR>", "<2-LeftMouse>" },
            open = "o",
            remove = "d",
            edit = "e",
            repl = "r",
            toggle = "t",
            watch = "w",
        },
        element_mappings = {},
        expand_lines = false,
        force_buffers = true,
        layouts = {
            {
                position = "left",
                size = 0.4,
                elements = {
                    { id = "stacks", size = 0.2 },
                    { id = "scopes", size = 0.5 },
                    { id = "breakpoints", size = 0.15 },
                    { id = "watches", size = 0.15 },
                },
            },
            {
                position = "bottom",
                size = 0.2,
                elements = {
                    { id = "repl", size = 0.3 },
                    { id = "console", size = 0.7 },
                },
            },
        },
        floating = {
            border = "single",
            mappings = { close = { "q", "<Esc>" } },
        },
        controls = {
            enabled = true,
            element = "repl",
            icons = {
                pause = "",
                play = "",
                step_into = "",
                step_over = "",
                step_out = "",
                step_back = "",
                run_last = "",
                terminate = "",
            },
        },
        render = { indent = 1, max_value_lines = 100 },
    }
    dapui.setup(config)
    -- dapui.setup 已将 terminal_win_cmd 绑定到 Console；不要再用 split/tabnew
    -- 覆盖它。适配器发出 runInTerminal 请求后，这个面板才变成可输入的终端。
    dap.defaults.fallback.focus_terminal = false

    -- UI 键位（其余 dap 键位在 lua/plugins/dap.lua）
    vim.keymap.set("n", "<leader>du", function()
        dapui.toggle({ reset = true })
    end, { desc = "DAP: Toggle UI" })
    vim.keymap.set("n", "<F1>", function()
        dapui.toggle({ reset = true })
    end, { desc = "DAP: Toggle UI" })
    vim.keymap.set("n", "<leader>dt", function()
        dapui.open()
        local buf = dapui.elements.console.buffer()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_buf(win) == buf then
                vim.api.nvim_set_current_win(win)
                break
            end
        end
        local job = vim.b[buf].terminal_job_id
        if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
            vim.cmd.startinsert()
        elseif vim.bo[buf].buftype ~= "terminal" then
            vim.notify(
                "程序终端尚未启动；C/C++ 输入输出调试请选择 Launch (codelldb, terminal)",
                vim.log.levels.INFO
            )
        end
    end, { desc = "DAP: Focus program terminal" })
end

return M
