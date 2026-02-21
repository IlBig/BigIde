-- neo-tree: file explorer VSCode-like per BigIDE
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    -- Occupa l'intera finestra nvim (nessun buffer editor a fianco)
    window = {
      position = "current",
      mappings = {
        -- ► espandi / ◄ collassa singolo ramo
        ["l"]     = "open",
        ["h"]     = "close_node",
        ["<CR>"]  = "open",
        ["<BS>"]  = "navigate_up",
        ["."]     = "set_root",
        ["H"]     = "toggle_hidden",
        ["R"]     = "refresh",
        ["a"]     = "add",
        ["d"]     = "delete",
        ["r"]     = "rename",
        ["y"]     = "copy_to_clipboard",
        ["x"]     = "cut_to_clipboard",
        ["p"]     = "paste_from_clipboard",
        ["q"]     = "close_window",
        ["?"]     = "show_help",
      },
    },
    filesystem = {
      follow_current_file    = { enabled = false },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible        = false,
        hide_dotfiles  = false,
        hide_gitignored = true,
      },
    },
    -- Icone Nerd Font (stile VSCode Material Icons)
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
