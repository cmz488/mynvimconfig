-- 缓冲区操作：删除 buffer 时保住当前编辑窗口。
--
-- Neovim 删除「当前窗口正在显示的 buffer」时不会复用该窗口：它关闭窗口，再把焦点
-- 交给另一个窗口。本配置里那个窗口通常是 nvim-tree 的侧栏，而且 nvim-tree 的缓冲区
-- 很早创建（bufnr 很小），于是焦点就落到文件树里。解决办法是在删除前先把窗口切到
-- 另一个 buffer，这样 bdelete 只删 buffer，不牵动窗口。

local M = {}

-- nvim-tree 的内部缓冲区名为 NvimTree_<tab>，与真实文件同名时会冲突（E95）
local NVIM_TREE_BUF_NAME = "^NvimTree_%d+$"

--- 是否为普通文件缓冲区（排除 nvim-tree、终端、quickfix、无名缓冲区等）
---@param buf integer
---@return boolean
function M.is_file_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return false
    end

    -- 跳过 nofile/terminal/prompt/quickfix 等特殊缓冲区
    if vim.bo[buf].buftype ~= "" then
        return false
    end

    local name = vim.api.nvim_buf_get_name(buf)

    -- 跳过无名缓冲区
    if name == "" then
        return false
    end

    if vim.fn.fnamemodify(name, ":t"):match(NVIM_TREE_BUF_NAME) then
        return false
    end

    return true
end

--- 选出接管窗口的缓冲区：优先 alternate buffer，其次最近使用的普通文件缓冲区
---@param exclude integer|nil 要排除的缓冲区（即将被删除的那个）
---@return integer|nil
function M.pick_successor(exclude)
    local alt = vim.fn.bufnr("#")
    if alt > 0 and alt ~= exclude and M.is_file_buffer(alt) and vim.bo[alt].buflisted then
        return alt
    end

    local best, best_used = nil, -1
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        local buf = info.bufnr
        if buf ~= exclude and M.is_file_buffer(buf) and info.lastused > best_used then
            best, best_used = buf, info.lastused
        end
    end

    return best
end

---@param buf integer
local function raw_delete(buf)
    local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
    if not ok then
        vim.notify(("删除缓冲区失败：%s"):format(err), vim.log.levels.WARN)
    end
end

--- 删除缓冲区，但不关闭它所在的窗口
---@param buf integer|nil 目标缓冲区，默认为当前缓冲区
function M.delete(buf)
    buf = buf or vim.api.nvim_get_current_buf()

    -- 非当前缓冲区、非普通文件缓冲区：删除不会牵动窗口，保持原生行为
    if buf ~= vim.api.nvim_get_current_buf() or not M.is_file_buffer(buf) then
        raw_delete(buf)
        return
    end

    local win = vim.api.nvim_get_current_win()

    local placeholder = nil
    local successor = M.pick_successor(buf)
    if not successor then
        -- 没有其它文件缓冲区时，先换成一个空缓冲区（等价于原生 `:enew`）
        placeholder = vim.api.nvim_create_buf(true, false)
        successor = placeholder
    end

    -- 切换窗口会触发 BufLeave，配置里的自动保存正好在删除前把修改写盘
    vim.api.nvim_win_set_buf(win, successor)

    local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
    if ok then
        return
    end

    -- 删除失败（例如自动保存没成功，缓冲区仍有未保存修改）：恢复窗口原状
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_win_set_buf, win, buf)
    end

    if placeholder and placeholder ~= vim.api.nvim_get_current_buf() then
        pcall(vim.api.nvim_buf_delete, placeholder, { force = true })
    end

    vim.notify(("删除缓冲区失败：%s"):format(err), vim.log.levels.WARN)
end

--- 编辑窗口被 Neovim 关闭后，补回一个编辑窗口显示其它文件缓冲区
---@param deleted integer 刚被删除的缓冲区
function M.reopen_window(deleted)
    local successor = M.pick_successor(deleted)
    if not successor then
        successor = vim.api.nvim_create_buf(true, false)
    end

    local ok, err = pcall(function()
        local sidebar = vim.api.nvim_get_current_win()
        local resize_sidebar = vim.bo[vim.api.nvim_win_get_buf(sidebar)].filetype == "NvimTree"

        -- 焦点这时通常落在 nvim-tree 的侧栏窗口里：从它分出一个窗口再挪到最右侧，
        -- 侧栏保持全高，编辑窗口也不会被挤进侧栏那 32 列的宽度里
        vim.cmd("vsplit")
        vim.cmd("wincmd L")
        vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), successor)

        -- 分屏会改变侧栏宽度，让 nvim-tree 按自身配置重新调整
        if resize_sidebar then
            pcall(require("nvim-tree.view").resize)
        end
    end)

    if not ok then
        vim.notify(("恢复编辑窗口失败：%s"):format(err), vim.log.levels.WARN)
    end
end

--- 记录最近编辑的文件缓冲区，并在它被删除时兜底补回编辑窗口。
-- 覆盖 `:bd`、picker 里删缓冲区等不由本配置接管的删除路径。
function M.setup()
    local group = vim.api.nvim_create_augroup("UserBufferWindow", { clear = true })

    local last_file_buf = nil
    local last_file_win = nil

    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(args)
            if not M.is_file_buffer(args.buf) then
                return
            end
            last_file_buf = args.buf
            last_file_win = vim.api.nvim_get_current_win()
        end,
        desc = "记录最近编辑的文件缓冲区及其窗口",
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            if args.buf ~= last_file_buf then
                return
            end

            local win = last_file_win
            last_file_buf, last_file_win = nil, nil

            -- 删除当前缓冲区时，BufDelete 触发时窗口已经被关掉了，只能等删除流程
            -- 结束后再补救
            vim.schedule(function()
                if win and vim.api.nvim_win_is_valid(win) then
                    return
                end
                if M.is_file_buffer(vim.api.nvim_get_current_buf()) then
                    return
                end
                M.reopen_window(args.buf)
            end)
        end,
        desc = "删除当前文件缓冲区后补回编辑窗口",
    })
end

return M