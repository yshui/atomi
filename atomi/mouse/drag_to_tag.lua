---------------------------------------------------------------------------
--- When the the mouse reach the end of the screen, then switch tag instead
--  of screens.
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @submodule mouse
---------------------------------------------------------------------------

local capi = {screen = screen, mouse = mouse}
local util = require("atomi.util")
local tag = require("atomi.tag")
local resize = require("atomi.mouse.resize")

local module = {}

function module.drag_to_tag(c)
    if (not c) or (not c.valid) then return end

    local coords = capi.mouse.coords()

    local dir = nil

    local wa = capi.screen[c.screen].workarea

    if coords.x >= wa.x + wa.width - 1 then
        capi.mouse.coords({ x = wa.x + 2 }, true)
        dir = "right"
    elseif coords.x <= wa.x + 1 then
        capi.mouse.coords({ x = wa.x + wa.width - 2 }, true)
        dir = "left"
    end

    local tags = c.screen.tags
    local t = c.screen.selected_tag
    local idx = t.index

    if dir then

        if dir == "right" then
            local newtag = tags[util.cycle(#tags, idx + 1)]
            c:move_to_tag(newtag)
            tag.viewnext()
        elseif dir == "left" then
            local newtag = tags[util.cycle(#tags, idx - 1)]
            c:move_to_tag(newtag)
            tag.viewprev()
        end
    end
end

resize.add_move_callback(function(c, _, _)
    if module.enabled then
        module.drag_to_tag(c)
    end
end, "mouse.move")

return setmetatable(module, {__call = function(_, ...) return module.drag_to_tag(...) end})
