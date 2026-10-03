-- nvim-dap-ui 的配置：会话自动开关、面板布局、UI 键位。
-- 不在这里 packadd：dapui 依赖 nvim-dap，插件组统一由 lua/plugins/dap.lua 声明，
-- 并在 packadd 之后调用本模块的 setup()。
local M = {}

function M.setup()
    local dap = require("dap")
    local dapui = require("dapui")

    -- UI responsiveness：进入/退出会话时自动开关 UI
    dap.listeners.before.attach.dapui_config = function()
        dapui.open({ reset = true })
    end
    dap.listeners.before.launch.dapui_config = function()
        dapui.open({ reset = true })
    end
    dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
    end

    -- customize UI layout
    dapui.setup {
        expand_lines = false,
        layouts = {
            {
                position = 'left',
                size = 0.4,
                elements = {
                    { id = 'stacks',      size = 0.2 },
                    { id = 'scopes',      size = 0.5 },
                    { id = 'breakpoints', size = 0.15 },
                    { id = 'watches',     size = 0.15 },
                },
            },
            {
                position = 'bottom',
                size = 0.2,
                elements = {
                    { id = 'repl',    size = 0.3 },
                    { id = 'console', size = 0.7 },
                },
            },
        },
    }

    -- UI 键位（其余 dap 键位在 lua/plugins/dap.lua）
    vim.keymap.set('n', '<leader>du', function()
        dapui.toggle({ reset = true })
    end, { desc = 'DAP: Toggle UI' })
    vim.keymap.set('n', '<F1>', function()
        dapui.toggle({ reset = true })
    end, { desc = 'DAP: Toggle UI' })
end

return M
