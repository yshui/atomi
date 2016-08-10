---------------------------------------------------------------------------
--- Wibar module for atomi.
-- This module allows you to easily create wibar and attach them to the edge of
-- a screen.
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.wibar
---------------------------------------------------------------------------

-- Grab environment we need
local capi =
{
    screen = screen,
    client = client
}
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs
local error = error
local proton = require("atomi.proton")
local ugly = require("ugly")
local util = require("atomi.util")
local placement = require("atomi.placement")

local function get_screen(s)
    return s and capi.screen[s]
end

local awfulwibar = { mt = {} }

--- Array of table with particles inside.
-- It's an array so it is ordered.
local particles = setmetatable({}, {__mode = "v"})

-- Compute the margin on one side
local function get_margin(w, position, auto_stop)
    local h_or_w = (position == "top" or position == "bottom") and "height" or "width"
    local ret = 0

    for _, v in ipairs(particles) do
        -- Ignore the wibars placed after this one
        if auto_stop and v == w then break end

        if v.position == position and v.screen == w.screen and v.visible then
            ret = ret + v[h_or_w]
        end
    end

    return ret
end

-- `honor_workarea` cannot be used as it does modify the workarea itself.
-- a manual padding has to be generated.
local function get_margins(w)
    local position = w.position
    assert(position)

    local margins = {left=0, right=0, top=0, bottom=0}

    margins[position] = get_margin(w, position, true)

    -- Avoid overlapping wibars
    if position == "left" or position == "right" then
        margins.top    = get_margin(w, "top"   )
        margins.bottom = get_margin(w, "bottom")
    end

    return margins
end

-- Create the placement function
local function gen_placement(position, stretch)
    local maximize = (position == "right" or position == "left") and
        "maximize_vertically" or "maximize_horizontally"

    return placement[position] + (stretch and placement[maximize] or nil)
end

-- Attach the placement function.
local function attach(wb, align)
    gen_placement(align, wb._stretch)(wb, {
        attach          = true,
        update_workarea = true,
        margins         = get_margins(wb)
    })
end

-- Re-attach all wibars on a given wibar screen
local function reattach(wb)
    local s = wb.screen
    for _, w in ipairs(particles) do
        if w ~= wb and w.screen == s then
            if w.detach_callback then
                w.detach_callback()
                w.detach_callback = nil
            end
            attach(w, w.position)
        end
    end
end

--- The wibar position.
-- @property position
-- @param string Either "left", right", "top" or "bottom"

local function get_position(wb)
    return wb._position or "top"
end

local function set_position(wb, position)
    -- Detach first to avoid any uneeded callbacks
    if wb.detach_callback then
        wb.detach_callback()

        -- Avoid disconnecting twice, this produces a lot of warnings
        wb.detach_callback = nil
    end

    -- Move the wibar to the end of the list to avoid messing up the others in
    -- case there is stacked wibars on one side.
    if wb._position then
        for k, w in ipairs(particles) do
            if w == wb then
                table.remove(particles, k)
            end
        end
        table.insert(particles, wb)
    end

    -- In case the position changed, it may be necessary to reset the size
    if (wb._position == "left" or wb._position == "right")
      and (position == "top" or position == "bottom") then
        wb.height = math.ceil(ugly.get_font_height(wb.font, wb.screen) * 1.5)
    elseif (wb._position == "top" or wb._position == "bottom")
      and (position == "left" or position == "right") then
        wb.width = math.ceil(ugly.get_font_height(wb.font, wb.screen) * 1.5)
    end

    -- Changing the position will also cause the other margins to be invalidated.
    -- For example, adding a wibar to the top will change the margins of any left
    -- or right wibars. To solve, this, they need to be re-attached.
    reattach(wb)

    -- Set the new position
    wb._position = position

    -- Attach to the new position
    attach(wb, position)
end

--- Stretch the wibar.
--
-- @property stretch
-- @param[opt=true] boolean

local function get_stretch(w)
    return w._stretch
end

local function set_stretch(w, value)
    w._stretch = value

    attach(w, w.position)
end

--- Remove a wibar.
-- @function remove
local function remove(self)
    self.visible = false

    if self.detach_callback then
        self.detach_callback()
        self.detach_callback = nil
    end

    for k, w in ipairs(particles) do
        if w == self then
            table.remove(particles, k)
        end
    end

    self._screen = nil
end

--- Get a wibar position if it has been set, or return top.
-- @param wb The wibar
-- @deprecated atomi.wibar.get_position
-- @return The wibar position.
function awfulwibar.get_position(wb)
    util.deprecate("Use wb:get_position() instead of atomi.wibar.get_position")
    return get_position(wb)
end

--- Put a wibar on a screen at this position.
-- @param wb The wibar to attach.
-- @param position The position: top, bottom left or right.
-- @param screen This argument is deprecated, use wb.screen directly.
-- @deprecated atomi.wibar.set_position
function awfulwibar.set_position(wb, position, screen) --luacheck: no unused args
    util.deprecate("Use wb:set_position(position) instead of atomi.wibar.set_position")

    set_position(wb, position)
