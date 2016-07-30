---------------------------------------------------------------------------
-- This class has been moved to `wibox.container.`
--
-- @author Lukáš Hrázký
-- @copyright 2012 Lukáš Hrázký
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.layout.constraint
---------------------------------------------------------------------------

local util = require("atomi.util")

return util.deprecate_class(
    require("wibox.container.constraint"),
    "wibox.layout.constraint",
    "wibox.container.constraint"
)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
