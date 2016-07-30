---------------------------------------------------------------------------
-- @author Uli Schlachter &lt;psychon@znc.in&gt;
-- @copyright 2014 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @module photon
---------------------------------------------------------------------------

local photon = require("atomi.photon.core")
if dbus then
    photon.dbus = require("atomi.photon.dbus")
end

return photon

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
