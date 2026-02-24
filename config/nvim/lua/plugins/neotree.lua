-- neo-tree: file explorer VSCode-like per BigIDE
-- Cartelle: espandi/collassa | File: preview overlay (q / Esc per chiudere)
-- ↑/↓ naviga file nell'albero neo-tree | ←/→ naviga stesso tipo nel viewer

local TEXT_EXT = {
  -- Markup / testo
  md=1, txt=1, rst=1, adoc=1, org=1, tex=1, log=1,
  -- Dati strutturati
  json=1, jsonc=1, xml=1, yaml=1, yml=1, toml=1, ini=1, cfg=1, conf=1, csv=1, tsv=1, env=1,
  plist=1,
  -- Shell
  sh=1, bash=1, zsh=1, fish=1, ps1=1,
  -- Scripting / backend
  lua=1, py=1, rb=1, php=1, pl=1, r=1, jl=1, ex=1, exs=1, hs=1, ml=1, el=1,
  applescript=1, scpt=1,
  -- Web
  js=1, mjs=1, cjs=1, ts=1, jsx=1, tsx=1,
  html=1, htm=1, css=1, scss=1, sass=1, less=1, svelte=1, vue=1,
  -- Sistemi / compiled
  c=1, h=1, cpp=1, hpp=1, cs=1, java=1, go=1, rs=1,
  swift=1, kt=1, m=1, mm=1, dart=1, zig=1,
  -- DevOps / infra
  sql=1, graphql=1, proto=1, tf=1, hcl=1,
  -- Diff / patch
  diff=1, patch=1,
  -- Vim
  vim=1, vimrc=1, lua=1,
}

local IMAGE_EXT = {
  jpg=1, jpeg=1, png=1, gif=1, webp=1, bmp=1,
  tiff=1, tif=1, ico=1, heic=1, heif=1, svg=1,
  avif=1, jxl=1, qoi=1,
}

local DOC_EXT = {
  pdf=1, docx=1, xlsx=1, pptx=1, doc=1, xls=1, ppt=1,
  pages=1, numbers=1, key=1, odt=1, ods=1, odp=1,
}

local VIDEO_EXT = {
  mp4=1, mov=1, avi=1, mkv=1, webm=1, m4v=1,
  wmv=1, flv=1, mpg=1, mpeg=1, ["3gp"]=1, ts=1,
}

local KNOWN_NAMES = {
  Makefile=1, makefile=1, GNUmakefile=1,
  Dockerfile=1, ["docker-compose.yml"]=1,
  [".env"]=1, [".gitignore"]=1, [".gitattributes"]=1,
  [".editorconfig"]=1, Brewfile=1, Rakefile=1, Gemfile=1,
}

local function is_image(name)
  local ext = name:match("%.([^%.]+)$")
  return ext ~= nil and IMAGE_EXT[ext:lower()] == 1
end

local function is_document(name)
  local ext = name:match("%.([^%.]+)$")
  return ext ~= nil and DOC_EXT[ext:lower()] == 1
end

local function is_video(name)
  local ext = name:match("%.([^%.]+)$")
  return ext ~= nil and VIDEO_EXT[ext:lower()] == 1
end

local function is_text(name, filepath)
  if KNOWN_NAMES[name] then return true end
  local ext = name:match("%.([^%.]+)$")
  if ext then
    ext = ext:lower()
    if TEXT_EXT[ext] == 1 then return true end
    if IMAGE_EXT[ext] == 1 then return false end
    if DOC_EXT[ext] == 1 then return false end
    if VIDEO_EXT[ext] == 1 then return false end
  end
  if filepath then
    local ok, out = pcall(vim.fn.system, { "file", "--mime-type", "--brief", filepath })
    if ok and vim.v.shell_error == 0 then
      out = out:gsub("%s+$", "")
      if out:match("^text/") then return true end
    end
  end
  return false
end

