-- Keymaps BigIDE — pannello file-tree read-only, nvim non chiudibile

local warn = function()
  vim.notify("BigIDE: usa Ctrl-A + Q per chiudere", vim.log.levels.WARN)
end

-- Blocca chiusura nvim da tastiera normale
vim.keymap.set("n", "q",  warn, { desc = "disabled: usa tmux prefix+Q" })
vim.keymap.set("n", "ZQ", "<nop>")
vim.keymap.set("n", "ZZ", "<nop>")

-- Comandi :Q :Qa :Wq che mostrano il messaggio invece di uscire
-- (bang=true gestisce anche :Q! :Qa! :Wq!)
vim.api.nvim_create_user_command("Q",  warn, { bang = true })
vim.api.nvim_create_user_command("Qa", warn, { bang = true })
vim.api.nvim_create_user_command("Wq", warn, { bang = true })

-- Abbreviazioni command-line: :q→:Q  :qa→:Qa  :wq→:Wq
-- (:q! diventa :Q! grazie a bang=true su Q)
vim.cmd([[
  cnoreabbrev q  Q
  cnoreabbrev qa Qa
  cnoreabbrev wq Wq
]])
