---------------------------------------------------------------------------
--- A progressbar widget.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_defaults_progressbar.svg)
--
-- @usage
--wibox.widget {
--    max_value = 1,
--    value     = 0.33,
--    widget    = wibox.widget.progressbar
--}
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.widget.progressbar
---------------------------------------------------------------------------

local setmetatable = setmetatable
local ipairs = ipairs
local math = math
local base = require("wibox.widget.base")
local color = require("gears.color")
local beautiful = require("beautiful")

local progressbar = { mt = {} }

local data = setmetatable({}, { __mode = "k" })

--- Set the progressbar border color.
-- If the value is nil, no border will be drawn.
--
-- @function set_border_color
-- @param progressbar The progressbar.
-- @param color The border color to set.

--- Set the progressbar foreground color.
--
-- @function set_color
-- @param progressbar The progressbar.
-- @param color The progressbar color.

--- Set the progressbar background color.
--
-- @function set_background_color
-- @param progressbar The progressbar.
-- @param color The progressbar background color.

--- Set the progressbar to draw vertically. Default is false.
--
-- @function set_vertical
-- @param progressbar The progressbar.
-- @param vertical A boolean value.

--- Set the progressbar to draw ticks. Default is false.
--
-- @function set_ticks
-- @param progressbar The progressbar.
-- @param ticks A boolean value.

--- Set the progressbar ticks gap.
--
-- @function set_ticks_gap
-- @param progressbar The progressbar.
-- @param value The value.

--- Set the progressbar ticks size.
--
-- @function set_ticks_size
-- @param progressbar The progressbar.
-- @param value The value.

--- Set the maximum value the progressbar should handle.
--
-- @function set_max_value
-- @param progressbar The progressbar.
-- @param value The value.

--- The progressbar background color.
-- @beautiful beautiful.graph_bg

--- The progressbar foreground color.
-- @beautiful beautiful.graph_fg

--- The progressbar border color.
-- @beautiful beautiful.graph_border_color

local properties = { "width", "height", "border_color",
                     "color", "background_color",
                     "vertical", "value", "max_value",
                     "ticks", "ticks_gap", "ticks_size" }

function progressbar.draw(pbar, _, cr, width, height)
    local ticks_gap = data[pbar].ticks_gap or 1
    local ticks_size = data[pbar].ticks_size or 4

    -- We want one pixel wide lines
    cr:set_line_width(1)

    local value = data[pbar].value
    local max_value = data[pbar].max_value
    if value >= 0 then
        value = value / max_value
    end

    local over_drawn_width = width
    local over_drawn_height = height
    local border_width = 0
    local col = data[pbar].border_color or beautiful.progressbar_border_color
    if col then
        -- Draw border
        cr:rectangle(0.5, 0.5, width - 1, height - 1)
        cr:set_source(color(col))
        cr:stroke()

        over_drawn_width = width - 2 -- remove 2 for borders
        over_drawn_height = height - 2 -- remove 2 for borders
        border_width = 1
    end

    cr:rectangle(border_width, border_width,
                 over_drawn_width, over_drawn_height)
    cr:set_source(color(data[pbar].color or beautiful.progressbar_fg or "#ff0000"))
    cr:fill()

    -- Cover the part that is not set with a rectangle
    if data[pbar].vertical then
        local rel_height = over_drawn_height * (1 - value)
        cr:rectangle(border_width,
                     border_width,
                     over_drawn_width,
                     rel_height)
        cr:set_source(color(data[pbar].background_color or beautiful.progressbar_bg or "#000000aa"))
        cr:fill()

        -- Place smaller pieces over the gradient if ticks are enabled
        if data[pbar].ticks then
            for i=0, height / (ticks_size+ticks_gap)-border_width do
                local rel_offset = over_drawn_height / 1 - (ticks_size+ticks_gap) * i

                if rel_offset >= rel_height then
                    cr:rectangle(border_width,
                                 rel_offset,
                                 over_drawn_width,
                                 ticks_gap)
                end
            end
            cr:set_source(color(data[pbar].background_color or beautiful.progressbar_bg or "#000000aa"))
            cr:fill()
        end
    else
        local rel_x = over_drawn_width * value
        cr:rectangle(border_width + rel_x,
                     border_width,
                     over_drawn_width - rel_x,
                     over_drawn_height)
        cr:set_source(color(data[pbar].background_color or "#000000aa"))
        cr:fill()

        if data[pbar].ticks then
            for i=0, width / (ticks_size+ticks_gap)-border_width do
                local rel_offset = over_drawn_width / 1 - (ticks_size+ticks_gap) * i

                if rel_offset <= rel_x then
                    cr:rectangle(rel_offset,
                                 border_width,
                                 ticks_gap,
                                 over_drawn_height)
                end
            end
            cr:set_source(color(data[pbar].background_color or "#000000aa"))
            cr:fill()
        end
    end
end

function progressbar.fit(pbar)
    return data[pbar].width, data[pbar].height
end

--- Set the progressbar value.
-- @param value The progress bar value between 0 and 1.
function progressbar:set_value(value)
    value = value or 0
    local max_value = data[self].max_value
    data[self].value = math.min(max_value, math.max(0, value))
    self:emit_signal("widget::redraw_needed")
    return self
end

--- Set the progressbar height.
-- @param height The height to set.
function progressbar:set_height(height)
    data[self].height = height
    self:emit_signal("widget::layout_changed")
    return self
end

--- Set the progressbar width.
-- @param width The width to set.
function progressbar:set_width(width)
    data[self].width = width
    self:emit_signal("widget::layout_changed")
    return self
end

-- Build properties function
for _, prop in ipairs(properties) do
    if not progressbar["set_" .. prop] then
        progressbar["set_" .. prop] = function(pbar, value)
            data[pbar][prop] = value
            pbar:emit_signal("widget::redraw_needed")
            return pbar
        end
    end
end

--- Create a progressbar widget.
-- @param args Standard widget() arguments. You should add width and height
-- key to set progressbar geometry.
-- @return A progressbar widget.
-- @function wibox.widget.progressbar
function progressbar.new(args)
    args = args or {}
    local width = args.width or 100
    local height = args.height or 20

    args.type = "imagebox"

    local pbar = base.make_widget()

    data[pbar] = { width = width, height = height, value = 0, max_value = 1 }

    -- Set methods
    for _, prop in ipairs(properties) do
        pbar["set_" .. prop] = progressbar["set_" .. prop]
    end

    pbar.draw = progressbar.draw
    pbar.fit = progressbar.fit

    return pbar
end

function progressbar.mt:__call(...)
    return progressbar.new(...)
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


return setmetatable(progressbar, progressbar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
