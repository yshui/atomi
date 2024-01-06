---------------------------
-- Default awesome theme --
---------------------------

local theme = {}

local resource_dir = os.getenv("HOME").."/.config/awesome/themes/default"

theme.font          = "monospace 8"

theme.bg_normal     = "#222222"
theme.bg_focus      = "#535d6c"
theme.bg_urgent     = "#ff0000"
theme.bg_minimize   = "#444444"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#aaaaaa"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"

theme.useless_gap   = 0
theme.border_width  = 0
theme.border_normal = "#000000"
theme.border_focus  = "#00ffff"
theme.border_marked = "#91231c"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Display the taglist squares
theme.taglist_squares_sel   = resource_dir.."/taglist/squarefw.png"
theme.taglist_squares_unsel = resource_dir.."/taglist/squarew.png"
theme.taglist_bg_focus_other = "#404040"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = resource_dir.."/submenu.png"
theme.menu_height = 15
theme.menu_width  = 100

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = resource_dir.."/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = resource_dir.."/titlebar/close_focus.png"

theme.titlebar_minimize_button_normal = resource_dir.."/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = resource_dir.."/titlebar/minimize_focus.png"

theme.titlebar_ontop_button_normal_inactive = resource_dir.."/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = resource_dir.."/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = resource_dir.."/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = resource_dir.."/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = resource_dir.."/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = resource_dir.."/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = resource_dir.."/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = resource_dir.."/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = resource_dir.."/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = resource_dir.."/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = resource_dir.."/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = resource_dir.."/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = resource_dir.."/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = resource_dir.."/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = resource_dir.."/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = resource_dir.."/titlebar/maximized_focus_active.png"

theme.wallpaper = os.getenv("HOME").."/wallpaper.png"

-- You can use your own layout icons like this:
theme.layout_fairh = resource_dir.."/layouts/fairhw.png"
theme.layout_fairv = resource_dir.."/layouts/fairvw.png"
theme.layout_floating  = resource_dir.."/layouts/floatingw.png"
theme.layout_magnifier = resource_dir.."/layouts/magnifierw.png"
theme.layout_max = resource_dir.."/layouts/maxw.png"
theme.layout_fullscreen = resource_dir.."/layouts/fullscreenw.png"
theme.layout_tilebottom = resource_dir.."/layouts/tilebottomw.png"
theme.layout_tileleft   = resource_dir.."/layouts/tileleftw.png"
theme.layout_tile = resource_dir.."/layouts/tilew.png"
theme.layout_tiletop = resource_dir.."/layouts/tiletopw.png"
theme.layout_spiral  = resource_dir.."/layouts/spiralw.png"
theme.layout_dwindle = resource_dir.."/layouts/dwindlew.png"
theme.layout_cornernw = resource_dir.."/layouts/cornernww.png"
theme.layout_cornerne = resource_dir.."/layouts/cornernew.png"
theme.layout_cornersw = resource_dir.."/layouts/cornersww.png"
theme.layout_cornerse = resource_dir.."/layouts/cornersew.png"

theme.awesome_icon = resource_dir.."/icons/awesome16.png"

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
