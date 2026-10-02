vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--query-driver=/usr/bin/arm-none-eabi-*",
  },

  filetypes = { "c", "cpp" },

  root_markers = {
    "compile_commands.json",
    "CMakeLists.txt",
    ".git",
  },
})

vim.lsp.enable("clangd")
