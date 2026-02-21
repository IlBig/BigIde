-- Keymaps BigIDE — pannello file-tree read-only, nvim non chiudibile

-- In modalità preview (popup): q ed Esc chiudono subito, nessuna restrizione
if vim.env.BIGIDE_PREVIEW == "1" then
  vim.keymap.set("n", "q",     "<cmd>qa!<CR>", { silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>qa!<CR>", { silent = true })
  return
end

local warn = function()
  vim.notify("BigIDE: usa Ctrl-A + Q per chiudere", vim.log.levels.WARN)
end

-- Blocca chiusura nvim da tastiera normale
vim.keymap.set("n", "q",  warn, { desc = "disabled: usa tmux prefix+Q" })
vim.keymap.set("n", "ZQ", "<nop>")
vim.keymap.set("n", "ZZ", "<nop>")

-- Comandi :Q :Qa :Wq che mostrano il messaggio invece di uscire
vim.api.nvim_create_user_command("Q",  warn, { bang = true })
vim.api.nvim_create_user_command("Qa", warn, { bang = true })
vim.api.nvim_create_user_command("Wq", warn, { bang = true })

vim.cmd([[
  cnoreabbrev q  Q
  cnoreabbrev qa Qa
  cnoreabbrev wq Wq
]])
