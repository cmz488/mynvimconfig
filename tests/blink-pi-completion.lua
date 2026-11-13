-- Run: nvim --headless -u init.lua -c 'luafile tests/blink-pi-completion.lua'
-- 用 --embed 子进程挂一个假 UI, 才能让 blink 真的触发补全
local CONFIG = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local COLS, ROWS = 120, 40

local failures = {}

local function expect(condition, message)
    if not condition then
        failures[#failures + 1] = message
    end
end

local chan = vim.fn.jobstart({ "nvim", "--embed", "-u", CONFIG .. "/init.lua" }, { rpc = true })
assert(chan > 0, "子进程启动失败")
vim.rpcrequest(chan, "nvim_ui_attach", COLS, ROWS, { rgb = true })

local function call(expr)
    return vim.rpcrequest(chan, "nvim_exec_lua", expr, {})
end

local function settle(ms)
    vim.wait(ms, function()
        return false
    end)
end

local function reset(filetype)
    vim.rpcrequest(chan, "nvim_input", "<Esc>")
    settle(150)
    call(
        string.format(
            [[
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)
        vim.bo[buf].filetype = %q
        vim.bo[buf].buftype = "nofile"
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    ]],
            filetype
        )
    )
    settle(150)
end

--- 输入一段文本, 返回补全项标签与来源
local function complete(keys)
    reset("pi-chat-prompt")
    vim.rpcrequest(chan, "nvim_input", "i" .. keys)
    settle(900)
    local items = call([[
        local ok, cmp = pcall(require, "blink.cmp")
        if not ok then return {} end
        local res = {}
        for _, item in ipairs(cmp.get_items()) do
            res[#res + 1] = { label = item.label, source = item.source_name }
        end
        return res
    ]])
    return items, call("return vim.api.nvim_get_current_line()")
end

local function accept()
    pcall(vim.rpcrequest, chan, "nvim_exec_lua", [[return require("blink.cmp").select_and_accept()]], {})
    settle(500)
    return call("return vim.api.nvim_get_current_line()")
end

--- 每一项都来自 pi 源, 且以给定前缀开头
local function assert_pi_only(items, prefix, context)
    expect(#items > 0, context .. ": 没有补全项")
    for _, item in ipairs(items) do
        expect(item.source == "Pi", context .. ": 来源不是 Pi, 而是 " .. tostring(item.source))
        expect(item.label:sub(1, #prefix) == prefix, context .. ": 标签 " .. item.label .. " 不以 " .. prefix .. " 开头")
    end
end

local items = complete("/")
assert_pi_only(items, "/", "斜杠命令")

items = complete("/mo")
assert_pi_only(items, "/", "斜杠命令前缀")
expect(items[1] and items[1].label == "/model", "斜杠命令前缀: 首项应为 /model, 实际 " .. tostring(items[1] and items[1].label))
local line = accept()
expect(line == "/model", "/model 接受后应为 /model, 实际 " .. vim.inspect(line))

items = complete("@lua/")
assert_pi_only(items, "@", "at 引用")
expect(items[1] and items[1].label == "@lua/core/", "at 引用: 首项应为 @lua/core/, 实际 " .. tostring(items[1] and items[1].label))
line = accept()
expect(line == "@lua/core/", "目录接受后应为 @lua/core/, 实际 " .. vim.inspect(line))

-- 非 pi 缓冲区不应该出现 pi 源
reset("lua")
vim.rpcrequest(chan, "nvim_input", "i@l")
settle(900)
items = call([[
    local ok, cmp = pcall(require, "blink.cmp")
    if not ok then return {} end
    local res = {}
    for _, item in ipairs(cmp.get_items()) do
        res[#res + 1] = { label = item.label, source = item.source_name }
    end
    return res
]])
for _, item in ipairs(items) do
    expect(item.source ~= "Pi", "普通缓冲区不该出现 pi 补全项: " .. item.label)
end

vim.fn.jobstop(chan)

if #failures > 0 then
    io.stderr:write("失败 " .. #failures .. " 项:\n")
    for _, message in ipairs(failures) do
        io.stderr:write("  - " .. message .. "\n")
    end
    vim.cmd("cquit 1")
end

print("PASS: pi 提示词窗口只出 / 命令和 @ 引用, 接受后文本正确, 普通缓冲区不受影响")
vim.cmd("qa!")
