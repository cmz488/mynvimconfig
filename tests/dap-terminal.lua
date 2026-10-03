-- Run: nvim --headless -c 'luafile tests/dap-terminal.lua'
-- Requires the installed codelldb adapter and g++; compiles only a temporary fixture.
-- DAP_TEST_ADAPTER=gdb reproduces native GDB's lack of runInTerminal support.
local api = vim.api
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local dap
local ok, err = xpcall(function()
    vim.o.lines = 60
    vim.o.columns = 140
    local source = directory .. "/main.cpp"
    local executable = directory .. "/main"
    vim.fn.writefile({
        "#include <iostream>",
        "int main() {",
        '  std::cout << "VALUE? " << std::flush;',
        "  int value;",
        "  if (!(std::cin >> value)) return 1;",
        '  std::cout << "RESULT=" << value * 2 << std::endl;',
        "  int finish;",
        "  if (!(std::cin >> finish)) return 1;",
        "  return 0;",
        "}",
    }, source)
    local compiled = vim.system({ "g++", "-g", "-O0", source, "-o", executable }, { text = true }):wait(10000)
    assert(compiled.code == 0, compiled.stderr)
    vim.cmd.edit(source)
    dap = require("dap")
    local dapui = require("dapui")
    local adapter = vim.env.DAP_TEST_ADAPTER or "codelldb"
    local config
    for _, candidate in ipairs(dap.configurations.cpp) do
        if candidate.type == adapter and candidate.request == "launch" then
            config = vim.deepcopy(candidate)
            break
        end
    end
    assert(config, "No launch configuration for " .. adapter)
    config.program = executable
    config.cwd = directory

    local exit_code
    dap.listeners.after.event_exited.terminal_test = function(_, body)
        exit_code = body.exitCode
    end
    local function console_visible(buf)
        for _, win in ipairs(api.nvim_list_wins()) do
            if api.nvim_win_get_buf(win) == buf then
                return true
            end
        end
        return false
    end
    local function console_text(buf)
        return table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    end
    -- Re-launch as well: each ended session must release its terminal buffer.
    for _, value in ipairs({ 21, 22 }) do
        exit_code = nil
        dap.run(config)
        local console
        assert(
            vim.wait(8000, function()
                local session = dap.session()
                console = session and session.term_buf
                return console and console_text(console):find("VALUE?", 1, true) ~= nil
            end),
            adapter .. " did not create a program terminal in DAP Console"
        )
        assert(console == dapui.elements.console.buffer(), "Program terminal is not bound to Console")
        assert(vim.bo[console].buftype == "terminal", "Console is not an interactive terminal")
        assert(console_visible(console), "Program terminal is not visible")
        local job = assert(vim.b[console].terminal_job_id)
        vim.fn.chansend(job, tostring(value) .. "\n")
        assert(
            vim.wait(2000, function()
                return console_text(console):find("RESULT=" .. value * 2, 1, true) ~= nil
            end),
            "Program output is missing from Console"
        )
        assert(console_visible(console), "UI closed while the program was still running")
        vim.fn.chansend(job, "0\n")
        assert(
            vim.wait(8000, function()
                return exit_code ~= nil
            end),
            "Program did not receive terminal input"
        )
        assert(exit_code == 0, "Program failed to read stdin")
        assert(
            vim.wait(2000, function()
                return dap.session() == nil and not api.nvim_buf_is_valid(console)
            end),
            "Session did not release the program terminal"
        )
        assert(not console_visible(console), "Program terminal window remains after cleanup")
    end
end, debug.traceback)

if dap then
    dap.listeners.after.event_exited.terminal_test = nil
    dap.terminate({ all = true })
    vim.wait(1000, function()
        return dap.session() == nil
    end)
    dap.close()
end
vim.fn.delete(directory, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
else
    print("PASS: Console accepts stdin, shows stdout, then releases its terminal; re-launch works")
    vim.cmd("qa!")
end