local PREVIEW_SCRIPT        = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-file.sh"
local PREVIEW_IMAGE_SCRIPT  = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-image.sh"
local PREVIEW_DOC_SCRIPT    = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-doc.sh"
local PREVIEW_VIDEO_SCRIPT  = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-video.sh"
local PREVIEW_BINARY_SCRIPT = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-binary.sh"

local function kill_imgview()
  vim.fn.jobstart({ "pkill", "-x", "bigide-imgview" }, { detach = true })
end

local function kill_docview()
  vim.fn.jobstart({ "pkill", "-x", "bigide-docview" }, { detach = true })
end

local function kill_vidview()
  vim.fn.jobstart({ "pkill", "-x", "bigide-vidview" }, { detach = true })
end

local function kill_all_viewers()
  kill_imgview()
  kill_docview()
  kill_vidview()
end

--- State neo-tree salvato da handle_node — usato per navigazione cross-type
local cached_state = nil

--- Polling cursore: sincronizza neo-tree con ←/→ del viewer Swift
local viewer_poll_id = nil
local viewer_poll_last = ""

local function reveal_in_neotree(filepath)
  pcall(function()
    require("neo-tree.command").execute({
      source = "filesystem",
      reveal_file = filepath,
    })
  end)
end

local function start_viewer_poll()
  if viewer_poll_id then return end
  viewer_poll_last = ""
  viewer_poll_id = vim.fn.timer_start(200, function()
    local f = io.open("/tmp/bigide-viewer-current", "r")
    if not f then return end
    local path = f:read("*a"):gsub("%s+$", "")
    f:close()
    if path ~= "" and path ~= viewer_poll_last then
      viewer_poll_last = path
      reveal_in_neotree(path)
    end
  end, { ["repeat"] = -1 })
end

local function stop_viewer_poll()
  if viewer_poll_id then
    vim.fn.timer_stop(viewer_poll_id)
    viewer_poll_id = nil
  end
  viewer_poll_last = ""
  os.remove("/tmp/bigide-viewer-current")
end

local function reset_display()
  vim.schedule(function()
    vim.fn.jobstart({ "tmux", "refresh-client" }, { detach = true })
    vim.cmd("redraw!")
  end)
end

local function read_and_delete(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  os.remove(path)
  if content then content = content:gsub("%s+$", "") end
  if content == "" then return nil end
  return content
end

--- Log diagnostico
local function nav_log(msg)
  local f = io.open("/tmp/bigide-nav.log", "a")
  if f then
    f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
    f:close()
  end
end

--- Trova la finestra neo-tree
local function find_neotree_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local ok, ft = pcall(function() return vim.bo[vim.api.nvim_win_get_buf(w)].filetype end)
    if ok and ft == "neo-tree" then
      return w
    end
  end
  -- Fallback: cached state
  if cached_state and cached_state.winid and vim.api.nvim_win_is_valid(cached_state.winid) then
    return cached_state.winid
  end
  return nil
end

--- Scrivi nav-root per i viewer Swift (così usano lo stesso albero di neo-tree)
local function set_nav_root()
  local root = vim.fn.getcwd()
  pcall(function()
    local f = io.open("/tmp/bigide-nav-root", "w")
    if f then f:write(root); f:close() end
  end)
end

--- Muovi cursore neo-tree al prossimo FILE (salta directory), ritorna path o nil
local function navigate_neotree(delta)
  -- Usa lo state salvato da handle_node (funziona con position=current)
  local state = cached_state
  if not state or not state.tree then
    nav_log("FAIL: no cached state")
    return nil
  end

  local win = find_neotree_win()
  if not win then
    nav_log("FAIL: no neo-tree window")
    return nil
  end

  nav_log("navigate delta=" .. delta .. " win=" .. win)
  local cmd = delta > 0 and "j" or "k"

  for _ = 1, 100 do
    local line = vim.api.nvim_win_get_cursor(win)[1]
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! " .. cmd)
    end)
    local new_line = vim.api.nvim_win_get_cursor(win)[1]
    if new_line == line then
      nav_log("  edge at line " .. line)
      return nil
    end

    local node = state.tree:get_node(new_line)
    if node and node.type == "file" then
      nav_log("  -> " .. node.path)
      return node.path
    end
  end
  nav_log("  exhausted")
  return nil
