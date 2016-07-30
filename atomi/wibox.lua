---------------------------------------------------------------------------
--- This module is deprecated and has been renamed `atomi.wibar`
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release v3.5.2-1890-ge472339
-- @module atomi.wibox
---------------------------------------------------------------------------
local util = require("atomi.util")

return util.deprecate_class(require("atomi.wibar"), "atomi.wibox", "atomi.wibar")

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
