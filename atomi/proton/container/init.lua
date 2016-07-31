---------------------------------------------------------------------------
--- Collection of containers that can be used in widget boxes
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.proton.container
---------------------------------------------------------------------------
local base = require("atomi.proton.widget.base")

return setmetatable({
    rotate = require("atomi.proton.container.rotate");
    margin = require("atomi.proton.container.margin");
    mirror = require("atomi.proton.container.mirror");
    constraint = require("atomi.proton.container.constraint");
    scroll = require("atomi.proton.container.scroll");
    background = require("atomi.proton.container.background");
}, {__call = function(_, args) return base.make_widget_declarative(args) end})

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
