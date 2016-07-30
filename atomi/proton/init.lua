---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod proton
---------------------------------------------------------------------------

local capi = {
    drawin = drawin,
    root = root,
    awesome = awesome,
    screen = screen
}
local setmetatable = setmetatable
local pairs = pairs
local type = type
local object = require("gears.object")
local grect =  require("gears.geometry").rectangle
local base = require("atomi.proton.widget.base")

--- This provides widget box windows. Every proton can also be used as if it were
-- a drawin. All drawin functions and properties are also available on protones!
-- proton
local proton = { mt = {}, object = {} }
proton.layout = require("atomi.proton.layout")
proton.container = require("atomi.proton.container")
proton.widget = require("atomi.proton.widget")
proton.drawable = require("atomi.proton.drawable")
proton.hierarchy = require("atomi.proton.hierarchy")

local force_forward = {
    shape_bounding = true,
    shape_clip = true,
}

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

--- The opacity of the proton, between 0 and 1.
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

--- The width of the proton.
--
-- **Signal:**
--
--  * *property::width*
--
-- @property width
-- @param width

--- The height of the proton.
--
-- **Signal:**
--
--  * *property::height*
--
-- @property height
-- @param height

--- The proton screen.
--
-- @property screen
-- @param screen

---  The proton's `drawable`.
--
-- **Signal:**
--
--  * *property::drawable*
--
-- @property drawable
-- @tparam drawable drawable

--- The widget that the `proton` displays.
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

--- The proton's bounding shape as a (native) cairo surface.
--
-- **Signal:**
--
--  * *property::shape_bounding*
--
-- @property shape_bounding
-- @param surface._native

--- The proton's clip shape as a (native) cairo surface.
--
-- **Signal:**
--
--  * *property::shape_clip*
--
-- @property shape_clip
-- @param surface._native

--- Get or set mouse buttons bindings to a proton.
--
-- @param buttons_table A table of buttons objects, or nothing.
-- @function buttons

--- Get or set proton geometry. That's the same as accessing or setting the x,
-- y, width or height properties of a proton.
--
-- @param A table with coordinates to modify.
-- @return A table with proton coordinates and geometry.
-- @function geometry

--- Get or set proton struts.
--
-- @param strut A table with new strut, or nothing
-- @return The proton strut in a table.
-- @function struts
-- @see client.struts

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @name setup
-- @class function

--- The background of the proton.
-- @param c The background to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @property bg
-- @see gears.color

--- The background image of the drawable.
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
-- @param image A background image or a function
-- @property bgimage
-- @see gears.surface

--- The foreground (text) of the proton.
-- @param c The foreground to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @property fg
-- @see gears.color

--- Find a widget by a point.
-- The proton must have drawn itself at least once for this to work.
-- @tparam number x X coordinate of the point
-- @tparam number y Y coordinate of the point
-- @treturn table A sorted table of widgets positions. The first element is the biggest
-- container while the last is the topmost widget. The table contains *x*, *y*,
-- *width*, *height* and *widget*.
-- @name find_widgets
-- @class function


function proton:set_widget(widget)
    self._drawable:set_widget(widget)
end

function proton:get_widget()
    return self._drawable.widget
end

proton.setup = base.widget.setup

function proton:set_bg(c)
    self._drawable:set_bg(c)
end

function proton:set_bgimage(image, ...)
    self._drawable:set_bgimage(image, ...)
end

function proton:set_fg(c)
    self._drawable:set_fg(c)
end

function proton:find_widgets(x, y)
    return self._drawable:find_widgets(x, y)
end

function proton:get_screen()
    if self.screen_assigned and self.screen_assigned.valid then
        return self.screen_assigned
    else
        self.screen_assigned = nil
    end
    local sgeos = {}

    for s in capi.screen do
        sgeos[s] = s.geometry
    end

    return grect.get_closest_by_coord(sgeos, self.x, self.y)
end

function proton:set_screen(s)
    s = capi.screen[s or 1]
    if s ~= self:get_screen() then
        self.x = s.geometry.x
        self.y = s.geometry.y
    end

    -- Remember this screen so things work correctly if screens overlap and
    -- (x,y) is not enough to figure out the correct screen.
    self.screen_assigned = s
end

for _, k in pairs{ "buttons", "struts", "geometry", "get_xproperty", "set_xproperty" } do
    proton[k] = function(self, ...)
        return self.drawin[k](self.drawin, ...)
    end
end

