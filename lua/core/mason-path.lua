local M = {}

-- mason 安装的二进制（clangd、lua-language-server、marksman、vtsls、neocmakelsp、
-- tree-sitter…）都在 stdpath('data')/mason/bin 下。
--
-- 本配置并没有启用 mason.nvim，这个目录不会自动进入 PATH，也没有别处设置它，
-- 所以由需要它的模块显式调用 ensure()。
--
-- 刻意「追加」而不是「前置」：系统包里的 clangd (22.1.8) 和 lua-language-server
-- (3.19.1) 都比 mason 里的 (22.1.6 / 3.18.2-dev) 新，前置会让版本回退。
-- 只有 mason 独有的二进制（marksman、vtsls、neocmakelsp、tree-sitter…）
-- 才会实际命中这里。
function M.ensure()
    local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
    if vim.fn.isdirectory(mason_bin) == 0 then
        return
    end

    local path = vim.env.PATH or ""
    if path == "" then
        vim.env.PATH = mason_bin
        return
    end

    -- 幂等：多个 FileType 回调都会调用；用字面量匹配，避免路径里的 . 被当正则
    if path:find(mason_bin, 1, true) then
        return
    end

    local path_sep = vim.fn.has("win32") == 1 and ";" or ":"
    vim.env.PATH = path .. path_sep .. mason_bin
end

return M
