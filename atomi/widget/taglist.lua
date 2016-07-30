---------------------------------------------------------------------------
--- Taglist widget module for awful
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.widget.taglist
---------------------------------------------------------------------------

-- Grab environment we need
local capi = { screen = screen,
               awesome = awesome,
               client = client }
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local table = table
local common = require("atomi.widget.common")
local util = require("atomi.util")
local tag = require("atomi.tag")
local ugly = require("ugly")
local fixed = require("atomi.proton.layout.fixed")
local surface = require("gears.surface")
local timer = require("gears.timer")

local function get_screen(s)
    return s and capi.screen[s]
end

local taglist = { mt = {} }
taglist.filter = {}

--- Don't need to track instances of screen
--- Tag change on one screen will affect all taglists any way
-- local instances = nil

function taglist.taglist_label(t, args, tb, other)
    if not args then args = {} end
    local theme = ugly.get()
    local bg_focus_other = args.bg_focus_other or theme.taglist_bg_focus_other
    local fg_focus_other = args.fg_focus_other or theme.taglist_fg_focus_other
    local fg_focus = args.fg_focus or theme.taglist_fg_focus or theme.fg_focus
    local bg_focus = args.bg_focus or theme.taglist_bg_focus or theme.bg_focus
    local fg_urgent = args.fg_urgent or theme.taglist_fg_urgent or theme.fg_urgent
    local bg_urgent = args.bg_urgent or theme.taglist_bg_urgent or theme.bg_urgent
    local bg_occupied = args.bg_occupied or theme.taglist_bg_occupied
    local fg_occupied = args.fg_occupied or theme.taglist_fg_occupied
    local bg_empty = args.bg_empty or theme.taglist_bg_empty
    local fg_empty = args.fg_empty or theme.taglist_fg_empty
    local taglist_squares_sel = args.squares_sel or theme.taglist_squares_sel
    local taglist_squares_unsel = args.squares_unsel or theme.taglist_squares_unsel
    local taglist_squares_sel_empty = args.squares_sel_empty or theme.taglist_squares_sel_empty
    local taglist_squares_unsel_empty = args.squares_unsel_empty or theme.taglist_squares_unsel_empty
    local taglist_squares_resize = theme.taglist_squares_resize or args.squares_resize or "true"
    local taglist_disable_icon = args.taglist_disable_icon or theme.taglist_disable_icon or false
    local font = args.font or theme.taglist_font or theme.font or ""
    local text = nil
    local sel = capi.client.focus
    local bg_color = nil
    local fg_color = nil
    local bg_image
    local icon
    -- TODO: Re-implement bg_resize
    local bg_resize = false -- luacheck: ignore
    local is_selected = false
    local cls = t:clients()

    if sel and taglist_squares_sel then
        -- Check that the selected client is tagged with 't'.
        local seltags = sel:tags()
        for _, v in ipairs(seltags) do
            if v == t then
                bg_image = taglist_squares_sel
                bg_resize = taglist_squares_resize == "true"
                is_selected = true
                break
            end
        end
    end
    if #cls == 0 and t.selected and taglist_squares_sel_empty then
        bg_image = taglist_squares_sel_empty
        bg_resize = taglist_squares_resize == "true"
    elseif not is_selected then
        if #cls > 0 then
            if taglist_squares_unsel then
                bg_image = taglist_squares_unsel
                bg_resize = taglist_squares_resize == "true"
            end
            if bg_occupied then bg_color = bg_occupied end
            if fg_occupied then fg_color = fg_occupied end
        else
            if taglist_squares_unsel_empty then
                bg_image = taglist_squares_unsel_empty
                bg_resize = taglist_squares_resize == "true"
            end
            if bg_empty then bg_color = bg_empty end
            if fg_empty then fg_color = fg_empty end
        end
    end
    if t.selected then
        if not other then
            bg_color = bg_focus
            fg_color = fg_focus
        else
            bg_color = bg_focus_other
            fg_color = fg_focus_other
        end
    elseif tag.getproperty(t, "urgent") then
        if bg_urgent then bg_color = bg_urgent end
        if fg_urgent then fg_color = fg_urgent end
    end
    if not tag.getproperty(t, "icon_only") then
        if fg_color then
            text = "<span color='" .. util.ensure_pango_color(fg_color) ..
                "'>" .. (util.escape(t.name) or "") .. "</span>"
        else
            text = (util.escape(t.name) or "")
        end
    end
    if not taglist_disable_icon then
        if t.icon then
            icon = surface.load(t.icon)
        end
    end

    tb:set_font(ugly.get_font("DejaVu Sans Mono 8"))

    return text, bg_color, bg_image, not taglist_disable_icon and icon or nil