local function setup_signals(_proton)
    local obj
    local function clone_signal(name)
        -- When "name" is emitted on proton.drawin, also emit it on proton
        obj:connect_signal(name, function(_, ...)
            _proton:emit_signal(name, ...)
        end)
    end

    obj = _proton.drawin
    clone_signal("property::border_color")
    clone_signal("property::border_width")
    clone_signal("property::buttons")
    clone_signal("property::cursor")
    clone_signal("property::height")
    clone_signal("property::ontop")
    clone_signal("property::opacity")
    clone_signal("property::struts")
    clone_signal("property::visible")
    clone_signal("property::width")
    clone_signal("property::x")
    clone_signal("property::y")
    clone_signal("property::geometry")
    clone_signal("property::shape_bounding")
    clone_signal("property::shape_clip")

    obj = _proton._drawable
    clone_signal("button::press")
    clone_signal("button::release")
    clone_signal("mouse::enter")
    clone_signal("mouse::leave")
    clone_signal("mouse::move")
    clone_signal("property::surface")
end

--- Create a proton.
-- @tparam[opt=nil] table args
-- @tparam integer args.border_width Border width.
-- @tparam string args.border_color Border color.
-- @tparam boolean args.ontop On top of other windows.
-- @tparam string args.cursor The mouse cursor.
-- @tparam boolean args.visible Visibility.
-- @tparam number args.opacity The opacity of the proton, between 0 and 1.
-- @tparam string args.type The window type (desktop, normal, dock, …).
-- @tparam integer args.x The x coordinates.
-- @tparam integer args.y The y coordinates.
-- @tparam integer args.width The width of the proton.
-- @tparam integer args.height The height of the proton.
-- @tparam screen args.screen The proton screen.
-- @tparam proton.widget args.widget The widget that the proton displays.
-- @param args.shape_bounding The proton’s bounding shape as a (native) cairo surface.
-- @param args.shape_clip The proton’s clip shape as a (native) cairo surface.
-- @tparam color args.bg The background of the proton.
-- @tparam surface args.bgimage The background image of the drawable.
-- @tparam color args.fg The foreground (text) of the proton.
-- @treturn proton The new proton
-- @function .proton

local function new(args)
    args = args or {}
    local ret = object()
    local w = capi.drawin(args)

    -- lua 5.1 and luajit have issues with self referencing loops
    local avoid_leak = setmetatable({ret},{__mode="v"})

    function w.get_proton()
        return avoid_leak[1]
    end

    local draw_args = {
        proton = ret,
        screen = args.screen,
        dpi = args.dpi,
    }
    ret.drawin = w
    ret._drawable = proton.drawable(w.drawable, draw_args,
        "proton drawable (" .. object.modulename(3) .. ")")

    for k, v in pairs(proton) do
        if type(v) == "function" then
            ret[k] = v
        end
    end

    setup_signals(ret)
    ret.draw = ret._drawable.draw
    ret.widget_at = function(_, widget, x, y, width, height)
        return ret._drawable:widget_at(widget, x, y, width, height)
    end

    -- Set the default background
    ret:set_bg(args.bg or "#000000")
    ret:set_fg(args.fg or "#ffffff")

    -- Add __tostring method to metatable.
    local mt = {}
    local orig_string = tostring(ret)
    mt.__tostring = function()
        return string.format("proton: %s (%s)",
                             tostring(ret._drawable), orig_string)
    end
    ret = setmetatable(ret, mt)

    -- Make sure the proton is drawn at least once
    ret.draw()

    -- If a value is not found, look in the drawin
    setmetatable(ret, {
        __index = function(self, k)
            if rawget(self, "get_"..k) then
                return self["get_"..k](self)
            else
                return w[k]
            end
        end,
        __newindex = function(self, k,v)
            if rawget(self, "set_"..k) then
                self["set_"..k](self, v)
            elseif w[k] ~= nil or force_forward[k] then
                w[k] = v
            else
                rawset(self, k, v)
            end
        end
    })

    -- Set other proton specific arguments
    if args.bgimage then
        ret:set_bgimage( args.bgimage )
    end

    if args.widget then
        ret:set_widget ( args.widget  )
    end

    if args.screen then
        ret:set_screen ( args.screen  )
    end

    return ret
end

--- Redraw a proton. You should never have to call this explicitely because it is
-- automatically called when needed.
-- @param proton
-- @function draw

function proton.mt:__call(...)
    return new(...)
end

-- Extend the luaobject
object.properties(capi.drawin, {
    getter_class = proton.object,
    setter_class = proton.object,
    auto_emit    = true,
})

return setmetatable(proton, proton.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
