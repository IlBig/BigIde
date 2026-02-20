-- BigIDE Neovim Config (LazyVim Overlay)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Base options
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"

-- Setup plugins
require("lazy").setup({
  "folke/tokyonight.nvim",
  "nvim-treesitter/nvim-treesitter",
  "nvim-lua/plenary.nvim",
  "nvim-telescope/telescope.nvim",
  "neovim/nvim-lspconfig",
})

-- Visual
vim.cmd[[colorscheme tokyonight]]
