-------------------------------------------------------------------------
--- Tooltip module for awesome objects.
--
-- A tooltip is a small hint displayed when the mouse cursor
-- hovers a specific item.
-- In awesome, a tooltip can be linked with almost any
-- object having a `:connect_signal()` method and receiving
-- `mouse::enter` and `mouse::leave` signals.
--
-- How to create a tooltip?
-- ---
--
--     myclock = atomi.proton.widget.textclock({}, "%T", 1)
--     myclock_t = atomi.tooltip({
--         objects = { myclock },
--         timer_function = function()
--                 return os.date("Today is %A %B %d %Y\nThe time is %T")
--             end,
--         })
--
-- How to add the same tooltip to multiple objects?
-- ---
--
--     myclock_t:add_to_object(obj1)
--     myclock_t:add_to_object(obj2)
--
-- Now the same tooltip is attached to `myclock`, `obj1`, `obj2`.
--
-- How to remove a tooltip from several objects?
-- ---
--
--     myclock_t:remove_from_object(obj1)
--     myclock_t:remove_from_object(obj2)
--
-- Now the same tooltip is only attached to `myclock`.
--
-- @author Sébastien Gross &lt;seb•ɱɩɲʋʃ•awesome•ɑƬ•chezwam•ɖɵʈ•org&gt;
-- @copyright 2009 Sébastien Gross
-- @release v3.5.2-1890-ge472339
-- @module atomi.tooltip
-------------------------------------------------------------------------

local mouse = mouse
local timer = require("gears.timer")
local object = require("gears.object")
local proton = require("atomi.proton")
local a_placement = require("atomi.placement")
local abutton = require("atomi.button")
local ugly = require("ugly")
local textbox = proton.widget.textbox
local background = require("atomi.proton.container.background")
local dpi = ugly.x.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs

--- Tooltip object definition.
-- @table tooltip
-- @tfield proton proton The proton displaying the tooltip.
-- @tfield boolean visible True if tooltip is visible.
local tooltip = { mt = {}  }

local instance_mt = {}

function instance_mt:__index(key)
    if key == "proton" then
        local wb = proton(self.proton_properties)
        wb:set_widget(self.marginbox)

        -- Close the tooltip when clicking it.  This gets done on release, to not
        -- emit the release event on an underlying object, e.g. the titlebar icon.
        wb:buttons(abutton({}, 1, nil, self.hide))
        rawset(self, "proton", wb)
        return wb
    end
end

-- Place the tooltip under the mouse.
--
-- @tparam tooltip self A tooltip object.
local function set_geometry(self)
    -- calculate width / height
    local n_w, n_h = self.textbox:get_preferred_size(mouse.screen)
    n_w = n_w + self.marginbox.left + self.marginbox.right
    n_h = n_h + self.marginbox.top + self.marginbox.bottom
    self.proton:geometry({ width = n_w, height = n_h })
    a_placement.next_to_mouse(self.proton)
    a_placement.no_offscreen(self.proton, mouse.screen)
end

-- Show a tooltip.
--
-- @tparam tooltip self The tooltip to show.
local function show(self)
    -- do nothing if the tooltip is already shown
    if self.visible then return end
    if self.timer then
        if not self.timer.started then
            self:timer_function()
            self.timer:start()
        end
    end
    set_geometry(self)
    self.proton.visible = true
    self.visible = true
    self:emit_signal("property::visible")
end

-- Hide a tooltip.
--
-- @tparam tooltip self The tooltip to hide.
local function hide(self)
    -- do nothing if the tooltip is already hidden
    if not self.visible then return end
    if self.timer then
        if self.timer.started then
            self.timer:stop()
        end
    end
    self.proton.visible = false
    self.visible = false
    self:emit_signal("property::visible")
end

--- Change displayed text.
--
-- @tparam tooltip self The tooltip object.
-- @tparam string  text New tooltip text, passed to
--   `atomi.proton.widget.textbox.set_text`.
tooltip.set_text = function(self, text)
    self.textbox:set_text(text)
    if self.visible then
        set_geometry(self)
    end
end

--- Change displayed markup.
--
-- @tparam tooltip self The tooltip object.
-- @tparam string  text New tooltip markup, passed to
--   `atomi.proton.widget.textbox.set_markup`.
tooltip.set_markup = function(self, text)
    self.textbox:set_markup(text)
    if self.visible then
        set_geometry(self)
    end
