---------------------------------------------------------------------------
--- AWesome Functions very UsefuL
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module atomi
---------------------------------------------------------------------------

-- TODO: This is a hack for backwards-compatibility with 3.5, remove!
local util = require("atomi.util")
local gtimer = require("gears.timer")
function timer(...) -- luacheck: ignore
    util.deprecate("gears.timer")
    return gtimer(...)
end

--TODO: This is a hack for backwards-compatibility with 3.5, remove!
-- Set atomi.util.spawn* and atomi.util.pread.
local spawn = require("atomi.spawn")

util.spawn = function(...)
   util.deprecate("atomi.spawn")
   return spawn.spawn(...)
end

util.spawn_with_shell = function(...)
   util.deprecate("atomi.spawn.with_shell")
   return spawn.with_shell(...)
end

util.pread = function()
    util.deprecate("Use io.popen() directly or look at atomi.spawn.easy_async() "
            .. "for an asynchronous alternative")
    return ""
end

return
{
    client = require("atomi.client");
    completion = require("atomi.completion");
    layout = require("atomi.layout");
    placement = require("atomi.placement");
    prompt = require("atomi.prompt");
    screen = require("atomi.screen");
    tag = require("atomi.tag");
    util = require("atomi.util");
    widget = require("atomi.widget");
    keygrabber = require("atomi.keygrabber");
    menu = require("atomi.menu");
    mouse = require("atomi.mouse");
    remote = require("atomi.remote");
    key = require("atomi.key");
    button = require("atomi.button");
    wibar = require("atomi.wibar");
    startup_notification = require("atomi.startup_notification");
    tooltip = require("atomi.tooltip");
    ewmh = require("atomi.ewmh");
    titlebar = require("atomi.titlebar");
    rules = require("atomi.rules");
    proton = require("atomi.proton");
    menubar = require("atomi.menubar");
    restore = require("atomi.restore");
    spawn = spawn;
}

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
