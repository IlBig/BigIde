-- Opzioni BigIDE (LazyVim imposta già molte defaults)
vim.opt.termguicolors = true
vim.opt.mouse        = "a"
vim.opt.number       = false
vim.opt.relativenumber = false

-- UI minimale per il pannello file-tree (nessuna statusline/tabline)
vim.opt.laststatus   = 0
vim.opt.showtabline  = 0
vim.opt.cmdheight    = 0

-- Auto-apri neo-tree all'avvio — NON in modalità preview (BIGIDE_PREVIEW=1)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.env.BIGIDE_PREVIEW == "1" then return end
    vim.schedule(function()
      local ok, cmd = pcall(require, "neo-tree.command")
      if ok then
        cmd.execute({ action = "show", position = "current", dir = vim.fn.getcwd() })
        -- Redraw dopo neo-tree: garantisce paint corretto in tmux al primo avvio
        vim.schedule(function() vim.cmd("redraw!") end)
      end
    end)
  end,
})
