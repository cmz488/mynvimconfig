-- Run: nvim --headless -c 'luafile tests/dap-cleanup.lua'
-- Uses real GDB and codelldb processes; all programs and PID files are temporary.
local api = vim.api
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local dap
local ok, err = xpcall(function()
    vim.o.lines = 60
    vim.o.columns = 140
    local source = directory .. "/main.cpp"
    local executable = directory .. "/main"
    local lines = {
        "#include <iostream>",
        "#include <fstream>",
        "#include <unistd.h>",
        "int main(int, char** argv) {",
        "  std::ofstream(argv[1]) << getpid();",
        "  int value = 21;",
        "  std::cout << value << std::endl;",
        "  return 0;",
        "}",
    }
    vim.fn.writefile(lines, source)
    local compiled = vim.system({ "g++", "-g", "-O0", source, "-o", executable }, { text = true }):wait(10000)
    assert(compiled.code == 0, compiled.stderr)
    vim.cmd.edit(source)
    local source_buf = api.nvim_get_current_buf()
    local source_win = api.nvim_get_current_win()
    dap = require("dap")
    local dapui = require("dapui")
    local breakpoints = require("dap.breakpoints")
    require("nvim-dap-virtual-text/virtual_text")
    local namespace = api.nvim_create_namespace("nvim-dap-virtual-text")
    local counter = 0
    local notifications = {}
    vim.notify = function(message)
        notifications[#notifications + 1] = tostring(message)
    end

    local function alive(pid)
        return pid and vim.uv.kill(pid, 0) ~= nil
    end
    local function read_pid(path)
        return tonumber(vim.fn.readfile(path)[1])
    end
    local function wrap(command, args, pidfile)
        local result = {
            "-c",
            'printf "%s\\n" "$$" >> "$1"; shift; exec "$@"',
            "dap-cleanup-test",
            pidfile,
            command,
        }
        vim.list_extend(result, args or {})
        return { command = "sh", args = result }
    end
    local function debug_windows()
        for _, win in ipairs(api.nvim_list_wins()) do
            local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
            if ft:match("^dapui_") or ft == "dap-repl" then
                return true
            end
        end
        return false
    end
    local function start(kind, invalid)
        counter = counter + 1
        api.nvim_set_current_win(source_win)
        breakpoints.set({}, source_buf, 7)
        dapui.elements.watches.add("value")
        api.nvim_buf_set_extmark(source_buf, namespace, 0, 0, { virt_text = { { "test value", "Comment" } } })
        local adapter_pid = directory .. "/adapter-" .. counter
        local target_pid = directory .. "/target-" .. counter
        if kind == "server" then
            dap.adapters.cleanup_test = {
                type = "server",
                port = "${port}",
                executable = wrap(vim.fn.exepath("codelldb"), { "--port", "${port}" }, adapter_pid),
            }
        else
            dap.adapters.cleanup_test = vim.tbl_extend("force", wrap("gdb", { "--interpreter=dap" }, adapter_pid), {
                type = "executable",
            })
        end
        local captured
        dap.listeners.on_session.cleanup_test = function(_, new)
            if new and new.config.type == "cleanup_test" then
                captured = new
            end
        end
        dap.run({
            type = "cleanup_test",
            request = "launch",
            name = "cleanup-test",
            program = invalid and directory .. "/missing" or executable,
            args = { target_pid },
            cwd = directory,
            terminal = "console",
        }, { new = true })
        assert(
            vim.wait(8000, function()
                return captured and (invalid and captured.closed or captured.current_frame ~= nil)
            end),
            "Adapter did not reach the expected launch state: " .. table.concat(notifications, "\n")
        )
        return captured, read_pid(adapter_pid), not invalid and read_pid(target_pid), adapter_pid
    end
    local function assert_clean(session, adapter_pid, target_pid)
        assert(
            vim.wait(8000, function()
                return session.closed
                    and dap.session() == nil
                    and not next(dap.sessions())
                    and #dapui.elements.watches.get() == 0
                    and not next(breakpoints.get())
                    and not debug_windows()
                    and session.current_frame == nil
                    and not alive(adapter_pid)
                    and not alive(target_pid)
            end),
            "Session resources were not cleared: "
                .. vim.inspect({
                    session = dap.session() and dap.session().id,
                    watches = dapui.elements.watches.get(),
                    breakpoints = breakpoints.get(),
                    windows = debug_windows(),
                    adapter_alive = alive(adapter_pid),
                    target_alive = alive(target_pid),
                })
        )
        assert(api.nvim_buf_is_valid(source_buf), "Source buffer was deleted")
        assert(vim.deep_equal(api.nvim_buf_get_lines(source_buf, 0, -1, false), lines), "Source was modified")
        assert(#api.nvim_buf_get_extmarks(source_buf, namespace, 0, -1, {}) == 0, "Virtual values remain")
        for _, buf in ipairs(api.nvim_list_bufs()) do
            local ft = vim.bo[buf].filetype
            assert(ft ~= "dapui_console", "Program terminal buffer remains")
            if ft == "dap-repl" then
                assert(
                    table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), ""):match("^%s*$"),
                    "REPL output remains"
                )
            end
        end
    end

    local session, adapter_pid, target_pid = start("gdb")
    dapui.float_element("scopes", { enter = false })
    assert(
        vim.wait(1000, function()
            for _, win in ipairs(api.nvim_list_wins()) do
                if api.nvim_win_get_config(win).relative ~= "" then
                    return true
                end
            end
            return false
        end),
        "Test did not open the DAP floating window"
    )
    dap.continue()
    assert_clean(session, adapter_pid, target_pid)
    print("PASS: natural exit closes the adapter and clears debug resources")

    session, adapter_pid, target_pid = start("server")
    vim.fn.maparg("<F4>", "n", false, true).callback()
    assert_clean(session, adapter_pid, target_pid)
    print("PASS: stop closes an owned TCP adapter server and its program")

    session, adapter_pid, target_pid = start("gdb")
    vim.fn.maparg("<leader>dq", "n", false, true).callback()
    assert_clean(session, adapter_pid, target_pid)
    print("PASS: close performs graceful disconnect and cleanup")

    session, adapter_pid = start("server", true)
    assert_clean(session, adapter_pid)
    print("PASS: failed launch releases adapter and UI resources")

    session, adapter_pid, target_pid = start("gdb")
    assert(vim.uv.kill(adapter_pid, "sigkill"))
    assert_clean(session, adapter_pid, target_pid)
    print("PASS: unexpected adapter exit cleans up without protocol termination events")

    local pidfile
    session, adapter_pid, target_pid, pidfile = start("gdb")
    dap.restart()
    assert(
        vim.wait(8000, function()
            local current = dap.session()
            return current and current ~= session and current.current_frame ~= nil
        end),
        "Restart lost the breakpoint or did not establish a new session"
    )
    assert(#dapui.elements.watches.get() == 1, "Restart cleared the watch expressions")
    assert(not alive(adapter_pid) and not alive(target_pid), "Restart left old processes running")
    session = dap.session()
    adapter_pid = tonumber(vim.fn.readfile(pidfile)[2])
    target_pid = read_pid(directory .. "/target-" .. counter)
    dap.continue()
    assert_clean(session, adapter_pid, target_pid)
    print("PASS: restart preserves definitions without leaking old processes")

    for _, message in ipairs(notifications) do
        assert(not message:find("DAP 清理", 1, true), message)
    end
end, debug.traceback)

if dap then
    dap.listeners.on_session.cleanup_test = nil
    dap.terminate({ all = true, hierarchy = true })
    vim.wait(6000, function()
        return dap.session() == nil
    end)
    dap.close()
end
vim.fn.delete(directory, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
