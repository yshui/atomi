---------------------------------------------------------------------------
--- Collection of layouts that can be used in widget boxes
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.layout
---------------------------------------------------------------------------
local base = require("atomi.proton.widget.base")

return setmetatable({
    fixed = require("atomi.proton.layout.fixed");
    align = require("atomi.proton.layout.align");
    flex = require("atomi.proton.layout.flex");
    ratio = require("atomi.proton.layout.ratio");
    stack = require("atomi.proton.layout.stack");
}, {__call = function(_, args) return base.make_widget_declarative(args) end})

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
