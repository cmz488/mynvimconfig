-- dap 组按需加载：只有打开可调试文件类型时才拉取并进入 runtimepath。
-- name 与 lua/plugins/init.lua 的 gh() 风格保持一致（目录名 = 插件短名）。
-- nvim-dap 只在这里声明，不要在 init.lua 里重复 add，否则会克隆两份。
-- nvim-dap-ui 的配置在 lua/plugins/dapui.lua：dapui 依赖 nvim-dap，
-- 所以必须等这个 packadd 执行完再调用它。
local function setup_debugging()
    vim.pack.add({
        { src = "https://github.com/mfussenegger/nvim-dap",           name = "dap" },
        { src = "https://github.com/theHamsta/nvim-dap-virtual-text", name = "dap-virtual-text" },
        { src = "https://github.com/nvim-neotest/nvim-nio",           name = "nio" },
        { src = "https://github.com/rcarriga/nvim-dap-ui",            name = "dap-ui" },
        { src = "https://github.com/mfussenegger/nvim-dap-python",    name = "dap-python" },
    })

    local dap = require("dap")
    local cleanup = require("plugins.dap-cleanup")

    -- 停止/切换栈帧时优先使用源码窗口。默认 uselast 可能选中另一个 dapui
    -- 面板；其 force_buffers 会恢复面板内容，导致源码行号被用于短面板而越界。
    dap.defaults.fallback.switchbuf = 'usevisible,usetab,uselast'

    -- NOTE: configure adapters
    -- C/C++ 统一使用 gdb 自带的 DAP 服务器（gdb >= 14 的 --interpreter=dap），
    -- 不再依赖 cpptools 的 cppdbg / OpenDebugAD7（它不随系统包分发，且 MI 专有字段
    -- 无法在 gdb 适配器里表达）。gdb 的 launch 支持 program/args/cwd/env/
    -- stopAtBeginningOfMainSubprogram/stopOnEntry，attach 支持 pid/target。
    dap.adapters.codelldb = {
        type = "executable",
        command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"
    }
    dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }
    dap.adapters.cudagdb = {
        type = "executable",
        command = "cuda-gdb",
        -- cuda-gdb 13.4 同样支持 DAP（基于 gdb 16.3），但必须显式指定解释器，
        -- 否则它会以普通 CLI 模式启动，永远不会说 DAP 协议。
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }
    dap.adapters["rust-gdb"] = {
        type = "executable",
        command = "rust-gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
    }
    dap.adapters.arm_gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "--quiet", "--nx", "--interpreter=dap", "--eval-command", "set print pretty on" },
    }

    -- probe-rs：ESP32 系列（esp-hal/embassy）内置 USB-JTAG 调试。
    -- adapter 名字故意用 "probe-rs-debug"：与 VSCode 扩展一致，这样项目里的
    -- .vscode/launch.json 可以被两个编辑器原样共用（nvim-dap 会自动读取它）。
    -- 具体 launch 参数（chip / coreConfigs / flashingConfig）写在项目的 launch.json 里。
    dap.adapters["probe-rs-debug"] = {
        type = "server",
        port = "${port}",
        executable = {
            command = "probe-rs",
            -- --single-session：会话结束即退出，避免残留进程占用端口
            args = { "dap-server", "--port", "${port}", "--single-session" },
        },
    }

    -- NOTE: filetype configurations
    dap.configurations.cuda = {
        {
            name = "Launch (cuda-gdb)",
            type = "cudagdb",
            request = "launch",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
        },
        {
            name = "Launch (gdb)",
            type = "gdb",
            request = "launch",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopAtBeginningOfMainSubprogram = false,
        },
    }
    dap.configurations.cpp = dap.configurations.cpp or {}

    vim.list_extend(dap.configurations.cpp, {
        {
            name = "Launch (codelldb, terminal)",
            type = "codelldb",
            request = "launch",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            -- 原生 GDB DAP 不发 runInTerminal 请求；需要 std::cin 等交互输入时
            -- 选择此项。codelldb 的 terminal 字段会把程序终端交给 dapui Console。
            terminal = "integrated",
            stopOnEntry = false,
        },
        {
            name = "Launch (gdb)",
            type = "gdb",
            request = "launch",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "Select and attach to process",
            type = "gdb",
            request = "attach",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            -- gdb 的 attach 用 pid（gdb 文档：pid 与 target 二选一）
            pid = function()
                local name = vim.fn.input("Executable name (filter): ")
                return require("dap.utils").pick_process({ filter = name })
            end,
            cwd = "${workspaceFolder}",
        },

        {
            name = "STM32：连接 OpenOCD",
            type = "arm_gdb",
            request = "attach",

            target = "127.0.0.1:3333",

            -- ELF 用于读取符号、源码位置和变量类型
            program = function()
                local path = vim.fn.input(
                    "ELF 文件路径：",
                    vim.fn.getcwd() .. "/build/Debug/",
                    "file"
                )

                if path == "" then
                    return dap.ABORT
                end

                path = vim.fn.fnamemodify(path, ":p")

                if vim.fn.filereadable(path) ~= 1 then
                    vim.notify("ELF 文件不存在：" .. path, vim.log.levels.ERROR)
                    return dap.ABORT
                end

                return path
            end,
        },
    })
    dap.configurations.rust = {
        {
            name = "Launch",
            type = "rust-gdb",
            request = "launch",
            program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            args = {}, -- provide arguments if needed
            cwd = "${workspaceFolder}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "Select and attach to process",
            type = "rust-gdb",
            request = "attach",
            program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            pid = function()
                local name = vim.fn.input('Executable name (filter): ')
                return require("dap.utils").pick_process({ filter = name })
            end,
            cwd = "${workspaceFolder}"
        },
        {
            name = "Attach to gdbserver :1234",
            type = "rust-gdb",
            request = "attach",
            target = "localhost:1234",
            program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}'
        }
    }
    -- C 与 C++ 共用同一批 launch/attach 配置（适配器与选项完全相同）。
    -- 必须在 list_extend 之后赋值：c 与 cpp 共享同一个表，后续追加两者都可见。
    dap.configurations.c = dap.configurations.cpp

    -- Gaudi / Moore 相关条目原先用 cppdbg 的 miDebuggerPath 指向各项目自带的 gdb。
    -- 改用 gdb 适配器后：gdb 可执行文件由适配器固定（PATH 里的 gdb），
    -- 所以 miDebuggerPath / MIMode / setupCommands / externalConsole / preLaunchTask
    -- 这些 MIEngine/VSCode 专有字段全部去掉；pretty-printing 由适配器参数里的
    -- --eval-command "set print pretty on" 覆盖。
    dap.configurations.python = dap.configurations.python or {}
    vim.list_extend(dap.configurations.python, {
        {
            type = "python",
            request = "launch",
            name = "file:args (cwd)",
            program = "${file}",
            args = function()
                local args_string = vim.fn.input("Arguments: ")
                local utils = require("dap.utils")
                if utils.splitstr and vim.fn.has("nvim-0.10") == 1 then
                    return utils.splitstr(args_string)
                end
                return vim.split(args_string, " +")
            end,
            console = "integratedTerminal",
            cwd = vim.fn.getcwd(),
        },
        {
            name = "GDB: gaudirun.py (Moore)",
            type = "gdb",
            request = "launch",
            program = function()
                local result = vim.system({ "utils/run-env", "Gaudi", "which", "python3" }, { text = true }):wait()
                return vim.trim(result.stdout)
            end,
            args = {
                "${workspaceFolder}/Gaudi/Gaudi/scripts/gaudirun.py",
                "${file}",
            },
            cwd = "${fileDirname}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "GDB: gaudirun.py",
            type = "gdb",
            request = "launch",
            program = function()
                local result = vim.system({ "utils/run-env", "Gaudi", "which", "python3" }, { text = true }):wait()
                return vim.trim(result.stdout)
            end,
            args = {
                "${workspaceFolder}/Gaudi/Gaudi/scripts/gaudirun.py",
                "${file}",
            },
            cwd = "${fileDirname}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "GDB: qmtexec",
            type = "gdb",
            request = "launch",
            program = function()
                local project = vim.fn.input("Project name: ", "Moore")
                return "${workspaceFolder}/" .. project .. "/run"
            end,
            args = {
                "qmtexec",
                "${file}",
            },
            cwd = "${fileDirname}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "GDB: attach",
            type = "gdb",
            request = "attach",
            program = "/cvmfs/lhcb.cern.ch/lib/lcg/releases/Python/3.9.12-9a1bc/x86_64-el9-gcc13-opt/bin/python",
            pid = function()
                return require("dap.utils").pick_process()
            end,
        },
    })
    dap.configurations.qmt = dap.configurations.python


    require("nvim-dap-virtual-text").setup({})
    local ok, noice = pcall(require, "noice")
    if ok then
        noice.setup()
    end

    -- Custom breakpoint icons
    vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = 'DapBreakpoint' })
    vim.fn.sign_define(
        'DapBreakpointCondition',
        {
            text = '',
            texthl = 'DapBreakpointCondition',
            linehl = 'DapBreakpointCondition',
            numhl =
            'DapBreakpointCondition'
        }
    )
    vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

    -- keymaps（dapui 的 <leader>du / <F1> 在 lua/plugins/dapui.lua）
    vim.keymap.set('n', '<leader>ds', dap.continue, { desc = ' Start/Continue' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = ' Start/Continue' })
    vim.keymap.set('n', '<leader>di', dap.step_into, { desc = ' Step into' })
    vim.keymap.set('n', '<F7>', dap.step_into, { desc = ' Step into' })
    vim.keymap.set('n', '<leader>do', dap.step_over, { desc = ' Step over' })
    vim.keymap.set('n', '<F8>', dap.step_over, { desc = ' Step over' })
    vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = ' Step out' })
    vim.keymap.set('n', '<F9>', dap.step_out, { desc = ' Step out' })
    vim.keymap.set('n', '<leader>dq', cleanup.stop, { desc = 'DAP: Stop and clean sessions' })
    vim.keymap.set('n', '<leader>dr', dap.restart_frame, { desc = 'DAP: Restart frame' })
    vim.keymap.set('n', '<F6>', dap.restart, { desc = 'DAP: Start over' })
    vim.keymap.set('n', '<leader>dQ', cleanup.stop, { desc = 'DAP: Stop and clean sessions' })
    vim.keymap.set('n', '<F4>', cleanup.stop, { desc = 'DAP: Stop and clean sessions' })

    vim.keymap.set('n', '<leader>dc', dap.run_to_cursor, { desc = 'DAP: Run to Cursor' })
    vim.keymap.set('n', '<leader>dR', dap.repl.toggle, { desc = 'DAP: Toggle REPL' })
    vim.keymap.set('n', '<leader>dh', require('dap.ui.widgets').hover, { desc = 'DAP: Hover' })

    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: Breakpoint' })
    vim.keymap.set('n', '<leader>dB', function()
        local input = vim.fn.input 'Condition for breakpoint:'
        dap.set_breakpoint(input)
    end, { desc = 'DAP: Conditional Breakpoint' })
    vim.keymap.set('n', '<leader>dD', dap.clear_breakpoints, { desc = 'DAP: Clear Breakpoints' })

    vim.keymap.set('n', '<leader>dj', dap.down, { desc = 'DAP: Frame down' })
    vim.keymap.set('n', '<leader>dk', dap.up, { desc = 'DAP: Frame up' })
    vim.keymap.set('n', '<leader>dl', dap.run_last, { desc = 'DAP: Run last' })
    vim.keymap.set('n', '<leader>dL', function()
        dap.set_breakpoint(nil, nil, vim.fn.input('Log point: '))
    end, { desc = 'DAP: Log point' })
    vim.keymap.set('n', '<leader>dX', dap.list_breakpoints, { desc = 'DAP: List breakpoints' })
    vim.keymap.set('n', '<leader>dS', dap.session, { desc = 'DAP: Session info' })
    vim.keymap.set('n', '<leader>dT', function()
        dap.terminate({}, { terminateDebuggee = true })
    end, { desc = 'DAP: Terminate' })
    vim.keymap.set('n', '<leader>dp', function()
        require('dap.ui.widgets').preview() -- 光标处表达式预览
    end, { desc = 'DAP: Preview expression' })
    -- nvim-dap 不执行 launch.json 的 preLaunchTask（那是 VSCode 的任务系统）。
    -- 用这个等效：先 cargo build，成功后再启动/继续调试。
    vim.api.nvim_create_user_command('DapCargoBuild', function()
        vim.notify('cargo build ...', vim.log.levels.INFO)
        local out = vim.system({ 'cargo', 'build' }, { cwd = vim.fn.getcwd(), text = true }):wait()
        if out.code ~= 0 then
            vim.notify('cargo build 失败：\n' .. (out.stderr or ''), vim.log.levels.ERROR)
            return
        end
        dap.continue()
    end, { desc = 'cargo build 后启动调试（等价于 preLaunchTask）' })
    vim.keymap.set('n', '<leader>dG', '<cmd>DapCargoBuild<CR>', { desc = 'DAP: Build + Debug' })

    require("plugins.dapui").setup()
    cleanup.setup()
end

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("SetupDebugging", { clear = true }),
    pattern = { "python", "cpp", "cuda", "c", "rust" },
    once = true,
    callback = setup_debugging,
})
