---------------------------------------------------------------------------
-- A container capable of changing the background color, foreground color
-- widget shape.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_container_defaults_background.svg)
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.proton.container.background
---------------------------------------------------------------------------

local base = require("atomi.proton.widget.base")
local color = require("atomi.proton.pattern")
local surface = require("atomi.proton.surface")
local cairo = require("lgi").cairo
local util = require("atomi.util")
local setmetatable = setmetatable
local type = type
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local background = { mt = {} }

-- Draw this widget
function background:draw(context, cr, width, height)
    if not self._private.widget or not self._private.widget:get_visible() then
        return
    end

    -- Keep the shape path in case there is a border
    self._private.path = nil

    if self._private.shape then
        -- Only add the offset if there is something to draw
        local offset = ((self._private.shape_border_width and self._private.shape_border_color)
            and self._private.shape_border_width or 0) / 2

        cr:translate(offset, offset)
        self._private.shape(cr, width - 2*offset, height - 2*offset, unpack(self._private.shape_args or {}))
        cr:translate(-offset, -offset)
        self._private.path = cr:copy_path()
        cr:clip()
    end

    if self._private.background then
        cr:set_source(self._private.background)
        cr:paint()
    end
    if self._private.bgimage then
        if type(self._private.bgimage) == "function" then
            self._private.bgimage(context, cr, width, height,unpack(self._private.bgimage_args))
        else
            local pattern = cairo.Pattern.create_for_surface(self._private.bgimage)
            cr:set_source(pattern)
            cr:paint()
        end
    end

end

-- Draw the border
function background:after_draw_children(_, cr)
    -- Draw the border
    if self._private.path and self._private.shape_border_width and self._private.shape_border_width > 0 then
        cr:append_path(self._private.path)
        cr:set_source(color(self._private.shape_border_color or self._private.foreground or "#ffffff"))

        cr:set_line_width(self._private.shape_border_width)
        cr:stroke()
        self._private.path = nil
    end
end

-- Prepare drawing the children of this widget
function background:before_draw_children(_, cr)
    if self._private.foreground then
        cr:set_source(self._private.foreground)
    end

    -- Clip the shape
    if self._private.path and self._private.shape_clip then
        cr:append_path(self._private.path)
        cr:clip()
    end
end

-- Layout this widget
function background:layout(_, width, height)
    if self._private.widget then
        return { base.place_widget_at(self._private.widget, 0, 0, width, height) }
    end
end

-- Fit this widget into the given area
function background:fit(context, width, height)
    if not self._private.widget then
        return 0, 0
    end

    return base.fit_widget(self, context, self._private.widget, width, height)
end

--- The widget displayed in the background widget.
-- @property widget
-- @tparam widget widget The widget to be disaplayed inside of the background
--  area

function background:set_widget(widget)
    if widget then
        base.check_widget(widget)
    end
    self._private.widget = widget
    self:emit_signal("widget::layout_changed")
end

function background:get_widget()
    return self._private.widget
end

-- Get children element
-- @treturn table The children
function background:get_children()
    return {self._private.widget}
end

-- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function background:set_children(children)
    self:set_widget(children[1])
end

--- The background color/pattern/gradient to use.
--
--
--![Usage example](../images/AUTOGEN_wibox_container_background_bg.svg)
--
-- @usage
--local text_widget = {
--    text   = 'Hello world!',
--    widget = atomi.proton.widget.textbox
--}
-- 
--parent : setup {
--    {
--        text_widget,
--        bg     = '#ff0000',
--        widget = atomi.proton.container.background
--    },
--    {
--        text_widget,
--        bg     = '#00ff00',
--        widget = atomi.proton.container.background
--    },
--    {
--        text_widget,
--        bg     = '#0000ff',
--        widget = atomi.proton.container.background
--    },
--    spacing = 10,
--    layout  = atomi.proton.layout.fixed.vertical
--}
-- @property bg
-- @param bg A color string, pattern or gradient
-- @see atomi.proton.pattern

function background:set_bg(bg)
    if bg then
        self._private.background = color(bg)
    else
        self._private.background = nil
    end
    self:emit_signal("widget::redraw_needed")
end

function background:get_bg()
    return self._private.background
end

--- The foreground (text) color/pattern/gradient to use.
--
--
--![Usage example](../images/AUTOGEN_wibox_container_background_fg.svg)
--
-- @usage
--local text_widget = {
--    text   = 'Hello world!',
--    widget = atomi.proton.widget.textbox
--}
-- 
--parent : setup {
--    {
--        text_widget,
--        fg     = '#ff0000',
--        widget = atomi.proton.container.background
--    },
--    {
--        text_widget,
--        fg     = '#00ff00',
--        widget = atomi.proton.container.background
--    },
--    {
--        text_widget,
--        fg     = '#0000ff',
--        widget = atomi.proton.container.background
--    },
--    spacing = 10,
--    layout  = atomi.proton.layout.fixed.vertical
--}
-- @property fg
-- @param fg A color string, pattern or gradient
-- @see atomi.proton.pattern

