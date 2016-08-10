---------------------------------------------------------------------------
--- Widget module for awful
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.widget
---------------------------------------------------------------------------

return
{
    taglist = require("atomi.widget.taglist");
    tasklist = require("atomi.widget.tasklist");
    systray = require("atomi.widget.systray");
    textclock = require("atomi.widget.textclock");
    button = require("atomi.widget.button");
    launcher = require("atomi.widget.launcher");
    prompt = require("atomi.widget.prompt");
    layoutbox = require("atomi.widget.layoutbox");
    keyboardlayout = require("atomi.widget.keyboardlayout");
    watch = require("atomi.widget.watch");
    battery = require("atomi.widget.battery");
}

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
