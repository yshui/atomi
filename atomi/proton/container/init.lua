---------------------------------------------------------------------------
--- Collection of containers that can be used in widget boxes
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.container
---------------------------------------------------------------------------
local base = require("wibox.widget.base")

return setmetatable({
    rotate = require("wibox.container.rotate");
    margin = require("wibox.container.margin");
    mirror = require("wibox.container.mirror");
    constraint = require("wibox.container.constraint");
    scroll = require("wibox.container.scroll");
    background = require("wibox.container.background");
}, {__call = function(_, args) return base.make_widget_declarative(args) end})

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