function background:set_fg(fg)
    if fg then
        self._private.foreground = color(fg)
    else
        self._private.foreground = nil
    end
    self:emit_signal("widget::redraw_needed")
end

function background:get_fg()
    return self._private.foreground
end

--- The background shap     e.
--
-- Use `set_shape` to set additional shape paramaters.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_container_background_shape.svg)
--
-- @usage
--parent : setup {
--    {
--        -- Adding a shape without margin may result in cropped output
--        {
--            text   = 'Hello world!',
--            widget = atomi.proton.widget.textbox
--        },
--        shape              = gears.shape.hexagon,
--        bg                 = beautiful.bg_normal,
--        shape_border_color = beautiful.border_color,
--        shape_border_width = beautiful.border_width,
--        widget             = atomi.proton.container.background
--    },
--    {
--        -- To solve this, use a margin
--        {
--            {
--                text   = 'Hello world!',
--                widget = atomi.proton.widget.textbox
--            },
--            left   = 10,
--            right  = 10,
--            top    = 3,
--            bottom = 3,
--            widget = atomi.proton.container.margin
--        },
--        shape              = gears.shape.hexagon,
--        bg                 = beautiful.bg_normal,
--        shape_border_color = beautiful.border_color,
--        shape_border_width = beautiful.border_width,
--        widget             = atomi.proton.container.background
--    },
--    spacing = 10,
--    layout  = atomi.proton.layout.fixed.vertical
--}
-- @property shape
-- @param shape A function taking a context, width and height as arguments
-- @see gears.shape
-- @see set_shape

--- Set the background shape.
--
-- Any other arguments will be passed to the shape function
-- @param shape A function taking a context, width and height as arguments
-- @see gears.shape
-- @see shape
function background:set_shape(shape, ...)
    self._private.shape = shape
    self._private.shape_args = {...}
    self:emit_signal("widget::redraw_needed")
end

function background:get_shape()
    return self._private.shape
end

--- When a `shape` is set, also draw a border.
--
-- See `atomi.proton.container.background.shape` for an usage example.
-- @property shape_border_width
-- @tparam number width The border width

function background:set_shape_border_width(width)
    self._private.shape_border_width = width
    self:emit_signal("widget::redraw_needed")
end

function background:get_shape_border_width()
    return self._private.shape_border_width
end

--- When a `shape` is set, also draw a border.
--
-- See `atomi.proton.container.background.shape` for an usage example.
-- @property shape_border_color
-- @param[opt=self._private.foreground] fg The border color, pattern or gradient
-- @see atomi.proton.pattern

function background:set_shape_border_color(fg)
    self._private.shape_border_color = fg
    self:emit_signal("widget::redraw_needed")
end

function background:get_shape_border_color()
    return self._private.shape_border_color
end

--- When a `shape` is set, make sure nothing is drawn outside of it.
--
--
--![Usage example](../images/AUTOGEN_wibox_container_background_clip.svg)
--
-- @usage
--parent : setup {
--    {
--        -- Some content may be outside of the shape
--        {
--            text   = 'Hello\nworld!',
--            widget = atomi.proton.widget.textbox
--        },
--        shape              = gears.shape.circle,
--        bg                 = beautiful.bg_normal,
--        shape_border_color = beautiful.border_color,
--        widget             = atomi.proton.container.background
--    },
--    {
--        -- To solve this, clip the content
--        {
--            text   = 'Hello\nworld!',
--            widget = atomi.proton.widget.textbox
--        },
--        shape_clip         = true,
--        shape              = gears.shape.circle,
--        bg                 = beautiful.bg_normal,
--        shape_border_color = beautiful.border_color,
--        widget             = atomi.proton.container.background
--    },
--    spacing = 10,
--    layout  = atomi.proton.layout.fixed.vertical
--}
-- @property shape_clip
-- @tparam boolean value If the shape clip is enable

function background:set_shape_clip(value)
    self._private.shape_clip = value
    self:emit_signal("widget::redraw_needed")
end

function background:get_shape_clip()
    return self._private.shape_clip or false
end

--- The background image to use
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
-- @property bgimage
-- @param image A background image or a function
-- @see atomi.proton.surface

function background:set_bgimage(image, ...)
    self._private.bgimage = type(image) == "function" and image or surface.load(image)
    self._private.bgimage_args = {...}
    self:emit_signal("widget::redraw_needed")
end

function background:get_bgimage()
    return self._private.bgimage
end

--- Returns a new background container.
--
-- A background container applies a background and foreground color
-- to another widget.
-- @param[opt] widget The widget to display.
-- @param[opt] bg The background to use for that widget.
-- @param[opt] shape A `gears.shape` compatible shape function
-- @function atomi.proton.container.background
local function new(widget, bg, shape)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    util.table.crush(ret, background, true)

    ret._private.shape = shape

    ret:set_widget(widget)
    ret:set_bg(bg)

    return ret
end

function background.mt:__call(...)
    return new(...)
end

--Imported documentation