end

--- Attach a wibar to a screen.
--
-- This function has been moved to the `atomi.placement` module. Calling this
-- no longer does anything.
--
-- @param wb The wibar to attach.
-- @param position The position of the wibar: top, bottom, left or right.
-- @param screen The screen to attach to
-- @see atomi.placement
-- @deprecated atomi.wibar.attach
function awfulwibar.attach(wb, position, screen) --luacheck: no unused args
    util.deprecate("atomi.wibar.attach is deprecated, use the 'attach' property"..
        " of atomi.placement. This method doesn't do anything anymore"
    )
end

--- Align a wibar.
--
-- Supported alignment are:
--
-- * top_left
-- * top_right
-- * bottom_left
-- * bottom_right
-- * left
-- * right
-- * top
-- * bottom
-- * centered
-- * center_vertical
-- * center_horizontal
--
-- @param wb The wibar.
-- @param align The alignment
-- @param screen This argument is deprecated. It is not used. Use wb.screen
--  directly.
-- @deprecated atomi.wibar.align
-- @see atomi.placement.align
function awfulwibar.align(wb, align, screen) --luacheck: no unused args
    if align == "center" then
        util.deprecate("atomi.wibar.align(wb, 'center' is deprecated, use 'centered'")
        align = "centered"
    end

    if screen then
        util.deprecate("atomi.wibar.align 'screen' argument is deprecated")
    end

    if placement[align] then
        return placement[align](wb)
    end
end

--- Stretch a wibar so it takes all screen width or height.
--
-- **This function has been removed.**
--
-- @deprecated atomi.wibar.stretch
-- @see atomi.placement
-- @see stretch

--- Create a new wibar and attach it to a screen edge.
-- You can add also position key with value top, bottom, left or right.
-- You can also use width or height in % and set align to center, right or left.
-- You can also set the screen key with a screen number to attach the wibar.
-- If not specified, the primary screen is assumed.
-- @see wibar
-- @tparam[opt=nil] table arg
-- @tparam string arg.position The position.
-- @tparam string arg.stretch If the wibar need to be stretched to fill the screen.
-- @tparam integer arg.border_width Border width.
-- @tparam string arg.border_color Border color.
-- @tparam boolean arg.ontop On top of other windows.
-- @tparam string arg.cursor The mouse cursor.
-- @tparam boolean arg.visible Visibility.
-- @tparam number arg.opacity The opacity of the wibar, between 0 and 1.
-- @tparam string arg.type The window type (desktop, normal, dock, …).
-- @tparam integer arg.x The x coordinates.
-- @tparam integer arg.y The y coordinates.
-- @tparam integer arg.width The width of the wibar.
-- @tparam integer arg.height The height of the wibar.
-- @tparam screen arg.screen The wibar screen.
-- @tparam wibar.widget arg.widget The widget that the wibar displays.
-- @param arg.shape_bounding The wibar’s bounding shape as a (native) cairo surface.
-- @param arg.shape_clip The wibar’s clip shape as a (native) cairo surface.
-- @tparam color arg.bg The background of the wibar.
-- @tparam surface arg.bgimage The background image of the drawable.
-- @tparam color arg.fg The foreground (text) of the wibar.
-- @return The new wibar
-- @function atomi.wibar
function awfulwibar.new(arg)
    arg = arg or {}
    local position = arg.position or "top"
    local has_to_stretch = true
    local screen = get_screen(arg.screen or 1)

    arg.type = arg.type or "dock"

    if position ~= "top" and position ~="bottom"
            and position ~= "left" and position ~= "right" then
        error("Invalid position in atomi.wibar(), you may only use"
            .. " 'top', 'bottom', 'left' and 'right'")
    end

    -- Set default size
    if position == "left" or position == "right" then
        arg.width = arg.width or math.ceil(ugly.get_font_height(arg.font, arg.screen) * 1.5)
        if arg.height then
            has_to_stretch = false
            if arg.screen then
                local hp = tostring(arg.height):match("(%d+)%%")
                if hp then
                    arg.height = math.ceil(screen.geometry.height * hp / 100)
                end
            end
        end
    else
        arg.height = arg.height or math.ceil(ugly.get_font_height(arg.font, arg.screen) * 1.5)
        if arg.width then
            has_to_stretch = false
            if arg.screen then
                local wp = tostring(arg.width):match("(%d+)%%")
                if wp then
                    arg.width = math.ceil(screen.geometry.width * wp / 100)
                end
            end
        end
    end

    arg.dpi = ugly.x.get_dpi(screen)
    arg.screen = screen
    arg.bg = ugly.bg_normal
    arg.fg = ugly.fg_normal

    local w = proton(arg)

    w.screen   = screen
    w._screen  = screen --HACK When a screen is removed, then getbycoords wont work
    w._stretch = arg.stretch == nil and has_to_stretch or arg.stretch

    w.get_position = get_position
    w.set_position = set_position

    w.get_stretch = get_stretch
    w.set_stretch = set_stretch
    w.remove      = remove

    if arg.visible == nil then w.visible = true end

    w:set_position(position)

    table.insert(particles, w)

    w:connect_signal("property::visible", function() reattach(w) end)

    return w
