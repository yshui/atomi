---------------------------------------------------------------------------
--- Mouse module for awful
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module mouse
---------------------------------------------------------------------------

-- Grab environment we need
local layout = require("atomi.layout")
local aplace = require("atomi.placement")
local util = require("atomi.util")
local type = type
local ipairs = ipairs
local capi =
{
    root = root,
    mouse = mouse,
    screen = screen,
    client = client,
    mousegrabber = mousegrabber,
}

local mouse = {
    resize = require("atomi.mouse.resize"),
    snap   = require("atomi.mouse.snap"),
    drag_to_tag = require("atomi.mouse.drag_to_tag")
}

mouse.object = {}
mouse.client = {}
mouse.wibox = {}

--- The default snap distance.
-- @tfield integer atomi.mouse.snap.default_distance
-- @tparam[opt=8] integer default_distance
-- @see atomi.mouse.snap

--- Enable screen edges snapping.
-- @tfield[opt=true] boolean atomi.mouse.snap.edge_enabled

--- Enable client to client snapping.
-- @tfield[opt=true] boolean atomi.mouse.snap.client_enabled

--- Enable changing tag when a client is dragged to the edge of the screen.
-- @tfield[opt=false] integer atomi.mouse.drag_to_tag.enabled

--- The snap outline background color.
-- @beautiful beautiful.snap_bg
-- @tparam color|string|gradient|pattern color

--- The snap outline width.
-- @beautiful beautiful.snap_border_width
-- @param integer

--- The snap outline shape.
-- @beautiful beautiful.snap_shape
-- @tparam function shape A `gears.shape` compatible function

--- Move a client.
-- @function atomi.mouse.client.move
-- @param c The client to move, or the focused one if nil.
-- @param snap The pixel to snap clients.
-- @param finished_cb Deprecated, do not use
function mouse.client.move(c, snap) --luacheck: no unused args

    c = c or capi.client.focus

    if not c
        or c.fullscreen
        or c.type == "desktop"
        or c.type == "splash"
        or c.type == "dock" then
        return
    end

    -- Compute the offset
    local coords = capi.mouse.coords()
    local geo    = aplace.centered(capi.mouse,{parent=c, pretend=true})

    local offset = {
        x = geo.x - coords.x,
        y = geo.y - coords.y,
    }

    mouse.resize(c, "mouse.move", {
        placement = aplace.under_mouse,
        offset    = offset,
        snap      = snap
    })
end

mouse.client.dragtotag = { }

--- Move the wibox under the cursor.
-- @function atomi.mouse.wibox.move
--@tparam wibox w The wibox to move, or none to use that under the pointer
function mouse.wibox.move(w)
    w = w or mouse.wibox_under_pointer()
    if not w then return end

    if not w
        or w.type == "desktop"
        or w.type == "splash"
        or w.type == "dock" then
        return
    end

    -- Compute the offset
    local coords = capi.mouse.coords()
    local geo    = aplace.centered(capi.mouse,{parent=w, pretend=true})

    local offset = {
        x = geo.x - coords.x,
        y = geo.y - coords.y,
    }

    mouse.resize(w, "mouse.move", {
        placement = aplace.under_mouse,
        offset    = offset
    })
end

--- Resize a client.
-- @function atomi.mouse.client.resize
-- @param c The client to resize, or the focused one by default.
-- @tparam string corner The corner to grab on resize. Auto detected by default.
-- @tparam[opt={}] table args A set of `atomi.placement` arguments
-- @treturn string The corner (or side) name
function mouse.client.resize(c, corner, args)
    c = c or capi.client.focus

    if not c then return end

    if c.fullscreen
        or c.type == "desktop"
        or c.type == "splash"
        or c.type == "dock" then
        return
    end

    -- Move the mouse to the corner
    if corner and aplace[corner] then
        aplace[corner](capi.mouse, {parent=c})
    else
        local _
        _, corner = aplace.closest_corner(capi.mouse, {parent=c})
    end

    mouse.resize(c, "mouse.resize", args or {include_sides=true})

    return corner
end

--- Default handler for `request::geometry` signals with "mouse.resize" context.
-- @signalhandler atomi.mouse.resize_handler
-- @tparam client c The client
-- @tparam string context The context
-- @tparam[opt={}] table hints The hints to pass to the handler
function mouse.resize_handler(c, context, hints)
    if hints and context and context:find("mouse.*") then
        -- This handler only handle the floating clients. If the client is tiled,
        -- then it let the layouts handle it.
        local t = c.screen.selected_tag
        local lay = t and t.layout or nil

        if (lay and lay == layout.suit.floating) or c.floating then
            c:geometry {
                x      = hints.x,
                y      = hints.y,
                width  = hints.width,
                height = hints.height,
            }
        elseif lay and lay.resize_handler then
            lay.resize_handler(c, context, hints)
        end
    end
