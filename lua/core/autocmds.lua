local group = vim.api.nvim_create_augroup(
    "UserConfig",
    { clear = true }
)

-- 复制时高亮
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.highlight.on_yank({
            timeout = 150,
        })
    end,
})


local project_markers = {
    "CMakeLists.txt",
    "Cargo.toml",
    "go.mod",
    "package.json",
    "pyproject.toml",
    "compile_commands.json",
}

local changing_project = false

local function find_project_root(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return nil
    end

    -- 跳过终端、帮助页、NvimTree 等特殊 buffer
    if vim.bo[buf].buftype ~= "" then
        return nil
    end

    -- 跳过未命名 buffer
    if vim.api.nvim_buf_get_name(buf) == "" then
        return nil
    end

    -- 优先使用 Git 根目录
    return vim.fs.root(buf, { ".git" })
        or vim.fs.root(buf, project_markers)
end

vim.api.nvim_create_autocmd("BufEnter",
    {
        group = group,
        callback = function(args)
            if changing_project then
                return
            end

            local root = find_project_root(args.buf)
            if not root then
                return
            end

            root = vim.fs.normalize(root)
            local current_dir = vim.fs.normalize(vim.fn.getcwd(0, 0))

            if current_dir == root then
                vim.t.project_root = root
                return
            end

            changing_project = true

            local ok, err = pcall(vim.cmd,
                {
                    cmd = "tcd",
                    args = { root },
                })

            changing_project = false

            if not ok then
                vim.notify(
                    ("切换项目目录失败：%s"):format(err),
                    vim.log.levels.WARN
                )
                return
            end

            vim.t.project_root = root
        end,
    })



local saf_group = vim.api.nvim_create_augroup("AutoSaveAndFormat", { clear = true })

vim.api.nvim_create_autocmd("BufLeave", {
  group = saf_group,
  pattern = "*",
  callback = function()
    vim.cmd("silent! update")
  end,
  desc = "离开缓冲区时自动格式化并保存",
})
vim.api.nvim_create_autocmd("BufWritePre", {
    group = saf_group,
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
  desc = "保存前自动格式化",
})