end

capi.screen.connect_signal("removed", function(s)
    for _, wibar in ipairs(particles) do
        if wibar._screen == s then
            wibar:remove()
        end
    end
end)

function awfulwibar.mt:__call(...)
    return awfulwibar.new(...)
end

--Imported documentation

--- Border width.
--
-- **Signal:**
--
--  * *property::border_width*
--
-- @property border_width
-- @param integer

--- Border color.
--
-- Please note that this property only support string based 24 bit or 32 bit
-- colors:
--
--    Red Blue
--     _|  _|
--    #FF00FF
--       T‾
--     Green
--
--
--    Red Blue
--     _|  _|
--    #FF00FF00
--       T‾  ‾T
--    Green   Alpha
--
-- **Signal:**
--
--  * *property::border_color*
--
-- @property border_color
-- @param string

--- On top of other windows.
--
-- **Signal:**
--
--  * *property::ontop*
--
-- @property ontop
-- @param boolean

--- The mouse cursor.
--
-- **Signal:**
--
--  * *property::cursor*
--
-- @property cursor
-- @param string
-- @see mouse

--- Visibility.
--
-- **Signal:**
--
--  * *property::visible*
--
-- @property visible
-- @param boolean

--- The opacity of the wibar, between 0 and 1.
--
-- **Signal:**
--
--  * *property::opacity*
--
-- @property opacity
-- @tparam number opacity (between 0 and 1)

--- The window type (desktop, normal, dock, ...).
--
-- **Signal:**
--
--  * *property::type*
--
-- @property type
-- @param string
-- @see client.type

--- The x coordinates.
--
-- **Signal:**
--
--  * *property::x*
--
-- @property x
-- @param integer

--- The y coordinates.
--
-- **Signal:**
--
--  * *property::y*
--
-- @property y
-- @param integer

--- The width of the wibar.
--
-- **Signal:**
--
--  * *property::width*
--
-- @property width
-- @param width

--- The height of the wibar.
--
-- **Signal:**
--
--  * *property::height*
--
-- @property height
-- @param height

--- The wibar screen.
--
-- @property screen
-- @param screen

---  The wibar's `drawable`.
--
-- **Signal:**
--
--  * *property::drawable*
--
-- @property drawable
-- @tparam drawable drawable

--- The widget that the `wibar` displays.
-- @property widget
-- @param widget

--- The X window id.
--
-- **Signal:**
--
--  * *property::window*
--
-- @property window
-- @param string
-- @see client.window

--- The wibar's bounding shape as a (native) cairo surface.
--
-- **Signal:**
--
--  * *property::shape_bounding*
--
-- @property shape_bounding
-- @param surface._native

--- The wibar's clip shape as a (native) cairo surface.
--
-- **Signal:**
--
--  * *property::shape_clip*
--
-- @property shape_clip
-- @param surface._native

--- Get or set mouse buttons bindings to a wibar.
--
-- @param buttons_table A table of buttons objects, or nothing.
-- @function buttons

--- Get or set wibar geometry. That's the same as accessing or setting the x,
-- y, width or height properties of a wibar.
--
-- @param A table with coordinates to modify.
-- @return A table with wibar coordinates and geometry.
-- @function geometry

--- Get or set wibar struts.
--
-- @param strut A table with new strut, or nothing
-- @return The wibar strut in a table.
-- @function struts
-- @see client.struts

--- The default background color.
-- @ugly ugly.bg_normal
-- @see bg

--- The default foreground (text) color.
-- @ugly ugly.fg_normal
-- @see fg

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @name setup
-- @class function

--- The background of the wibar.
-- @param c The background to use. This must either be a cairo pattern object,
--   nil or a string that atomi.proton.pattern() understands.
-- @property bg
-- @see atomi.proton.pattern

--- The background image of the drawable.
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
-- @param image A background image or a function
-- @property bgimage
-- @see atomi.proton.surface

--- The foreground (text) of the wibar.
-- @param c The foreground to use. This must either be a cairo pattern object,
--   nil or a string that atomi.proton.pattern() understands.
-- @property fg
-- @see atomi.proton.pattern

--- Find a widget by a point.
-- The wibar must have drawn itself at least once for this to work.
-- @tparam number x X coordinate of the point
-- @tparam number y Y coordinate of the point
-- @treturn table A sorted table of widgets positions. The first element is the biggest
-- container while the last is the topmost widget. The table contains *x*, *y*,
-- *width*, *height* and *widget*.
-- @name find_widgets
-- @class function


return setmetatable(awfulwibar, awfulwibar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
