-- init minimale per preview immagini: SOLO image.nvim, niente LazyVim/neo-tree
local lazy_dir = vim.fn.expand("$HOME") .. "/.local/share/bigide/lazy"

for _, pkg in ipairs({ "image.nvim", "plenary.nvim" }) do
  local p = lazy_dir .. "/" .. pkg
  if vim.fn.isdirectory(p) == 1 then
    vim.opt.rtp:prepend(p)
  end
end

-- UI minimale, NESSUN swap file
vim.opt.swapfile   = false
vim.opt.number     = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 0
vim.opt.cmdheight  = 0
vim.opt.ruler      = false
vim.opt.showmode   = false
vim.opt.showtabline = 0

-- Setup image.nvim con fallback: Kitty → Sixel
-- Nota: image.nvim potrebbe fallire in ambienti non-PTY (es. tmux display-popup)
-- ma continuerà a funzionare in sesisoni tmux regolari
local ok, image = pcall(require, "image")
if ok then
  -- Tenta Kitty protocol (primario), fallback a sixel se non disponibile
  local backends_to_try = { "kitty", "sixel" }
  local backend_used = nil

  -- Supprimere i warning di image.nvim aggiungendo una source temporanea
  -- che cattura e scarta i messaggi di errore di terminal size
  vim.opt.shortmess:append("T")  -- Suppress "truncated" message

  for _, backend in ipairs(backends_to_try) do
    local cfg_attempt = {
      backend = backend,
      processor = "magick_cli",
      hijack_file_patterns = {
        "*.png","*.jpg","*.jpeg","*.gif","*.webp",
        "*.heic","*.heif","*.bmp","*.tiff","*.tif","*.svg","*.avif",
      },
      -- Usa percentuali della finestra (documentazione ufficiale image.nvim)
      max_width_window_percentage = 90,
      max_height_window_percentage = 90,
      scale_factor = 1.0,
      tmux_show_only_in_active_window = true,
      integrations = {
        markdown = { enabled = false },
        neorg = { enabled = false },
      },
    }

    local success = pcall(function()
      image.setup(cfg_attempt)
      backend_used = backend
    end)

    if success and backend_used then
      break
    end
  end

  if backend_used then
    -- Esplicita render dell'immagine all'avvio
    vim.schedule(function()
      vim.cmd("silent! edit! %")
    end)
  else
    -- Fallback: visualizza le informazioni del file se image.nvim non riesce
    vim.notify("Anteprima immagine non disponibile in questo ambiente", vim.log.levels.INFO)
  end
else
  vim.notify("image.nvim non disponibile", vim.log.levels.WARN)
end

-- Chiudi con q / Esc / Enter
for _, k in ipairs({ "q", "<Esc>", "<CR>" }) do
  vim.keymap.set("n", k, "<cmd>qa!<CR>", { silent = true })
end
