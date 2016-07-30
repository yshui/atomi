---------------------------------------------------------------------------
--
--
--
--![Usage example](../images/AUTOGEN_wibox_container_defaults_constraint.svg)
--
-- @author Lukáš Hrázký
-- @copyright 2012 Lukáš Hrázký
-- @release v3.5.2-1890-ge472339
-- @classmod wibox.container.constraint
---------------------------------------------------------------------------

local setmetatable = setmetatable
local base = require("wibox.widget.base")
local util = require("atomi.util")
local math = math

local constraint = { mt = {} }

-- Layout a constraint layout
function constraint:layout(_, width, height)
    if self._private.widget then
        return { base.place_widget_at(self._private.widget, 0, 0, width, height) }
    end
end

-- Fit a constraint layout into the given space
function constraint:fit(context, width, height)
    local w, h
    if self._private.widget then
        w = self._private.strategy(width, self._private.width)
        h = self._private.strategy(height, self._private.height)

        w, h = base.fit_widget(self, context, self._private.widget, w, h)
    else
        w, h = 0, 0
    end

    w = self._private.strategy(w, self._private.width)
    h = self._private.strategy(h, self._private.height)

    return w, h
end

--- The widget to be constrained.
-- @property widget
-- @tparam widget widget The widget

function constraint:set_widget(widget)
    self._private.widget = widget
    self:emit_signal("widget::layout_changed")
end

function constraint:get_widget()
    return self._private.widget
end

--- Get the number of children element
-- @treturn table The children
function constraint:get_children()
    return {self._private.widget}
end

--- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function constraint:set_children(children)
    self:set_widget(children[1])
end

--- Set the strategy to use for the constraining. Valid values are 'max',
-- 'min' or 'exact'. Throws an error on invalid values.
-- @property strategy

function constraint:set_strategy(val)
    local func = {
        min = function(real_size, limit)
            return limit and math.max(limit, real_size) or real_size
        end,
        max = function(real_size, limit)
            return limit and math.min(limit, real_size) or real_size
        end,
        exact = function(real_size, limit)
            return limit or real_size
        end
    }

    if not func[val] then
        error("Invalid strategy for constraint layout: " .. tostring(val))
    end

    self._private.strategy = func[val]
    self:emit_signal("widget::layout_changed")
end

function constraint:get_strategy()
    return self._private.strategy
end

--- Set the maximum width to val. nil for no width limit.
-- @property height
-- @param number

function constraint:set_width(val)
    self._private.width = val
    self:emit_signal("widget::layout_changed")
end

function constraint:get_width()
    return self._private.width
end

--- Set the maximum height to val. nil for no height limit.
-- @property width
-- @param number

function constraint:set_height(val)
    self._private.height = val
    self:emit_signal("widget::layout_changed")
end

function constraint:get_height()
    return self._private.height
end

--- Reset this layout. The widget will be unreferenced, strategy set to "max"
-- and the constraints set to nil.
function constraint:reset()
    self._private.width = nil
    self._private.height = nil
    self:set_strategy("max")
    self:set_widget(nil)
end

--- Returns a new constraint container.
-- This container will constraint the size of a
-- widget according to the strategy. Note that this will only work for layouts
-- that respect the widget's size, eg. fixed layout. In layouts that don't
-- (fully) respect widget's requested size, the inner widget still might get
-- drawn with a size that does not fit the constraint, eg. in flex layout.
-- @param[opt] widget A widget to use.
-- @param[opt] strategy How to constraint the size. 'max' (default), 'min' or
-- 'exact'.
-- @param[opt] width The maximum width of the widget. nil for no limit.
-- @param[opt] height The maximum height of the widget. nil for no limit.
-- @treturn table A new constraint container
-- @function wibox.container.constraint
local function new(widget, strategy, width, height)
    local ret = base.make_widget(nil, nil, {enable_properties = true})

    util.table.crush(ret, constraint, true)

    ret:set_strategy(strategy or "max")
    ret:set_width(width)
    ret:set_height(height)

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function constraint.mt:__call(...)
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


return setmetatable(constraint, constraint.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
