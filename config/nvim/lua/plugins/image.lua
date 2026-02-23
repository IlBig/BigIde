-- image.nvim: preview immagini ad alta qualità (Kitty Graphics Protocol)
-- Gestisce il ciclo di ridisegno tmux → immagini persistenti nel float window
-- processor=magick_cli usa convert/identify CLI (no luarocks necessario)

return {
  "3rd/image.nvim",
  lazy = true,
  opts = {
    backend   = "kitty",
    processor = "magick_cli",
    integrations = {},
    max_width_window_percentage  = 90,
    max_height_window_percentage = 90,
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = {
      "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp",
      "*.heic", "*.heif", "*.bmp", "*.tiff", "*.tif",
      "*.avif", "*.svg",
    },
  },
}
