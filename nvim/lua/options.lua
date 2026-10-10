vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.cmd("set number")

-- true:  VSCode/RubyMine-style layout, neo-tree reopened with sessions and barbar tabs on top
-- false: one file at a time, switch with Telescope (<D-p> files, <D-e> open buffers)
vim.g.ide_layout = false

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
})