end

local function taglist_update(s, w, buttons, filter, data, style, update_function)
    local tags = {}
    for _, t in ipairs(root.tags()) do
        if not tag.getproperty(t, "hide") and filter(t) then
            table.insert(tags, t)
        end
    end

    local function label(c, tb) return taglist.taglist_label(c, style, tb, c.screen ~= s) end

    update_function(w, nil, ugly.x.get_dpi(s), buttons, label, data, tags)
end

--- Create a new taglist widget. The last two arguments (update_function
-- and base_widget) serve to customize the layout of the taglist (eg. to
-- make it vertical). For that, you will need to copy the
-- atomi.widget.common.list_update function, make your changes to it
-- and pass it as update_function here. Also change the base_widget if the
-- default is not what you want.
-- @param screen The screen to draw taglist for.
-- @param filter Filter function to define what clients will be listed.
-- @param buttons A table with buttons binding to set.
-- @param style The style overrides default theme.
-- @param[opt] update_function Function to create a tag widget on each
--   update. @see atomi.widget.common.
-- @param[opt] base_widget Optional container widget for tag widgets. Default
--   is wibox.layout.fixed.horizontal().
-- @param base_widget.bg_focus The background color for focused client.
-- @param base_widget.fg_focus The foreground color for focused client.
-- @param base_widget.bg_urgent The background color for urgent clients.
-- @param base_widget.fg_urgent The foreground color for urgent clients.
-- @param[opt] base_widget.squares_sel A user provided image for selected squares.
-- @param[opt] base_widget.squares_unsel A user provided image for unselected squares.
-- @param[opt] base_widget.squares_sel_empty A user provided image for selected squares for empty tags.
-- @param[opt] base_widget.squares_unsel_empty A user provided image for unselected squares for empty tags.
-- @param[opt] base_widget.squares_resize True or false to resize squares.
-- @param base_widget.font The font.
function taglist.new(screen, filter, buttons, style, update_function, base_widget)
    screen = get_screen(screen)
    local uf = update_function or common.list_update
    local w = base_widget or fixed.horizontal()

    local data = setmetatable({}, { __mode = 'k' })

    local queued_update = false
    function w._do_taglist_update()
        -- Add a delayed callback for the first update.
        if not queued_update then
            timer.delayed_call(function()
                if screen.valid then
                    taglist_update(screen, w, buttons, filter, data, style, uf)
                end
                queued_update = false
            end)
            queued_update = true
        end
    end

    local function update_callback()
        w._do_taglist_update()
    end

    capi.client.connect_signal("focus", update_callback)
    capi.client.connect_signal("unfocus", update_callback)
    tag.attached_connect_signal(nil, "property::selected", update_callback)
    tag.attached_connect_signal(nil, "property::icon", update_callback)
    tag.attached_connect_signal(nil, "property::hide", update_callback)
    tag.attached_connect_signal(nil, "property::name", update_callback)
    tag.attached_connect_signal(nil, "property::activated", update_callback)
    tag.attached_connect_signal(nil, "property::screen", update_callback)
    tag.attached_connect_signal(nil, "property::index", update_callback)
    tag.attached_connect_signal(nil, "property::urgent", update_callback)
    capi.client.connect_signal("property::screen", update_callback)
    capi.client.connect_signal("tagged", update_callback)
    capi.client.connect_signal("untagged", update_callback)
    capi.client.connect_signal("unmanage", update_callback)

    w._do_taglist_update()
    return w
end

--- Filtering function to include all nonempty tags on the screen.
-- @param t The tag.
-- @return true if t is not empty, else false
function taglist.filter.noempty(t)
    return #t:clients() > 0 or t.selected
end

--- Filtering function to include selected tags on the screen.
-- @param t The tag.
-- @return true if t is not empty, else false
function taglist.filter.selected(t)
    return t.selected
end

--- Filtering function to include all tags on the screen.
-- @return true
function taglist.filter.all()
    return true
end

function taglist.mt:__call(...)
    return taglist.new(...)
end


return setmetatable(taglist, taglist.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
