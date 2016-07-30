---------------------------------------------------------------------------
--- D-Bus module for atomi.
--
-- This module simply request the org.naquadah.awesome.awful name on the D-Bus
-- for futur usage by other awful modules.
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module atomi.dbus
---------------------------------------------------------------------------

-- Grab environment we need
local dbus = dbus

if dbus then
    dbus.request_name("session", "org.naquadah.awesome.awful")
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