end

-- Older layouts implement their own mousegrabber.
-- @tparam client c The client
-- @tparam table args Additional arguments
-- @treturn boolean This return false when the resize need to be aborted
mouse.resize.add_enter_callback(function(c, args) --luacheck: no unused args
    if c.floating then return end

    local l = c.screen.selected_tag and c.screen.selected_tag.layout or nil
    if l == layout.suit.floating then return end

    if l ~= layout.suit.floating and l.mouse_resize_handler then
        capi.mousegrabber.stop()

        local geo, corner = aplace.closest_corner(capi.mouse, {parent=c})

        l.mouse_resize_handler(c, corner, geo.x, geo.y)

        return false
    end
end, "mouse.resize")

--- Get the client currently under the mouse cursor.
-- @property current_client
-- @tparam client|nil The client

function mouse.object.get_current_client()
    local obj = capi.mouse.object_under_pointer()
    if type(obj) == "client" then
        return obj
    end
end

--- Get the wibox currently under the mouse cursor.
-- @property current_wibox
-- @tparam wibox|nil The wibox

function mouse.object.get_current_wibox()
    local obj = capi.mouse.object_under_pointer()
    if type(obj) == "drawin" and obj.get_wibox then
        return obj:get_wibox()
    end
end

--- Get the widgets currently under the mouse cursor.
--
-- @property current_widgets
-- @tparam nil|table list The widget list
-- @treturn table The list of widgets.The first element is the biggest
-- container while the last is the topmost widget. The table contains *x*, *y*,
-- *width*, *height* and *widget*.
-- @treturn table The list of geometries.
-- @see wibox.find_widgets

function mouse.object.get_current_widgets()
    local w = mouse.object.get_current_wibox()
    if w then
        local geo, coords = w:geometry(), capi.mouse:coords()

        local list = w:find_widgets(coords.x - geo.x, coords.y - geo.y)

        local ret = {}

        for k, v in ipairs(list) do
            ret[k] = v.widget
        end

        return ret, list
    end
end

--- Get the topmost widget currently under the mouse cursor.
-- @property current_widget
-- @tparam widget|nil widget The widget
-- @treturn ?widget The widget
-- @treturn ?table The geometry.
-- @see wibox.find_widgets

function mouse.object.get_current_widget()
    local wdgs, geos = mouse.object.get_current_widgets()

    if wdgs then
        return wdgs[#wdgs], geos[#geos]
    end
end

--- True if the left mouse button is pressed.
-- @property is_left_mouse_button_pressed
-- @param boolean

--- True if the right mouse button is pressed.
-- @property is_right_mouse_button_pressed
-- @param boolean

--- True if the middle mouse button is pressed.
-- @property is_middle_mouse_button_pressed
-- @param boolean

for _, b in ipairs {"left", "right", "middle"} do
    mouse.object["is_".. b .."_mouse_button_pressed"] = function()
        return capi.mouse.coords().buttons[1]
    end
end

capi.client.connect_signal("request::geometry", mouse.resize_handler)

-- Set the cursor at startup
capi.root.cursor("left_ptr")

-- Implement the custom property handler
local props = {}

capi.mouse.set_newindex_miss_handler(function(_,key,value)
    if mouse.object["set_"..key] then
        mouse.object["set_"..key](value)
    elseif not mouse.object["get_"..key] then
        props[key] = value
    else
        -- If there is a getter, but no setter, then the property is read-only
        error("Cannot set '" .. tostring(key) .. " because it is read-only")
    end
end)

capi.mouse.set_index_miss_handler(function(_,key)
    if mouse.object["get_"..key] then
        return mouse.object["get_"..key]()
    else
        return props[key]
    end
end)

--- Get or set the mouse coords.
--
--
--
--![Usage example](../images/AUTOGEN_awful_mouse_coords.svg)
--
--**Usage example output**:
--
--    235
--
--
-- @usage
-- -- Get the position
--print(mouse.coords().x)
-- 
-- -- Change the position
--mouse.coords {
--    x = 185,
--    y = 10
--}
--
-- @tparam[opt=nil] table coords_table None or a table with x and y keys as mouse
--  coordinates.
-- @tparam[opt=nil] integer coords_table.x The mouse horizontal position
-- @tparam[opt=nil] integer coords_table.y The mouse vertical position
-- @tparam[opt=false] boolean silent Disable mouse::enter or mouse::leave events that
--  could be triggered by the pointer when moving.
-- @treturn integer table.x The horizontal position
-- @treturn integer table.y The vertical position
-- @treturn table table.buttons Table containing the status of buttons, e.g. field [1] is true
--  when button 1 is pressed.
-- @function mouse.coords


return mouse

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
