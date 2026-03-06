-- Opzioni BigIDE (LazyVim imposta già molte defaults)
vim.opt.termguicolors = true
vim.opt.mouse        = "a"
vim.opt.number       = false
vim.opt.relativenumber = false

-- UI minimale per il pannello file-tree (nessuna statusline/tabline/winbar)
vim.opt.laststatus   = 0
vim.opt.showtabline  = 0
vim.opt.cmdheight    = 0
vim.opt.winbar       = ""   -- impedisce a neo-tree di mostrare il path


-- Rimuovi readonly/nomodifiable da buffer file normali (neo-tree li imposta sui propri buffer,
-- ma possono propagarsi quando si apre un file nella stessa finestra)
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bt = vim.bo.buftype
    local ft = vim.bo.filetype
    -- Solo buffer normali (non neo-tree, non help, non terminali, ecc.)
    if bt == "" and ft ~= "neo-tree" then
      vim.bo.readonly = false
      vim.bo.modifiable = true
    end
  end,
})

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