--- Get a widex index.
-- @param widget The widget to look for
-- @param[opt] recursive Also check sub-widgets
-- @param[opt] ... Aditional widgets to add at the end of the \"path\"
-- @return The index
-- @return The parent layout
-- @return The path between \"self\" and \"widget\"
-- @function index

--- Get all direct and indirect children widgets.
-- This will scan all containers recursively to find widgets
-- Warning: This method it prone to stack overflow id the widget, or any of its
-- children, contain (directly or indirectly) itself.
-- @treturn table The children
-- @function get_all_children

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @function setup

--- Force a widget height.
-- @property forced_height
-- @tparam number|nil height The height (`nil` for automatic)

--- Force a widget width.
-- @property forced_width
-- @tparam number|nil width The width (`nil` for automatic)

--- The widget opacity (transparency).
-- @property opacity
-- @tparam[opt=1] number opacity The opacity (between 0 and 1)

--- The widget visibility.
-- @property visible
-- @param boolean

--- Set/get a widget's buttons.
-- @param _buttons The table of buttons that should bind to the widget.
-- @function buttons


--- When the layout (size) change.
-- This signal is emited when the previous results of `:layout()` and `:fit()`
-- are no longer valid.
-- @signal widget::layout_changed
-- @see widget::redraw_needed

--- When the widget content changed.
-- Unless this signal is emitted, `:layout()` and `:fit()` must return the same
-- result when called with the same arguments. In case this isn't the case,
-- use `widget::layout_changed`.
-- @signal widget::redraw_needed

--- When a mouse button is pressed over the widget.
-- The position of the mouse press relative to the widget while geometry
-- contains the geometry of the widget relative to the atomi.proton.
-- @signal button::press
-- @tparam table widget The widget
-- @tparam number lx The relative horizontal position.
-- @tparam number ly The relative vertical position.
-- @tparam number button The button number.
-- @tparam table mods The modifiers (mod4, mod1 (alt), Control, Shift)
-- @tparam table geometry
-- @tparam number geometry.x The vertical position
-- @tparam number geometry.y The horizontal position
-- @tparam number geometry.width The widget
-- @tparam number geometry.height The height
-- @tparam drawable geometry.drawable The `drawable`
-- @tparam table geometry.matrix_to_parent The relative `gears.matrix`
-- @tparam table geometry.matrix_to_device The absolute `gears.matrix`
-- @see mouse

--- When a mouse button is released over the widget.
-- The position of the mouse press relative to the widget while geometry
-- contains the geometry of the widget relative to the atomi.proton.
-- @signal button::release
-- @tparam table widget The widget
-- @tparam number lx The relative horizontal position.
-- @tparam number ly The relative vertical position.
-- @tparam number button The button number.
-- @tparam table mods The modifiers (mod4, mod1 (alt), Control, Shift)
-- @tparam table geometry
-- @tparam number geometry.x The vertical position
-- @tparam number geometry.y The horizontal position
-- @tparam number geometry.width The widget
-- @tparam number geometry.height The height
-- @tparam drawable geometry.drawable The `drawable`
-- @tparam table geometry.matrix_to_parent The relative `gears.matrix`
-- @tparam table geometry.matrix_to_device The absolute `gears.matrix`
-- @see mouse

--- When the mouse enter a widget.
-- @signal mouse::enter
-- @tparam table widget The widget
-- @tparam table geometry
-- @tparam number geometry.x The vertical position
-- @tparam number geometry.y The horizontal position
-- @tparam number geometry.width The widget
-- @tparam number geometry.height The height
-- @tparam drawable geometry.drawable The `drawable`
-- @tparam table geometry.matrix_to_parent The relative `gears.matrix`
-- @tparam table geometry.matrix_to_device The absolute `gears.matrix`
-- @see mouse

--- When the mouse leave a widget.
-- @signal mouse::leave
-- @tparam table widget The widget
-- @tparam table geometry
-- @tparam number geometry.x The vertical position
-- @tparam number geometry.y The horizontal position
-- @tparam number geometry.width The widget
-- @tparam number geometry.height The height
-- @tparam drawable geometry.drawable The `drawable`
-- @tparam table geometry.matrix_to_parent The relative `gears.matrix`
-- @tparam table geometry.matrix_to_device The absolute `gears.matrix`
-- @see mouse


--Imported documentation


--- Disonnect to a signal.
-- @tparam string name The name of the signal
-- @tparam function func The callback that should be disconnected
-- @function disconnect_signal

--- Emit a signal.
--
-- @tparam string name The name of the signal
-- @param ... Extra arguments for the callback functions. Each connected
--   function receives the object as first argument and then any extra arguments
--   that are given to emit_signal()
-- @function emit_signal

--- Connect to a signal.
-- @tparam string name The name of the signal
-- @tparam function func The callback to call when the signal is emitted
-- @function connect_signal

--- Connect to a signal weakly. This allows the callback function to be garbage
-- collected and automatically disconnects the signal when that happens.
--
-- **Warning:**
-- Only use this function if you really, really, really know what you
-- are doing.
-- @tparam string name The name of the signal
-- @tparam function func The callback to call when the signal is emitted
-- @function weak_connect_signal


return setmetatable(background, background.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
