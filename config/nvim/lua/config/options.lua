-- Opzioni BigIDE (LazyVim imposta già molte defaults)
vim.opt.termguicolors = true
vim.opt.mouse        = "a"
vim.opt.number       = false
vim.opt.relativenumber = false

-- UI minimale per il pannello file-tree (nessuna statusline/tabline)
vim.opt.laststatus   = 0
vim.opt.showtabline  = 0
vim.opt.cmdheight    = 0

-- Auto-apri neo-tree all'avvio (pcall: non crasha se plugin mancante)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      local ok, cmd = pcall(require, "neo-tree.command")
      if ok then
        -- dir = cwd (cartella progetto impostata da filetree.sh)
        cmd.execute({ action = "show", position = "current", dir = vim.fn.getcwd() })
      end
    end)
  end,
})
