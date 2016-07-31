---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.widget.systray
---------------------------------------------------------------------------

local wbase = require("atomi.proton.widget.base")
local ugly = require("ugly")
local util = require("atomi.util")
local capi = {
    awesome = awesome,
    screen = screen
}
local setmetatable = setmetatable
local error = error
local abs = math.abs

local systray = { mt = {} }

local instance = nil
local horizontal = true
local base_size = nil
local reverse = false
local display_on_screen = "primary"

--- The systray background color.
-- @ugly ugly.bg_systray
-- @param string The color (string like "#ff0000" only)

--- The systray icon spacing.
-- @ugly ugly.systray_icon_spacing
-- @tparam[opt=0] integer The icon spacing

local function should_display_on(s)
    if display_on_screen == "primary" then
        return s == capi.screen.primary
    end
    return s == display_on_screen
end

function systray:draw(context, cr, width, height)
    print("Redraw 0")
    if not should_display_on(context.screen) then
        return
    end
    print("Redraw 1")
    print(debug.traceback())

    local x, y, _, _ = wbase.rect_to_device_geometry(cr, 0, 0, width, height)
    local num_entries = capi.awesome.systray()
    local bg = ugly.bg_systray or ugly.bg_normal or "#000000"
    local spacing = ugly.systray_icon_spacing or 0

    if context and not context.proton then
        error("The systray widget can only be placed inside a proton.")
    end

    -- Figure out if the cairo context is rotated
    local dir_x, dir_y = cr:user_to_device_distance(1, 0)
    local is_rotated = abs(dir_x) < abs(dir_y)

    local in_dir, ortho, base
    if horizontal then
        in_dir, ortho = width, height
        is_rotated = not is_rotated
    else
        ortho, in_dir = width, height
    end
    if ortho * num_entries <= in_dir then
        base = ortho
    else
        base = in_dir / num_entries
    end
    capi.awesome.systray(context.proton.drawin, math.ceil(x), math.ceil(y),
                         base, is_rotated, bg, reverse, spacing)
end

function systray:fit(context, width, height)
    print("systray::fit")
    print(debug.traceback())
    if not should_display_on(context.screen) then
        return 0, 0
    end

    local num_entries = capi.awesome.systray()

    print("nent "..num_entries)
    local base = base_size
    local spacing = ugly.systray_icon_spacing or 0
    if num_entries == 0 then
        return 0, 0
    end
    if base == nil then
        if width < height then
            base = width
        else
            base = height
        end
    end
    base = base + spacing
    if horizontal then
        return base * num_entries - spacing, base
    end
    return base, base * num_entries - spacing
end

-- Check if the function was called like :foo() or .foo() and do the right thing
local function get_args(self, ...)
    if self == instance then
        return ...
    end
    return self, ...
end

--- Set the size of a single icon.
-- If this is set to nil, then the size is picked dynamically based on the
-- available space. Otherwise, any single icon has a size of `size`x`size`.
-- @tparam integer|nil size The base size
function systray:set_base_size(size)
    base_size = get_args(self, size)
    if instance then
        instance:emit_signal("widget::layout_changed")
    end
end

--- Decide between horizontal or vertical display.
-- @tparam boolean horiz Use horizontal mode?
function systray:set_horizontal(horiz)
    horizontal = get_args(self, horiz)
    if instance then
        instance:emit_signal("widget::layout_changed")
    end
end

--- Should the systray icons be displayed in reverse order?
-- @tparam boolean rev Display in reverse order
function systray:set_reverse(rev)
    reverse = get_args(self, rev)
    if instance then
        instance:emit_signal("widget::redraw_needed")
    end
end

--- Set the screen that the systray should be displayed on.
-- This can either be a screen, in which case the systray will be displayed on
-- exactly that screen, or the string `"primary"`, in which case it will be
-- visible on the primary screen. The default value is "primary".
-- @tparam screen|"primary" s The screen to display on.
function systray:set_screen(s)
    display_on_screen = get_args(self, s)
    if instance then
        instance:emit_signal("widget::layout_changed")
    end
end

--- Create the systray widget.
-- Note that this widget can only exist once.
-- @tparam boolean revers Show in the opposite direction
-- @treturn table The new `systray` widget
-- @function proton.widget.systray

local function new(revers)
    print("New systray")
    local ret = wbase.make_widget()

    util.table.crush(ret, systray, true)

    if revers then
        ret:set_reverse(true)
    end

    capi.awesome.connect_signal("systray::update", function()
        print("systray::update")
        ret:emit_signal("widget::layout_changed")
        ret:emit_signal("widget::redraw_needed")
    end)
    capi.screen.connect_signal("primary_changed", function()
        print("primary_changed")
        if display_on_screen == "primary" then
            ret:emit_signal("widget::layout_changed")
        end
    end)

    return ret
end

function systray.mt:__call(...)
    if not instance then
        instance = new(...)
    end
    return instance
end

return setmetatable(systray, systray.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
