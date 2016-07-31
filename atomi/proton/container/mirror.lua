---------------------------------------------------------------------------
--
--
--
--![Usage example](../images/AUTOGEN_wibox_container_defaults_mirror.svg)
--
-- @author dodo
-- @copyright 2012 dodo
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.proton.container.mirror
---------------------------------------------------------------------------

local type = type
local error = error
local ipairs = ipairs
local setmetatable = setmetatable
local base = require("atomi.proton.widget.base")
local matrix = require("gears.matrix")
local util = require("atomi.util")

local mirror = { mt = {} }

-- Layout this layout
function mirror:layout(_, width, height)
    if not self._private.widget then return end

    local m = matrix.identity
    local t = { x = 0, y = 0 } -- translation
    local s = { x = 1, y = 1 } -- scale
    if self._private.horizontal then
        t.x = width
        s.x = -1
    end
    if self._private.vertical then
        t.y = height
        s.y = -1
    end
    m = m:translate(t.x, t.y)
    m = m:scale(s.x, s.y)

    return { base.place_widget_via_matrix(self._private.widget, m, width, height) }
end

-- Fit this layout into the given area
function mirror:fit(context, ...)
    if not self._private.widget then
        return 0, 0
    end
    return base.fit_widget(self, context, self._private.widget, ...)
end

--- The widget to be reflected.
-- @property widget
-- @tparam widget widget The widget

function mirror:set_widget(widget)
    if widget then
        base.check_widget(widget)
    end
    self._private.widget = widget
    self:emit_signal("widget::layout_changed")
end

function mirror:get_widget()
    return self._private.widget
end

--- Get the number of children element
-- @treturn table The children
function mirror:get_children()
    return {self._private.widget}
end

--- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function mirror:set_children(children)
    self:set_widget(children[1])
end

--- Reset this layout. The widget will be removed and the axes reset.
function mirror:reset()
    self._private.horizontal = false
    self._private.vertical = false
    self:set_widget(nil)
end

function mirror:set_reflection(reflection)
    if type(reflection) ~= 'table' then
        error("Invalid type of reflection for mirror layout: " ..
              type(reflection) .. " (should be a table)")
    end
    for _, ref in ipairs({"horizontal", "vertical"}) do
        if reflection[ref] ~= nil then
            self._private[ref] = reflection[ref]
        end
    end
    self:emit_signal("widget::layout_changed")
end

--- Get the reflection of this mirror layout.
-- @property reflection
-- @param table reflection A table of booleans with the keys "horizontal", "vertical".
-- @param boolean reflection.horizontal
-- @param boolean reflection.vertical

function mirror:get_reflection()
    return { horizontal = self._private.horizontal, vertical = self._private.vertical }
end

--- Returns a new mirror container.
-- A mirror container mirrors a given widget. Use
-- `:set_widget()` to set the widget and
-- `:set_horizontal()` and `:set_vertical()` for the direction.
-- horizontal and vertical are by default false which doesn't change anything.
-- @param[opt] widget The widget to display.
-- @param[opt] reflection A table describing the reflection to apply.
-- @treturn table A new mirror container
-- @function atomi.proton.container.mirror
local function new(widget, reflection)
    local ret = base.make_widget(nil, nil, {enable_properties = true})
    ret._private.horizontal = false
    ret._private.vertical = false

    util.table.crush(ret, mirror, true)

    ret:set_widget(widget)
    ret:set_reflection(reflection or {})

    return ret
end

function mirror.mt:__call(...)
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


return setmetatable(mirror, mirror.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
