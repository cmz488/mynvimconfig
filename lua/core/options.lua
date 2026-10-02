local opt = vim.opt

-- 行号
opt.number = true
opt.relativenumber = true

-- 缩进
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- 界面
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8

-- 搜索
opt.ignorecase = true
opt.smartcase = true

-- 系统剪贴板
vim.g.clipboard = {                                                                                                                                      
     name = "wl-clipboard",                                                                                                                                 
                                                                                                                                                            
     copy = {                                                                                                                                               
       ["+"] = { "wl-copy" },                                                                                                                               
       ["*"] = { "wl-copy", "--primary" },                                                                                                                  
     },                                                                                                                                                     
                                                                                                                                                            
     paste = {                                                                                                                                              
       ["+"] = { "wl-paste", "--no-newline" },                                                                                                              
       ["*"] = { "wl-paste", "--primary", "--no-newline" },                                                                                                 
     },                                                                                                                                                     
                                                                                                                                                            
     cache_enabled = 0,                                                                                                                                     
   }                                                                                                                                                        
                                                                                                                                                            
   vim.opt.clipboard = "unnamedplus"

-- 分屏
opt.splitright = true
opt.splitbelow = true

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
