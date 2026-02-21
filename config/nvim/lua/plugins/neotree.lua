-- neo-tree: file explorer VSCode-like per BigIDE
-- FILE TREE ONLY: nessuna apertura/modifica file, nessuna chiusura nvim
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
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
        ["h"]            = "close_node",
        ["<BS>"]         = false,  -- disabilitato: non uscire dalla root progetto
        ["."]            = false,  -- disabilitato: non cambiare root
        ["H"]            = "toggle_hidden",
        ["R"]            = "refresh",
        ["a"]            = "add",
        ["d"]            = "delete",
        ["r"]            = "rename",
        ["y"]            = "copy_to_clipboard",
        ["x"]            = "cut_to_clipboard",
        ["p"]            = "paste_from_clipboard",
        ["?"]            = "show_help",
        -- Disabilita esplicitamente apertura file e chiusura finestra
        ["q"]            = false,
        ["o"]            = false,
        ["<2-LeftMouse>"]= false,
        ["s"]            = false,  -- open_split
        ["S"]            = false,  -- open_vsplit
        ["t"]            = false,  -- open_tabnew
        ["w"]            = false,  -- open_with_window_picker
      },
    },
    filesystem = {
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
        folder_closed = "",
        folder_open   = "",
        folder_empty  = "",
        default       = "",
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
