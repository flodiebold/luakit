----------------------------
-- Solarized luakit theme --
----------------------------

local solarized = {}
solarized.base03 = "#002b36"
solarized.base02 = "#073642"
solarized.base01 = "#586e75"
solarized.base00 = "#657b83"
solarized.base0 = "#839496"
solarized.base1 = "#93a1a1"
solarized.base2 = "#eee8d5"
solarized.base3 = "#fdf6e3"
solarized.yellow = "#b58900"
solarized.orange = "#cb4b16"
solarized.red = "#dc322f"
solarized.magenta = "#d33682"
solarized.violet = "#6c71c4"
solarized.blue = "#268bd2"
solarized.cyan = "#2aa198"
solarized.green = "#859900"

local theme = {}

-- Default settings
theme.font = "15px monospace"
theme.fg   = solarized.base0
theme.bg   = solarized.base03

-- Genaral colours
theme.success_fg = solarized.green
theme.loaded_fg  = solarized.cyan
theme.error_fg = "#FFF"
theme.error_bg = "#F00"

-- Warning colours
theme.warning_fg = solarized.orange
theme.warning_bg = theme.bg

-- Notification colours
theme.notif_fg = solarized.base1
theme.notif_bg = theme.bg

-- Menu colours
theme.menu_fg                   = "#000"
theme.menu_bg                   = "#fff"
theme.menu_selected_fg          = "#000"
theme.menu_selected_bg          = "#FF0"
theme.menu_title_bg             = "#fff"
theme.menu_primary_title_fg     = "#f00"
theme.menu_secondary_title_fg   = "#666"

theme.menu_disabled_fg = "#999"
theme.menu_disabled_bg = theme.menu_bg
theme.menu_enabled_fg = theme.menu_fg
theme.menu_enabled_bg = theme.menu_bg
theme.menu_active_fg = "#060"
theme.menu_active_bg = theme.menu_bg

-- Proxy manager
theme.proxy_active_menu_fg      = '#000'
theme.proxy_active_menu_bg      = '#FFF'
theme.proxy_inactive_menu_fg    = '#888'
theme.proxy_inactive_menu_bg    = '#FFF'

-- Statusbar specific
theme.sbar_fg         = solarized.base0
theme.sbar_bg         = solarized.base03

-- Downloadbar specific
theme.dbar_fg         = solarized.base0
theme.dbar_bg         = solarized.base03
theme.dbar_error_fg   = solarized.red

-- Input bar specific
theme.ibar_fg           = solarized.base1
theme.ibar_bg           = solarized.base03

-- Tab label
theme.tab_fg            = solarized.base0
theme.tab_bg            = solarized.base03
theme.tab_hover_bg      = solarized.base02
theme.tab_ntheme        = "#ddd"
theme.selected_fg       = solarized.yellow
theme.selected_bg       = solarized.base02
theme.selected_ntheme   = "#ddd"
theme.loading_fg        = "#33AADD"
theme.loading_bg        = "#000"

theme.selected_private_tab_bg = "#3d295b"
theme.private_tab_bg    = "#22254a"

-- Trusted/untrusted ssl colours
theme.trust_fg          = solarized.green
theme.notrust_fg        = solarized.red

-- General colour pairings
theme.ok = { fg = solarized.base0, bg = solarized.base03 }
theme.warn = { fg = solarized.orange, bg = solarized.base03 }
theme.error = { fg = solarized.red, bg = solarized.base03 }

return theme

-- vim: et:sw=4:ts=8:sts=4:tw=80
