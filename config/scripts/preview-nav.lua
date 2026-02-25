-- BigIDE preview navigation — ↑/↓ delega a neo-tree
-- ↑/↓ cambia file | Enter: leggi | Esc/q: chiudi
-- Caricato da preview-file.sh quando BIGIDE_PREVIEW=1

local current_file = vim.fn.expand("%:p")
local filename = vim.fn.fnamemodify(current_file, ":t")
local current_dir = vim.fn.fnamemodify(current_file, ":h")

-- Trova file adiacente nella stessa directory (fallback se navigate_neotree fallisce)
local function find_adjacent_file(delta)
  local ok, entries = pcall(vim.fn.readdir, current_dir)
  if not ok then return nil end

  -- Solo file (no directory), ordinati
  local files = {}
  for _, name in ipairs(entries) do
    if not name:match("^%.") then
      local path = current_dir .. "/" .. name
      if vim.fn.isdirectory(path) == 0 then
        table.insert(files, path)
      end
    end
  end
  table.sort(files)

  for i, path in ipairs(files) do
    if path == current_file then
      local ni = ((i - 1 + delta) % #files) + 1
      return files[ni]
    end
  end
  return nil
end

-- Naviga: scrivi direzione + path fallback e chiudi
local function navigate(delta)
  local direction = delta > 0 and "down" or "up"
  local fallback = find_adjacent_file(delta)
  local content = direction
  if fallback then
    content = direction .. "\n" .. fallback
  end
  local f = io.open("/tmp/bigide-preview-next", "w")
  if f then f:write(content); f:close() end
  vim.cmd("quit!")
end

local function setup_browse_mode()
  -- ↑/↓ naviga file (delega a neo-tree)
  vim.keymap.set("n", "<Up>", function() navigate(-1) end, { buffer = 0, nowait = true })
  vim.keymap.set("n", "<Down>", function() navigate(1) end, { buffer = 0, nowait = true })

  -- Enter entra in modalita' lettura
  vim.keymap.set("n", "<CR>", function()
    pcall(vim.keymap.del, "n", "<Up>", { buffer = 0 })
    pcall(vim.keymap.del, "n", "<Down>", { buffer = 0 })
    pcall(vim.keymap.del, "n", "<CR>", { buffer = 0 })
    vim.keymap.set("n", "<Esc>", function()
      setup_browse_mode()
    end, { buffer = 0, nowait = true })
    vim.api.nvim_echo({{"  j/k scorri  |  Esc: torna ai file  |  q: chiudi", "Comment"}}, false, {})
  end, { buffer = 0, nowait = true })

  -- Esc chiude la preview
  vim.keymap.set("n", "<Esc>", "<cmd>quit!<cr>", { buffer = 0, nowait = true })

  vim.api.nvim_echo(
    {{"  ↑↓ naviga file  |  Enter: leggi  |  Esc: chiudi  ", "Comment"},
     {filename, "String"}},
    false, {}
  )
end

-- q chiude sempre
vim.keymap.set("n", "q", "<cmd>quit!<cr>", { buffer = 0, nowait = true })

-- Avvia in browse mode
vim.schedule(function()
  setup_browse_mode()
end)
