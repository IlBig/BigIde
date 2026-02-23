-- init minimale per preview immagini: SOLO image.nvim, niente LazyVim/neo-tree
local lazy_dir = vim.fn.expand("$HOME") .. "/.local/share/bigide/lazy"

-- Aggiunge image.nvim e dipendenze al runtimepath
for _, pkg in ipairs({ "image.nvim", "plenary.nvim" }) do
  local p = lazy_dir .. "/" .. pkg
  if vim.fn.isdirectory(p) == 1 then
    vim.opt.rtp:prepend(p)
  end
end

-- UI minimale
vim.opt.number     = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 0
vim.opt.cmdheight  = 0
vim.opt.ruler      = false
vim.opt.showmode   = false
vim.opt.showtabline = 0

-- Setup image.nvim con Kitty protocol
require("image").setup({
  backend  = "kitty",
  processor = "magick_cli",
  hijack_file_patterns = {
    "*.png","*.jpg","*.jpeg","*.gif","*.webp",
    "*.heic","*.heif","*.bmp","*.tiff","*.tif","*.svg","*.avif",
  },
  max_width_window_percentage  = 95,
  max_height_window_percentage = 95,
  tmux_show_only_in_active_window = true,
})

-- Chiudi con q / Esc / Enter
for _, k in ipairs({ "q", "<Esc>", "<CR>" }) do
  vim.keymap.set("n", k, "<cmd>qa!<CR>", { silent = true })
end