end

--- Gestisci segnale di navigazione: "direzione\npath" o path diretto
local function handle_nav_signal(signal_file)
  local signal = read_and_delete(signal_file)
  if not signal then return false end

  nav_log("signal: " .. signal_file .. " -> " .. signal:gsub("\n", " | "))

  local direction = signal:match("^([^\n]+)")
  local fallback_path = signal:match("\n(.+)")

  if direction == "up" or direction == "down" then
    local delta = direction == "down" and 1 or -1
    local filepath = navigate_neotree(delta)
    if filepath then
      nav_log("OK -> " .. filepath)
      open_any_preview(filepath)
      return true
    end
    if fallback_path and fallback_path:sub(1, 1) == "/" then
      nav_log("FALLBACK -> " .. fallback_path)
      reveal_in_neotree(fallback_path)
      open_any_preview(fallback_path)
      return true
    end
    nav_log("FAILED, no fallback")
    return true
  end

  if signal:sub(1, 1) == "/" then
    reveal_in_neotree(signal)
    open_any_preview(signal)
    return true
  end

  return false
end

-- Forward declarations
local open_preview
local open_preview_image
local open_preview_doc
local open_preview_video

--- Apri la preview appropriata per un file qualsiasi
function open_any_preview(filepath)
  local name = vim.fn.fnamemodify(filepath, ":t")
  if is_image(name) then
    open_preview_image(filepath)
  elseif is_video(name) then
    open_preview_video(filepath)
  elseif is_document(name) then
    open_preview_doc(filepath)
  elseif is_text(name, filepath) then
    open_preview(filepath)
  else
    vim.fn.jobstart({ "bash", PREVIEW_BINARY_SCRIPT, filepath }, {
      on_exit = function() reset_display() end,
    })
  end
end

--- Callback on_exit della preview testo
local function on_preview_exit()
  vim.schedule(function()
    if handle_nav_signal("/tmp/bigide-preview-next") then return end
    reset_display()
  end)
end

--- Callback on_exit del viewer immagini
local function on_imgview_exit()
  vim.schedule(function()
    if handle_nav_signal("/tmp/bigide-imgview-next") then return end
    reset_display()
    local last_path = read_and_delete("/tmp/bigide-imgview-last")
    if last_path then reveal_in_neotree(last_path) end
  end)
end

--- Callback on_exit del viewer documenti
local function on_docview_exit()
  vim.schedule(function()
    if handle_nav_signal("/tmp/bigide-docview-next") then return end
    reset_display()
    local last_path = read_and_delete("/tmp/bigide-docview-last")
    if last_path then reveal_in_neotree(last_path) end
  end)
end

--- Callback on_exit del viewer video
local function on_vidview_exit()
  vim.schedule(function()
    if handle_nav_signal("/tmp/bigide-vidview-next") then return end
    reset_display()
    local last_path = read_and_delete("/tmp/bigide-vidview-last")
    if last_path then reveal_in_neotree(last_path) end
  end)
end

--- Preview video
open_preview_video = function(filepath)
  kill_imgview()
  kill_docview()
  set_nav_root()
  start_viewer_poll()
  vim.fn.jobstart({ "bash", PREVIEW_VIDEO_SCRIPT, filepath }, {
    on_exit = function() stop_viewer_poll(); on_vidview_exit() end,
  })
end

--- Preview documento
open_preview_doc = function(filepath)
  kill_imgview()
  kill_vidview()
  set_nav_root()
  start_viewer_poll()
  vim.fn.jobstart({ "bash", PREVIEW_DOC_SCRIPT, filepath }, {
    on_exit = function() stop_viewer_poll(); on_docview_exit() end,
  })
end

