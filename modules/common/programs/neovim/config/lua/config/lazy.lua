-- prevent linter warnings for unknown global var
---@diagnostic disable: lowercase-global
vim = vim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo,
    lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.keymap.set("n", "<Space>", "", { noremap = true, silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.logging_level = "warn"
vim.opt.hlsearch = true           -- enable search highlighting
vim.opt.number = false            -- disable line numbers
vim.opt.clipboard = "unnamedplus" -- use system clipboard for all operations
vim.opt.termguicolors = true

vim.filetype.add({
  extension = {
    rex = "clojure",
  },
})

vim.o.guifont = "JetBrainsMono Nerd Font:h12"

require("config.globals")         -- load global utility defs
require("config.keys")            -- load keybindings with no dependencies

-- Setup lazy.nvim
require("lazy").setup({
  spec = { { import = "plugins" } },

  install = { colorscheme = { "habamax" } },

  checker = { enabled = true },
})