end

--- Change the tooltip's update interval.
--
-- @tparam tooltip self A tooltip object.
-- @tparam number timeout The timeout value.
tooltip.set_timeout = function(self, timeout)
    if self.timer then
        self.timer.timeout = timeout
    end
end

--- Add tooltip to an object.
--
-- @tparam tooltip self The tooltip.
-- @tparam gears.object obj An object with `mouse::enter` and
--   `mouse::leave` signals.
tooltip.add_to_object = function(self, obj)
    obj:connect_signal("mouse::enter", self.show)
    obj:connect_signal("mouse::leave", self.hide)
end

--- Remove tooltip from an object.
--
-- @tparam tooltip self The tooltip.
-- @tparam gears.object obj An object with `mouse::enter` and
--   `mouse::leave` signals.
tooltip.remove_from_object = function(self, obj)
    obj:disconnect_signal("mouse::enter", self.show)
    obj:disconnect_signal("mouse::leave", self.hide)
end


--- Create a new tooltip and link it to a widget.
-- Tooltips emit `property::visible` when their visibility changes.
-- @tparam table args Arguments for tooltip creation.
-- @tparam function args.timer_function A function to dynamically set the
--   tooltip text.  Its return value will be passed to
--   `atomi.proton.widget.textbox.set_markup`.
-- @tparam[opt=1] number args.timeout The timeout value for
--   `timer_function`.
-- @tparam[opt] table args.objects A list of objects linked to the tooltip.
-- @tparam[opt] number args.delay_show Delay showing the tooltip by this many
--   seconds.
-- @tparam[opt=apply_dpi(5)] integer args.margin_leftright The left/right margin for the text.
-- @tparam[opt=apply_dpi(3)] integer args.margin_topbottom The top/bottom margin for the text.
-- @treturn atomi.tooltip The created tooltip.
-- @see add_to_object
-- @see set_timeout
-- @see set_text
-- @see set_markup
tooltip.new = function(args)
    local self = setmetatable(object(), instance_mt)
    self.visible = false

    -- private data
    if args.delay_show then
        local delay_timeout

        delay_timeout = timer { timeout = args.delay_show }
        delay_timeout:connect_signal("timeout", function ()
            show(self)
            delay_timeout:stop()
        end)

        function self.show()
            if not delay_timeout.started then
                delay_timeout:start()
            end
        end
        function self.hide()
            if delay_timeout.started then
                delay_timeout:stop()
            end
            hide(self)
        end
    else
        function self.show()
            show(self)
        end
        function self.hide()
            hide(self)
        end
    end

    -- export functions
    self.set_text = tooltip.set_text
    self.set_markup = tooltip.set_markup
    self.set_timeout = tooltip.set_timeout
    self.add_to_object = tooltip.add_to_object
    self.remove_from_object = tooltip.remove_from_object

    -- setup the timer action only if needed
    if args.timer_function then
        self.timer = timer { timeout = args.timeout and args.timeout or 1 }
        self.timer_function = function()
                self:set_markup(args.timer_function())
            end
        self.timer:connect_signal("timeout", self.timer_function)
    end

    -- Set default properties
    self.proton_properties = {
        visible = false,
        ontop = true,
        border_width = ugly.tooltip_border_width or ugly.border_width or 1,
        border_color = ugly.tooltip_border_color or ugly.border_normal or "#ffcb60",
        opacity = ugly.tooltip_opacity or 1,
        bg = ugly.tooltip_bg_color or ugly.bg_focus or "#ffcb60"
    }
    local fg = ugly.tooltip_fg_color or ugly.fg_focus or "#000000"
    local font = ugly.tooltip_font or ugly.font or "terminus 6"

    self.textbox = textbox()
    self.textbox:set_font(ugly.get_font(font, mouse.screen))
    self.background = background(self.textbox)
    self.background:set_fg(fg)

    -- Add margin.
    local m_lr = args.margin_leftright or dpi(5)
    local m_tb = args.margin_topbottom or dpi(3)
    self.marginbox = proton.container.margin(self.background, m_lr, m_lr, m_tb, m_tb)

    -- Add tooltip to objects
    if args.objects then
        for _, obj in ipairs(args.objects) do
            self:add_to_object(obj)
        end
    end

    return self
end

function tooltip.mt:__call(...)
    return tooltip.new(...)
end

return setmetatable(tooltip, tooltip.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
