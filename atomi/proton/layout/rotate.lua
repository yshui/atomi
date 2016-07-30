---------------------------------------------------------------------------
-- This class has been moved to `wibox.container.rotate`
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.layout.rotate
---------------------------------------------------------------------------

local util = require("atomi.util")

return util.deprecate_class(
    require("wibox.container.rotate"),
    "wibox.layout.rotate",
    "wibox.container.rotate"
)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
