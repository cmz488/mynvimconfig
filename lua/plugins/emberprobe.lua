-- Copy this complete block into init.lua BEFORE its first vim.pack.add().
-- Prepare the default source first:
--   bash scripts/prepare-pack-source.sh ~/Projects/emberprobe.nvim
assert(vim.pack and vim.pack.add, 'EmberProbe vim.pack installation requires Neovim 0.12+')

local plugin_name = 'emberprobe'
local source = vim.env.EMBERPROBE_PACK_SRC
    or ('file://' .. vim.fn.expand('~/Projects/emberprobe.nvim'))
local library_name = jit.os == 'Windows' and 'emberprobe.dll'
    or jit.os == 'OSX' and 'libemberprobe.dylib' or 'libemberprobe.so'

local function build(path)
    assert(vim.fn.filereadable(path .. '/Cargo.toml') == 1,
        'EmberProbe: installation source must contain the Rust/Lua rewrite (Cargo.toml missing)')
    assert(vim.fn.executable('cargo') == 1, 'EmberProbe: install Rust/Cargo before building')
    vim.notify('EmberProbe: building Rust native library…')
    -- Fix the output directory even when the user sets CARGO_TARGET_DIR.
    local result = vim.system({
        'cargo', 'build', '--release', '--locked', '--target-dir', path .. '/target',
    }, { cwd = path, text = true }):wait()
    if result.code ~= 0 then
        error('EmberProbe: native build failed in ' .. path .. '\n'
            .. (result.stderr or result.stdout or 'Cargo did not return diagnostic output'))
    end
    assert(vim.fn.filereadable(path .. '/target/release/' .. library_name) == 1,
        'EmberProbe: native library missing after build; check CARGO_BUILD_TARGET and cross-compilation settings')
end

vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('EmberProbePackBuild', { clear = true }),
    callback = function(ev)
        local data = ev.data
        if data.spec.name ~= plugin_name
            or (data.kind ~= 'install' and data.kind ~= 'update') then
            return
        end
        -- Installation finishes building before Lua can create a native session.
        build(data.path)
        if data.kind == 'update' then
            vim.notify('EmberProbe: rebuild complete; restart Neovim to load the updated native library')
        end
    end,
})

vim.pack.add({ { src = source, name = plugin_name } }, { load = true })

local installed = vim.pack.get({ plugin_name }, { info = false })[1]
assert(installed and installed.active, 'EmberProbe: package was not installed')
-- Recover an existing installation created before the build hook was added.
if vim.fn.filereadable(installed.path .. '/target/release/' .. library_name) == 0 then
    build(installed.path)
end

vim.api.nvim_create_user_command('EmberProbeBuild', function()
    build(installed.path)
    vim.notify('EmberProbe: rebuild complete; restart Neovim to load the new native library')
end, { desc = 'Build the installed EmberProbe Rust library', force = true })

require('emberprobe').setup({
    -- sample_hz = 2000,
    -- max_samples = 10,
    -- refresh_hz = 2000,
    -- Configure your hardware here, for example:
    -- interface = 'interface/cmsis-dap.cfg',
    -- target = 'target/stm32h7x.cfg',
    -- elf = '/absolute/path/build/firmware.elf',
})
