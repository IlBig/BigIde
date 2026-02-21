-- neo-tree: file explorer VSCode-like per BigIDE
-- FILE TREE ONLY: nessuna apertura/modifica file, nessuna chiusura nvim
return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",  -- icone per tipo file
    "MunifTanjim/nui.nvim",
  },
  opts = {
    -- Usa nvim-web-devicons per icone per tipo di file
    use_default_mappings = false,
    enable_git_status    = true,
    enable_diagnostics   = false,

    window = {
      position = "current",
      mappings = {
        -- ► espandi cartella / ◄ collassa — NON apre file
        ["l"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" then
            require("neo-tree.sources.filesystem.commands").open(state)
          end
        end,
        ["<CR>"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" then
            require("neo-tree.sources.filesystem.commands").open(state)
          end
        end,
        ["h"]             = "close_node",
        ["<BS>"]          = false,   -- bloccato: non uscire dalla root progetto
        ["."]             = false,   -- bloccato: non cambiare root
        ["H"]             = "toggle_hidden",
        ["R"]             = "refresh",
        ["a"]             = "add",
        ["d"]             = "delete",
        ["r"]             = "rename",
        ["y"]             = "copy_to_clipboard",
        ["x"]             = "cut_to_clipboard",
        ["p"]             = "paste_from_clipboard",
        ["?"]             = "show_help",
        -- Apertura file / chiusura finestra: tutti disabilitati
        ["q"]             = false,
        ["o"]             = false,
        ["e"]             = false,
        ["s"]             = false,
        ["S"]             = false,
        ["t"]             = false,
        ["w"]             = false,
        ["<2-LeftMouse>"] = false,
      },
    },

    filesystem = {
      bind_to_cwd            = true,   -- root = cwd al lancio (= cartella progetto)
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
      -- Icone cartelle (Nerd Fonts v3)
      icon = {
        folder_closed   = "󰉋",
        folder_open     = "󰝰",
        folder_empty    = "󰉖",
        folder_empty_open = "󰷏",
        default         = "󰈔",
        highlight       = "NeoTreeFileIcon",
      },
      -- Indicatori git affianco ai file
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
