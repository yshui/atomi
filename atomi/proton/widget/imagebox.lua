---------------------------------------------------------------------------
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_defaults_imagebox.svg)
--
-- @usage
--wibox.widget {
--    image  = beautiful.awesome_icon,
--    resize = false,
--    widget = wibox.widget.imagebox
--}
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.widget.imagebox
---------------------------------------------------------------------------

local base = require("wibox.widget.base")
local surface = require("gears.surface")
local util = require("atomi.util")
local setmetatable = setmetatable
local type = type
local print = print
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local imagebox = { mt = {} }

-- Draw an imagebox with the given cairo context in the given geometry.
function imagebox:draw(_, cr, width, height)
    if not self._private.image then return end
    if width == 0 or height == 0 then return end

    if not self._private.resize_forbidden then
        -- Let's scale the image so that it fits into (width, height)
        local w = self._private.image:get_width()
        local h = self._private.image:get_height()
        local aspect = width / w
        local aspect_h = height / h
        if aspect > aspect_h then aspect = aspect_h end

        cr:scale(aspect, aspect)
    end

    -- Set the clip
    if self._private.clip_shape then
        cr:clip(self._private.clip_shape(cr, width, height, unpack(self._private.clip_args)))
    end

    cr:set_source_surface(self._private.image, 0, 0)
    cr:paint()
end

-- Fit the imagebox into the given geometry
function imagebox:fit(_, width, height)
    if not self._private.image then
        return 0, 0
    end

    local w = self._private.image:get_width()
    local h = self._private.image:get_height()

    if w > width then
        h = h * width / w
        w = width
    end
    if h > height then
        w = w * height / h
        h = height
    end

    if h == 0 or w == 0 then
        return 0, 0
    end

    if not self._private.resize_forbidden then
        local aspect = width / w
        local aspect_h = height / h

        -- Use the smaller one of the two aspect ratios.
        if aspect > aspect_h then aspect = aspect_h end

        w, h = w * aspect, h * aspect
    end

    return w, h
end

--- Set an imagebox' image
-- @property image
-- @param image Either a string or a cairo image surface. A string is
--   interpreted as the path to a png image file.
-- @return true on success, false if the image cannot be used

function imagebox:set_image(image)
    if type(image) == "string" then
        image = surface.load(image)
        if not image then
            print(debug.traceback())
            return false
        end
    end

    image = surface.load(image)

    if image then
        local w = image.width
        local h = image.height
        if w <= 0 or h <= 0 then
            return false
        end
    end

    if self._private.image == image then
        -- The image could have been modified, so better redraw
        self:emit_signal("widget::redraw_needed")
        return
    end

    self._private.image = image

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
    return true
end

--- Set a clip shape for this imagebox
-- A clip shape define an area where the content is displayed and one where it
-- is trimmed.
--
-- @property clip_shape
-- @param clip_shape A `gears_shape` compatible shape function
-- @see gears.shape
-- @see set_clip_shape

--- Set a clip shape for this imagebox
-- A clip shape define an area where the content is displayed and one where it
-- is trimmed.
--
-- Any other parameters will be passed to the clip shape function
--
-- @param clip_shape A `gears_shape` compatible shape function
-- @see gears.shape
-- @see clip_shape
function imagebox:set_clip_shape(clip_shape, ...)
    self._private.clip_shape = clip_shape
    self._private.clip_args = {...}
    self:emit_signal("widget::redraw_needed")
end

--- Should the image be resized to fit into the available space?
-- @property resize
-- @param allowed If false, the image will be clipped, else it will be resized
--   to fit into the available space.

function imagebox:set_resize(allowed)
    self._private.resize_forbidden = not allowed
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

--- Returns a new imagebox.
-- Any other arguments will be passed to the clip shape function
-- @param image the image to display, may be nil
-- @param resize_allowed If false, the image will be clipped, else it will be resized
--   to fit into the available space.
-- @param clip_shape A `gears.shape` compatible function
-- @treturn table A new `imagebox`
-- @function wibox.widget.imagebox
local function new(image, resize_allowed, clip_shape)
    local ret = base.make_widget(nil, nil, {enable_properties = true})

    util.table.crush(ret, imagebox, true)

    if image then
        ret:set_image(image)
    end
    if resize_allowed ~= nil then
        ret:set_resize(resize_allowed)
    end

    ret._private.clip_shape = clip_shape
    ret._private.clip_args = {}

    return ret
end

function imagebox.mt:__call(...)
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
-- contains the geometry of the widget relative to the wibox.
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
-- contains the geometry of the widget relative to the wibox.
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


return setmetatable(imagebox, imagebox.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
