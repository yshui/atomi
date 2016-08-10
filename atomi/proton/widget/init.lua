---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod proton.widget
---------------------------------------------------------------------------
local base = require("atomi.proton.widget.base")

return setmetatable({
    base = base;
    textbox = require("atomi.proton.widget.textbox");
    imagebox = require("atomi.proton.widget.imagebox");
    progressbar = require("atomi.proton.widget.progressbar");
}, {__call = function(_, args) return base.make_widget_declarative(args) end})

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