--- Preview testo (tmux popup)
open_preview = function(filepath)
  kill_all_viewers()
  stop_viewer_poll()
  set_nav_root()
  vim.fn.jobstart({ "bash", PREVIEW_SCRIPT, filepath }, {
    on_exit = function() on_preview_exit() end,
  })
end

--- Preview immagine
open_preview_image = function(filepath)
  kill_docview()
  kill_vidview()
  set_nav_root()
  start_viewer_poll()
  vim.fn.jobstart({ "bash", PREVIEW_IMAGE_SCRIPT, filepath }, {
    on_exit = function() stop_viewer_poll(); on_imgview_exit() end,
  })
end

--- Ricerca file (chiamata da file-search.sh via tmux send-keys)
function BigideOpenSearch()
  local f = io.open("/tmp/bigide-fzf-result", "r")
  if not f then return end
  local filepath = f:read("*a"):gsub("%s+$", "")
  f:close()
  os.remove("/tmp/bigide-fzf-result")
  if filepath == "" then return end
  reveal_in_neotree(filepath)
  vim.defer_fn(function()
    open_any_preview(filepath)
  end, 100)
end

local function open_preview_binary(filepath)
  if is_image(vim.fn.fnamemodify(filepath, ":t")) then
    open_preview_image(filepath)
  else
    vim.fn.jobstart({ "bash", PREVIEW_BINARY_SCRIPT, filepath }, {
      on_exit = function() reset_display() end,
    })
  end
end

local function handle_node(state)
  -- Salva lo state per navigazione cross-type (navigate_neotree)
  cached_state = state

  local node = state.tree:get_node()
  if node.type == "directory" then
    require("neo-tree.sources.filesystem.commands").open(state)
  elseif node.type == "file" then
    if is_video(node.name) then
      open_preview_video(node.path)
    elseif is_document(node.name) then
      open_preview_doc(node.path)
    elseif is_text(node.name, node.path) then
      open_preview(node.path)
    else
      open_preview_binary(node.path)
    end
  end
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    use_default_mappings = false,
    enable_git_status    = true,
    enable_diagnostics   = false,

    renderers = {
      file = {
        { "indent" },
        { "icon" },
        { "name", use_git_status_colors = true },
        { "git_status", highlight = "NeoTreeDimText" },
      },
      directory = {
        { "indent" },
        { "icon" },
        { "name" },
        { "git_status" },
      },
    },

    window = {
      position = "current",
      mappings = {
        ["<CR>"] = handle_node,
        ["l"]    = handle_node,
        ["h"]             = "close_node",
        ["<BS>"]          = false,
        ["."]             = false,
        ["H"]             = "toggle_hidden",
        ["R"]             = "refresh",
        ["a"]             = "add",
        ["d"]             = "delete",
        ["r"]             = "rename",
        ["y"]             = "copy_to_clipboard",
        ["x"]             = "cut_to_clipboard",
        ["p"]             = "paste_from_clipboard",
        ["?"]             = "show_help",
        ["q"]             = false,
        ["o"]             = false,
        ["e"]             = false,
        ["s"]             = false,
        ["S"]             = false,
        ["t"]             = false,
        ["w"]             = false,
        ["<Space>"]       = false,
        ["<2-LeftMouse>"] = handle_node,
      },
    },

    filesystem = {
      bind_to_cwd            = true,
      cwd_target             = { sidebar = "tab", current = "window" },
      follow_current_file    = { enabled = false },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible         = false,
        hide_dotfiles   = false,
        hide_gitignored = true,
      },
    },

    default_component_configs = {
      icon = {
        folder_closed     = "󰉋",
        folder_open       = "󰝰",
        folder_empty      = "󰉖",
        folder_empty_open = "󰷏",
        default           = "󰈔",
        highlight         = "NeoTreeFileIcon",
      },
      git_status = {
        symbols = {
          added     = "",
          modified  = "",
          deleted   = "✖",
          renamed   = "➜",
          untracked = "★",
          ignored   = "◌",
          unstaged  = "✗",
          staged    = "✓",
          conflict  = "",
        },
      },
    },
  },
}
