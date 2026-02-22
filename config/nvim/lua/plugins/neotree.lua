-- neo-tree: file explorer VSCode-like per BigIDE
-- Cartelle: espandi/collassa | File testo: preview modale centrata (q / Esc per chiudere)

local TEXT_EXT = {
  -- Markup / testo
  md=1, txt=1, rst=1, adoc=1, org=1, tex=1,
  -- Dati strutturati
  json=1, jsonc=1, xml=1, yaml=1, yml=1, toml=1, ini=1, cfg=1, conf=1, csv=1, tsv=1, env=1,
  -- Shell
  sh=1, bash=1, zsh=1, fish=1, ps1=1,
  -- Scripting / backend
  lua=1, py=1, rb=1, php=1, pl=1, r=1, jl=1, ex=1, exs=1, hs=1, ml=1, el=1,
  -- Web
  js=1, mjs=1, cjs=1, ts=1, jsx=1, tsx=1,
  html=1, htm=1, css=1, scss=1, sass=1, less=1, svelte=1, vue=1,
  -- Sistemi / compiled
  c=1, h=1, cpp=1, hpp=1, cs=1, java=1, go=1, rs=1,
  swift=1, kt=1, m=1, mm=1, dart=1, zig=1,
  -- DevOps / infra
  sql=1, graphql=1, proto=1, tf=1, hcl=1,
  -- Vim
  vim=1, vimrc=1, lua=1,
}

local KNOWN_NAMES = {
  Makefile=1, makefile=1, GNUmakefile=1,
  Dockerfile=1, ["docker-compose.yml"]=1,
  [".env"]=1, [".gitignore"]=1, [".gitattributes"]=1,
  [".editorconfig"]=1, Brewfile=1, Rakefile=1, Gemfile=1,
}

local function is_text(name)
  if KNOWN_NAMES[name] then return true end
  local ext = name:match("%.([^%.]+)$")
  return ext ~= nil and TEXT_EXT[ext:lower()] == 1
end

local PREVIEW_SCRIPT = vim.fn.expand("$HOME") .. "/.bigide/scripts/preview-file.sh"

local function open_preview(filepath)
  -- tmux display-popup: si apre centrato sull'intera finestra Ghostty, non sul pannello nvim
  vim.fn.jobstart({
    "bash", PREVIEW_SCRIPT, filepath
  }, { detach = true })
end

local function handle_node(state)
  local node = state.tree:get_node()
  if node.type == "directory" then
    require("neo-tree.sources.filesystem.commands").open(state)
  elseif node.type == "file" then
    if is_text(node.name) then
      open_preview(node.path)
    else
      vim.notify("File binario — anteprima non disponibile", vim.log.levels.INFO)
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
        ["<LeftMouse>"]   = "focus",
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
