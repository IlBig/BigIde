-- BigIDE preview navigation (scansione ricorsiva albero)
-- ↑/↓ cambia file (attraversa cartelle) | Enter: leggi | Esc: chiudi
-- Caricato da preview-file.sh quando BIGIDE_PREVIEW=1

local current_file = vim.fn.expand("%:p")

-- Cartelle da ignorare
local SKIP_DIRS = {
  node_modules=1, __pycache__=1, [".git"]=1, [".svn"]=1, [".hg"]=1,
  build=1, dist=1, [".next"]=1, [".nuxt"]=1, target=1,
  [".cache"]=1, [".tmp"]=1, vendor=1, Pods=1, [".build"]=1,
}

-- Leggi nav-root (preservato tra transizioni) o usa la dir del file
local nav_root
local rf = io.open("/tmp/bigide-nav-root", "r")
if rf then
  nav_root = rf:read("*a"):gsub("%s+$", "")
  rf:close()
  if nav_root == "" then nav_root = nil end
end
if not nav_root then
  nav_root = vim.fn.fnamemodify(current_file, ":h")
end

-- Scansione ricorsiva depth-first (stessa logica del viewer Swift)
local all_files = {}
local MAX_FILES = 5000

local function walk_dir(dir, max_depth)
  if max_depth <= 0 or #all_files >= MAX_FILES then return end
  local ok, entries = pcall(vim.fn.readdir, dir)
  if not ok then return end

  -- Separa cartelle e file, ordina ciascun gruppo (come neo-tree: cartelle prima)
  local dirs = {}
  local files = {}
  for _, name in ipairs(entries) do
    if not name:match("^%.") then
      local path = dir .. "/" .. name
      if vim.fn.isdirectory(path) == 1 then
        table.insert(dirs, name)
      else
        table.insert(files, name)
      end
    end
  end
  table.sort(dirs)
  table.sort(files)

  -- Prima ricorri nelle cartelle
  for _, name in ipairs(dirs) do
    if not SKIP_DIRS[name] then
      walk_dir(dir .. "/" .. name, max_depth - 1)
    end
  end

  -- Poi aggiungi i file
  for _, name in ipairs(files) do
    table.insert(all_files, dir .. "/" .. name)
  end
end

walk_dir(nav_root, 8)

-- Trova posizione corrente
local current_idx = 1
for i, path in ipairs(all_files) do
  if path == current_file then
    current_idx = i
    break
  end
end

-- Path relativo dalla root
local function rel_path(path)
  local prefix = nav_root .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return vim.fn.fnamemodify(path, ":t")
end

-- Naviga al file precedente/successivo: scrivi path e chiudi
local function navigate(delta)
  if #all_files <= 1 then return end
  local new_idx = ((current_idx - 1 + delta) % #all_files) + 1
  local next_path = all_files[new_idx]
  local f = io.open("/tmp/bigide-preview-next", "w")
  if f then
    f:write(next_path)
    f:close()
  end
  vim.cmd("quit!")
end

local function setup_browse_mode()
  -- ↑/↓ naviga file (attraversa cartelle)
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
     {rel_path(current_file) .. "  ", "String"},
     {"(" .. current_idx .. "/" .. #all_files .. ")", "NonText"}},
    false, {}
  )
end

-- q chiude sempre
vim.keymap.set("n", "q", "<cmd>quit!<cr>", { buffer = 0, nowait = true })

-- Avvia in browse mode
vim.schedule(function()
  setup_browse_mode()
end)
