---------------------------------------------------------------------------
--- This module has been moved to `wibox.widget.graph`
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.widget.graph
---------------------------------------------------------------------------
local util = require("atomi.util")

return util.deprecate_class(
    require("wibox.widget.graph"),
    "atomi.widget.graph",
    "wibox.widget.graph"
)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
