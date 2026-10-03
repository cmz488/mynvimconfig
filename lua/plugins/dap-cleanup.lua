-- 会话级资源清理；适配器进程、管道和连接仍由 nvim-dap 的 Session:close
-- 负责释放。只处理本 Neovim 拥有的终端与临时数据，不按进程名全局杀进程。
local M = {}
---@type table<dap.Session, boolean>
local sessions = setmetatable({}, { __mode = "k" })
---@type table<dap.Session, boolean>
local disconnecting = setmetatable({}, { __mode = "k" })
local generation = 0
local listener = "config.resource_cleanup"

---@param label string
---@param fn fun()
local function attempt(label, fn)
    local ok, err = pcall(fn)
    if not ok then
        vim.notify("DAP 清理 " .. label .. " 失败: " .. tostring(err), vim.log.levels.WARN)
    end
end

---@param buf integer
local function terminal_in_use(buf)
    for session in pairs(sessions) do
        if not session.closed and session.term_buf == buf then
            return true
        end
    end
    return false
end

---@param buf integer?
local function delete_buffer(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    local job = vim.b[buf].terminal_job_id
    if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
        vim.fn.jobstop(job)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
end

local function clear_if_idle()
    local dap = require("dap")
    if next(dap.sessions()) then
        return
    end
    for session in pairs(sessions) do
        if not session.closed then
            return
        end
    end
    local dapui = require("dapui")
    attempt("关闭面板", dapui.close)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
        if vim.api.nvim_win_get_config(win).relative ~= "" and (ft:match("^dapui_") or ft == "dap-repl") then
            attempt("调试浮窗", function()
                vim.api.nvim_win_close(win, true)
            end)
        end
    end
    attempt("断点", dap.clear_breakpoints)
    attempt("监视表达式", function()
        local watches = dapui.elements.watches
        for index = #watches.get(), 1, -1 do
            watches.remove(index)
        end
    end)
    attempt("REPL", dap.repl.clear)
    local virtual_text = package.loaded["nvim-dap-virtual-text/virtual_text"]
    if virtual_text then
        attempt("虚拟值", function()
            virtual_text.clear_virtual_text()
            virtual_text.clear_last_frames()
        end)
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local ft = vim.bo[buf].filetype
        local name = vim.api.nvim_buf_get_name(buf)
        -- REPL 是工具栏绑定的固定 UI 缓冲区：清空而不删除，避免上游的
        -- BufWipeout 自动重建它并反复注册控件。真正的程序终端则完全释放。
        if ft == "dapui_console" or ft == "dapui_hover" or name:match("^dap%-src://") then
            attempt("临时缓冲区 " .. buf, function()
                delete_buffer(buf)
            end)
        end
    end
    -- 固定 UI 元素继续复用，重绘为空状态；不反复 setup（会重复注册监听器）。
    attempt("面板数据", function()
        dapui.update_render({ indent = require("dapui.config").render.indent })
    end)
end

---@param session dap.Session
local function track(session)
    if session.on_close[listener] then
        return
    end
    sessions[session] = true
    generation = generation + 1
    session.on_close[listener] = function(closed)
        disconnecting[closed] = nil
        local epoch = generation
        -- on_close 可能在 libuv 回调里运行；同时留出内置 restart 启动新会话的机会。
        vim.schedule(function()
            vim.schedule(function()
                local buf = closed.term_buf
                if buf and not terminal_in_use(buf) then
                    attempt("程序终端", function()
                        delete_buffer(buf)
                    end)
                end
                closed.term_buf = nil
                closed.current_frame = nil
                closed.stopped_thread_id = nil
                closed.threads = {}
                sessions[closed] = nil
                if generation == epoch then
                    clear_if_idle()
                end
            end)
        end)
    end
end

-- 比直接 dap.close() 更安全：先发送 disconnect，让 launch 的程序退出，
-- attach 的外部目标则只脱离。Session:disconnect 自带超时与本地关闭逻辑。
function M.stop()
    local dap = require("dap")
    local pending = {}
    local function collect(session)
        if pending[session] then
            return
        end
        pending[session] = true
        for _, child in pairs(session.children or {}) do
            collect(child)
        end
    end
    for _, session in pairs(dap.sessions()) do
        collect(session)
    end
    for session in pairs(sessions) do
        collect(session)
    end
    for session in pairs(pending) do
        if not session.closed and not disconnecting[session] then
            disconnecting[session] = true
            session:disconnect({ terminateDebuggee = session.config.request == "launch" }, function(err)
                disconnecting[session] = nil
                if err then
                    vim.notify("DAP disconnect 失败，已关闭本地会话: " .. tostring(err), vim.log.levels.WARN)
                end
            end)
        end
    end
    if not next(pending) then
        clear_if_idle()
    end
end

function M.setup()
    local dap = require("dap")
    dap.listeners.on_session[listener] = function(_, new)
        if new then
            track(new)
        end
    end
    -- 未取得焦点的子会话，以及 initialize 失败的会话，也安装关闭钩子。
    dap.listeners.before.initialize[listener] = track
    dap.listeners.after.initialize[listener] = function(session, err)
        if err and not session.closed then
            session:close()
        end
    end
    for _, session in pairs(dap.sessions()) do
        track(session)
    end
end

return M
