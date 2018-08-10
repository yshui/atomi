---------------------------------------------------------------------------
--- Maximized and fullscreen layouts module for awful
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module atomi.layout.suit.max
---------------------------------------------------------------------------

-- Grab environment we need
local pairs = pairs

local max = {}

local function fmax(p, fs)
    -- Fullscreen?
    local area
    if fs then
        area = p.geometry
    else
        area = p.workarea
    end

    for _, c in pairs(p.clients) do
        local g = {
            x = area.x,
            y = area.y,
            width = area.width,
            height = area.height
        }
        -- Try to honor the aspect ratio in size_hints
        if c.size_hints ~= nil and c.size_hints_honor then
            local min_n = c.size_hints["min_aspect_num"]
            local min_d = c.size_hints["min_aspect_den"]
            local max_n = c.size_hints["max_aspect_num"]
            local max_d = c.size_hints["max_aspect_den"]
            if min_n == nil or min_d == nil then
                min_n = max_n
                min_d = max_d
            elseif max_n == nil or max_d == nil then
                max_n = min_n
                max_d = min_d
            end

            if min_n ~= nil and min_d ~= nil and max_n ~= nil and max_d ~= nil then
                -- update g according to aspect ratio
                local ar = g.width/g.height
                if ar < (min_n/min_d) then
                    -- not ok 1
                    g.height = g.width*min_d/min_n
                    g.y = (area.height-g.height)/2+area.y
                elseif ar > (max_n/max_d) then
                    -- not ok 2
                    g.width = g.height*max_n/max_d
                    g.x = (area.width-g.width)/2+area.x
                end
            end
        end
        p.geometries[c] = g
    end
end

--- Maximized layout.
-- @param screen The screen to arrange.
max.name = "max"
function max.arrange(p)
    return fmax(p, false)
end

--- Fullscreen layout.
-- @param screen The screen to arrange.
max.fullscreen = {}
max.fullscreen.name = "fullscreen"
function max.fullscreen.arrange(p)
    return fmax(p, true)
end

return max

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
