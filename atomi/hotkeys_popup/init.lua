---------------------------------------------------------------------------
--- Popup widget which shows current hotkeys and their descriptions.
--
-- @author Yauheni Kirylau &lt;yawghen@gmail.com&gt;
-- @copyright 2014-2015 Yauheni Kirylau
-- @release v3.5.2-1890-ge472339
-- @module atomi.hotkeys_popup
---------------------------------------------------------------------------


local hotkeys_popup = {
  widget = require("atomi.hotkeys_popup.widget"),
  keys = require("atomi.hotkeys_popup.keys")
}
hotkeys_popup.show_help = hotkeys_popup.widget.show_help
return hotkeys_popup

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
