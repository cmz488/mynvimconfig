-- Fcitx5: 0 = 未启用，1 = 英文（inactive），2 = 输入法已激活。
local ime_group = vim.api.nvim_create_augroup("ImeAutoGroup", { clear = true })
local remote = vim.fn.exepath("fcitx5-remote")
if remote == "" then
    return
end

local ACTIVE = "2"
local COMMAND_TIMEOUT_MS = 200
local restore_active = false
local warned = false

local function warn(message)
    if warned then
        return
    end
    warned = true
    vim.schedule(function()
        vim.notify("输入法自动切换失败：" .. message, vim.log.levels.WARN)
    end)
end

local function run_remote(option)
    local command = { remote, "--check" }
    if option then
        command[#command + 1] = option
    end

    -- 查询和切换必须按顺序完成；异步查询可能在关闭输入法后才读到状态，
    -- 或在快速 Esc/i 时让旧回调覆盖新状态。超时避免 D-Bus 故障卡住编辑器。
    local ok, result = pcall(function()
        return vim.system(command, { text = true }):wait(COMMAND_TIMEOUT_MS)
    end)
    if not ok then
        warn(tostring(result))
        return nil
    end
    if result.code ~= 0 then
        warn(vim.trim(result.stderr or "") ~= "" and vim.trim(result.stderr)
            or ("fcitx5-remote 退出码 %s"):format(result.code))
        return nil
    end
    return vim.trim(result.stdout or "")
end

vim.api.nvim_create_autocmd("InsertLeave", {
    group = ime_group,
    desc = "记住 Fcitx5 状态并切换到英文",
    callback = function()
        restore_active = false
        local state = run_remote()
        if state == ACTIVE then
            restore_active = run_remote("-c") ~= nil
        elseif state ~= nil and state ~= "0" and state ~= "1" then
            warn("无法识别 Fcitx5 状态：" .. state)
        end
    end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
    group = ime_group,
    desc = "恢复上次插入模式的 Fcitx5 状态",
    callback = function()
        if not restore_active then
            return
        end
        restore_active = false
        run_remote("-o")
    end,
})
