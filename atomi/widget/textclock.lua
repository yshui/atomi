---------------------------------------------------------------------------
--- Text clock widget.
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.proton.widget.textclock
---------------------------------------------------------------------------

local setmetatable = setmetatable
local os = os
local ugly = require("ugly")
local textbox = require("atomi.proton.widget.textbox")
local timer = require("gears.timer")
local DateTime = require("lgi").GLib.DateTime

local textclock = { mt = {} }

--- This lowers the timeout so that it occurs "correctly". For example, a timeout
-- of 60 is rounded so that it occurs the next time the clock reads ":00 seconds".
local function calc_timeout(real_timeout)
    return real_timeout - os.time() % real_timeout
end

--- Create a textclock widget. It draws the time it is in a textbox.
--
-- @tparam[opt=" %a %b %d, %H:%M "] string format The time format.
-- @tparam[opt=60] number timeout How often update the time (in seconds).
-- @treturn table A textbox widget.
-- @function atomi.proton.widget.textclock
function textclock.new(s, format, timeout)
    format = format or " %a %b %d, %H:%M "
    timeout = timeout or 60

    local w = textbox(ugly.get_font(ugly.font))
    local t
    function w._private.textclock_update_cb()
        w:set_markup(DateTime.new_now_local():format(format))
        t.timeout = calc_timeout(timeout)
        t:again()
        return true -- Continue the timer
    end
    t = timer.weak_start_new(timeout, w._private.textclock_update_cb)
    t:emit_signal("timeout")
    return w
end

function textclock.mt:__call(...)
    return textclock.new(...)
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


return setmetatable(textclock, textclock.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
