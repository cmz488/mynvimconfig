-- Run: nvim --headless -c 'luafile tests/dap-cleanup-state.lua'
-- Replay session lifecycle boundaries to test attach/multi-session safety without ptrace.
local api = vim.api
local source = vim.fn.tempname() .. ".cpp"
vim.fn.writefile({ "int main() { return 0; }" }, source)
local unrelated_job
local unrelated_buf
local dap
local ok, err = xpcall(function()
    vim.cmd.edit(source)
    local source_buf = api.nvim_get_current_buf()
    dap = require("dap")
    local dapui = require("dapui")
    local cleanup = require("plugins.dap-cleanup")
    cleanup.setup()
    cleanup.setup()
    local listener = "config.resource_cleanup"
    local next_id = 1000
    local function session(request)
        next_id = next_id + 1
        local s = {
            id = next_id,
            config = { name = "cleanup-state", request = request },
            children = {},
            on_close = {},
            disconnects = {},
            threads = { [1] = {} },
            current_frame = { name = "test" },
        }
        function s:close()
            self.closed = true
            for _, callback in pairs(self.on_close) do
                callback(self)
            end
            self.on_close = {}
        end
        function s:disconnect(opts, callback)
            self.disconnects[#self.disconnects + 1] = opts
            self.finish = function()
                self:close()
                callback(nil)
            end
        end
        s.on_close.registry = function()
            dap.sessions()[s.id] = nil
            dap.set_session(nil)
        end
        dap.set_session(s)
        return s
    end
    local function seed()
        dapui.open()
        require("dap.breakpoints").set({}, source_buf, 1)
        dapui.elements.watches.add("value")
    end
    local function settled()
        -- Drain both cleanup scheduling turns and asynchronous UI rendering.
        vim.wait(50, function()
            return false
        end)
    end
    local function empty()
        assert(#dapui.elements.watches.get() == 0, "Watches were not cleared")
        assert(not next(require("dap.breakpoints").get()), "Breakpoints were not cleared")
    end

    unrelated_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_call(unrelated_buf, function()
        unrelated_job = vim.fn.jobstart({ "sleep", "30" }, { term = true })
    end)
    assert(unrelated_job > 0)

    local first = session("launch")
    seed()
    local second = session("attach")
    first:close()
    settled()
    assert(#dapui.elements.watches.get() == 1, "Closing one session cleared another session's watches")
    assert(next(require("dap.breakpoints").get()), "Closing one session cleared another session's breakpoints")
    cleanup.stop()
    cleanup.stop()
    assert(#second.disconnects == 1, "Repeated stop sent duplicate disconnect requests")
    assert(second.disconnects[1].terminateDebuggee == false, "Attach target would be killed")
    second.finish()
    settled()
    empty()

    local failed = session("launch")
    seed()
    dap.listeners.after.initialize[listener](failed, { message = "test initialize failure" })
    settled()
    assert(failed.closed, "Initialize failure left the session open")
    empty()

    local old = session("launch")
    seed()
    local console = dapui.elements.console.buffer()
    local job
    api.nvim_buf_call(console, function()
        job = vim.fn.jobstart({ "sleep", "30" }, { term = true })
    end)
    assert(job > 0)
    old.term_buf = console
    old:close()
    local replacement = session("launch")
    replacement.term_buf = console
    settled()
    assert(api.nvim_buf_is_valid(console), "Late cleanup deleted the new session's terminal")
    assert(vim.fn.jobwait({ job }, 0)[1] == -1, "Late cleanup stopped the new session's terminal")
    assert(#dapui.elements.watches.get() == 1, "Late cleanup reset the new session's watches")
    replacement:close()
    settled()
    assert(not api.nvim_buf_is_valid(console), "Closed session terminal was not deleted")
    assert(vim.fn.jobwait({ job }, 0)[1] ~= -1, "Closed session terminal job remains")
    empty()
    assert(api.nvim_buf_is_valid(source_buf), "Cleanup deleted source")
    assert(api.nvim_buf_is_valid(unrelated_buf), "Cleanup deleted an unrelated terminal")
    assert(vim.fn.jobwait({ unrelated_job }, 0)[1] == -1, "Cleanup killed an unrelated terminal job")
    print("PASS: attach detaches safely, stop is idempotent, other sessions and unrelated terminals survive")
end, debug.traceback)
if unrelated_job then
    vim.fn.jobstop(unrelated_job)
end
if unrelated_buf and api.nvim_buf_is_valid(unrelated_buf) then
    api.nvim_buf_delete(unrelated_buf, { force = true })
end
vim.fn.delete(source)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
