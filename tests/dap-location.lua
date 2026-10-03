-- Run with the normal config: nvim --headless -c 'luafile tests/dap-location.lua'
-- Replay a DAP frame through nvim-dap's real positioning code and dapui's
-- force_buffers autocmds. Scope requests are unrelated to window selection.
local api = vim.api
local source_path = vim.fn.tempname() .. ".cpp"

local ok, err = xpcall(function()
    vim.o.lines = 60
    vim.o.columns = 140
    vim.fn.writefile({
        "#include <cstdio>",
        "",
        "int main() {",
        "  int i = 0;",
        "",
        "",
        "  i++;",
        "",
        "",
        "",
        "",
        '  std::printf("%d", i);',
        "  return 0;",
        "}",
    }, source_path)
    vim.cmd.edit(source_path)
    local source_buf = api.nvim_get_current_buf()
    local source_win = api.nvim_get_current_win()
    local dapui = require("dapui")
    dapui.open()

    local panels = {}
    for _, win in ipairs(api.nvim_list_wins()) do
        local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
        if ft:match("^dapui_") then
            panels[ft] = { win = win, buf = api.nvim_win_get_buf(win) }
        end
    end
    assert(panels.dapui_breakpoints and panels.dapui_watches)
    local notifications = {}
    vim.notify = function(message)
        notifications[#notifications + 1] = message
    end
    local session = setmetatable({
        config = { type = "gdb" },
        filetype = "cpp",
        sign_group = "DapLocationTest",
        _request_scopes = function() end,
    }, { __index = require("dap.session") })

    local function replay(line, previous, focused)
        api.nvim_set_current_win(panels[previous].win)
        api.nvim_set_current_win(panels[focused].win)
        session:_frame_set({
            id = 1,
            name = "main",
            line = line,
            column = 0,
            source = { path = source_path, sourceReference = 0 },
        })
        assert(#notifications == 0, table.concat(notifications, "\n"))
        assert(api.nvim_get_current_buf() == source_buf, "Stopped frame selected a UI buffer")
        assert(api.nvim_win_get_cursor(0)[1] == line, "Stopped frame selected the wrong source line")
        for _, panel in pairs(panels) do
            assert(api.nvim_win_get_buf(panel.win) == panel.buf, "A dapui panel was replaced")
        end
    end

    replay(13, "dapui_breakpoints", "dapui_watches")
    replay(12, "dapui_stacks", "dapui_scopes")
    -- Blank lines are still part of the debugger's source numbering.
    replay(8, "dapui_scopes", "dapui_breakpoints")
    -- No visible source window: open a new one rather than reusing a UI panel.
    api.nvim_win_set_buf(source_win, api.nvim_create_buf(true, false))
    replay(13, "dapui_breakpoints", "dapui_watches")
    dapui.close()
end, debug.traceback)

vim.fn.delete(source_path)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
else
    print("PASS: DAP selects the source window, preserves panels and exact line numbers, and opens hidden sources")
    vim.cmd("qa!")
end
