vim.pack.add({
    'https://github.com/nvim-mini/mini.nvim',
})


--- @mini.git config

local function is_git_repo()
    -- 传入 0 代表当前 buffer，'.git' 为要查找的标记
    local root = vim.fs.root(0, '.git')
    return root ~= nil
end

-- 只有当进入有git仓库的目录才使能mini.git
vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("GitProjectOnly", { clear = true }),
    callback = function()
        -- 排除特殊 buffer（如终端、dashboard）
        if vim.bo.buftype ~= "" then return end

        -- 检查是否有 .git 目录
        if is_git_repo() then
            require("mini.git").setup()
            vim.keymap.set("n", "<leader>ga", function()
                vim.cmd("Git add %")
                vim.notify("已经追踪当前文件", vim.log.levels.INFO)
            end, { desc = "git add 当前缓冲区" })

            vim.keymap.set("n", "<leader>gA", "<cmd>Git add .<cr>", { desc = "追踪当前项目所有文件" })

            vim.keymap.set("n", "<leader>gc", function()
                vim.ui.input({ prompt = "Commit msg: " }, function(msg)
                    if not msg or msg == "" then
                        vim.notify("Commit 已取消或消息为空", vim.log.levels.WARN)
                        return
                    end


                    vim.cmd("Git commit -m " .. msg)
                end)
            end, { desc = "git commit" })
        end
    end,
})

--- @mini.surround config
require('mini.surround').setup()
