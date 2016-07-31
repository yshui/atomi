---------------------------------------------------------------------------
--- Useful functions for tag manipulation.
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module tag
---------------------------------------------------------------------------

-- Grab environment we need
local util = require("atomi.util")
local ascreen = require("atomi.screen")
local ugly = require("ugly")
local object = require("gears.object")
local pairs = pairs
local ipairs = ipairs
local table = table
local setmetatable = setmetatable
local capi =
{
    tag = tag,
    screen = screen,
    mouse = mouse,
    client = client,
    root = root
}

local function get_screen(s)
    return s and capi.screen[s]
end

local tag = {object = {},  mt = {} }

-- Private data
local data = {}
data.history = {}
data.dynamic_cache = setmetatable({}, { __mode = 'k' })
data.tags = setmetatable({}, { __mode = 'k' })

-- History functions
tag.history = {}
tag.history.limit = 20

-- screen.tags depend on index, it cannot be used by atomi.tag
local function raw_tags(scr)
    local tmp_tags = {}
    for _, t in ipairs(root.tags()) do
        if get_screen(t.screen) == scr then
            table.insert(tmp_tags, t)
        end
    end

    return tmp_tags
end

--- The number of elements kept in the history.
-- @tfield integer atomi.tag.history.limit

--- The tag index.
--
-- The index is the position as shown in the `atomi.widget.taglist`.
--
-- **Signal:**
--
-- * *property::index*
--
-- @property index
-- @param integer
-- @treturn number The tag index.

function tag.object.set_index(self, idx)
    local scr = get_screen(tag.getproperty(self, "screen"))

    -- screen.tags cannot be used as it depend on index
    local tmp_tags = raw_tags(scr)

    if (not idx) or (idx < 1) or (idx > #tmp_tags) then
        return
    end

    local rm_index = nil

    for i, t in ipairs(tmp_tags) do
        if t == self then
            table.remove(tmp_tags, i)
            rm_index = i
            break
        end
    end

    table.insert(tmp_tags, idx, self)
    for i = idx < rm_index and idx or rm_index, #tmp_tags do
        local tmp_tag = tmp_tags[i]
        tag.object.set_screen(tmp_tag, scr)
        tag.setproperty(tmp_tag, "index", i)
    end
end

function tag.object.get_index(query_tag)
    -- Get an unordered list of tags
    local tags = raw_tags(query_tag.screen)

    local idx = tag.getproperty(query_tag, "index")

    if idx then return idx end

    -- Too bad, lets compute it
    for i, t in ipairs(tags) do
        if t == query_tag then
            tag.setproperty(t, "index", i)
            return i
        end
    end
end

--- Swap 2 tags
-- @function tag.swap
-- @see tag.swap
-- @param tag2 The second tag
-- @see client.swap
function tag.object.swap(self, tag2)
    local idx1, idx2 = tag.object.get_index(self), tag.object.get_index(tag2)
    local scr2, scr1 = tag.getproperty(tag2, "screen"), tag.getproperty(self, "screen")

    -- If they are on the same screen, avoid recomputing the whole table
    -- for nothing.
    if scr1 == scr2 then
        tag.setproperty(self, "index", idx2)
        tag.setproperty(tag2, "index", idx1)
    else
        tag.object.set_screen(tag2, scr1)
        tag.object.set_index (tag2, idx1)
        tag.object.set_screen(self, scr2)
        tag.object.set_index (self, idx2)
    end
end

--- Swap 2 tags
-- @deprecated atomi.tag.swap
-- @see tag.swap
-- @param tag1 The first tag
-- @param tag2 The second tag
function tag.swap(tag1, tag2)
    util.deprecate("Use t:swap(tag2) instead of atomi.tag.swap")

    tag.object.swap(tag1, tag2)
end

--- Add a tag.
--
-- This function allow to create tags from a set of properties:
--
--    local t = atomi.tag.add("my new tag", {
--        screen = screen.primary,
--        layout = atomi.layout.suit.max,
--    })
--
-- @function atomi.tag.add
-- @param name The tag name, a string
-- @param props The tags inital properties, a table
-- @return The created tag
-- @see tag.delete
function tag.add(name, props)
    local properties = props or {}

    -- Be sure to set the screen before the tag is activated to avoid function
    -- connected to property::activated to be called without a valid tag.
    -- set properties cannot be used as this has to be set before the first
    -- signal is sent
    properties.screen = get_screen(properties.screen or ascreen.focused())
    -- Index is also required
    properties.index = #raw_tags(properties.screen)+1

    local newtag = capi.tag{ name = name }

    -- Start with a fresh property table to avoid collisions with unsupported data
    data.tags[newtag] = {screen=properties.screen, index=properties.index}

    newtag.activated = true

    for k, v in pairs(properties) do
        -- `rawget` doesn't work on userdata, `:clients()` is the only relevant
        -- entry.
        if k == "clients" or tag.object[k] then
            newtag[k](newtag, v)
        else
            newtag[k] = v
        end
    end

    return newtag
end

--- Create a set of tags.
-- @function atomi.tag.new
-- @param names The tag name, in a table
-- @param screen The tag screen, or 1 if not set.
-- @param layout The layout or layout table to set for this tags by default.
-- @return A table with all created tags.
function tag.new(names, layout)
    -- Put all tags at screen 1 because why not
    -- unselected tags are not visible anyway
    local screen = get_screen(1)
    local tags = {}
    for id, name in ipairs(names) do
        table.insert(tags, id, tag.add(name, {screen = screen,
                                            layout = (layout and layout[id]) or
                                                        layout}))
        -- Select the first tag.
        if id == 1 then
            tags[id].selected = true
        end
    end

    return tags
end

--- Find a suitable fallback tag.
-- @function atomi.tag.find_fallback
-- @param screen The screen to look for a tag on. [atomi.screen.focused()]
-- @param invalids A table of tags we consider unacceptable. [selectedlist(scr)]
function tag.find_fallback(screen, invalids)
    local scr = screen or ascreen.focused()
    local t = invalids or scr.selected_tags

    for _, v in pairs(scr.tags) do
        if not util.table.hasitem(t, v) then return v end
    end
end

--- Delete a tag.
--
-- To delete the current tag:
--
--    mouse.screen.selected_tag:delete()
--
-- @function tag.delete
-- @see atomi.tag.add
-- @see atomi.tag.find_fallback
-- @tparam[opt=atomi.tag.find_fallback()] tag fallback_tag Tag to assign
--  stickied tags to.
-- @tparam[opt=false] boolean force Move even non-sticky clients to the fallback
-- tag.
-- @return Returns true if the tag is successfully deleted, nil otherwise.
-- If there are no clients exclusively on this tag then delete it. Any
-- stickied clients are assigned to the optional 'fallback_tag'.
-- If after deleting the tag there is no selected tag, try and restore from
-- history or select the first tag on the screen.
function tag.object.delete(self, fallback_tag, force)

    -- abort if the taf isn't currently activated
    if not self.activated then return end

    local target_scr = get_screen(tag.getproperty(self, "screen"))
    local tags       = target_scr.tags
    local idx        = tag.object.get_index(self)
    local ntags      = #tags

    -- We can't use the target tag as a fallback.
    if fallback_tag == self then return end

    -- No fallback_tag provided, try and get one.
    if fallback_tag == nil then
        fallback_tag = tag.find_fallback(target_scr, {self})
    end

    -- Abort if we would have un-tagged clients.
    local clients = self:clients()
    if ( #clients > 0 and ntags <= 1 ) or fallback_tag == nil then return end

    -- Move the clients we can off of this tag.
    for _, c in pairs(clients) do
        local nb_tags = #c:tags()

        -- If a client has only this tag, or stickied clients with
        -- nowhere to go, abort.
        if (not c.sticky and nb_tags == 1 and not force) then
            return
        -- If a client has multiple tags, then do not move it to fallback
        elseif nb_tags < 2 then
            c:tags({fallback_tag})
        end
    end

    -- delete the tag
    data.tags[self].screen = nil
    self.activated = false

    -- Update all indexes
    for i=idx+1, #tags do
        tag.setproperty(tags[i], "index", i-1)
    end

    -- If no tags are visible, try and view one.
    if target_scr.selected_tag == nil and ntags > 0 then
        tag.history.restore(nil, 1)
        if target_scr.selected_tag == nil then
            local other_tag = tags[tags[1] == self and 2 or 1]
            if other_tag then
                other_tag.selected = true
            end
        end
    end

    return true
end

--- Delete a tag.
-- @deprecated atomi.tag.delete
-- @see tag.delete
-- @param target_tag Optional tag object to delete. [selected()]
-- @param fallback_tag Tag to assign stickied tags to. [~selected()]
-- @return Returns true if the tag is successfully deleted, nil otherwise.
-- If there are no clients exclusively on this tag then delete it. Any
-- stickied clients are assigned to the optional 'fallback_tag'.
-- If after deleting the tag there is no selected tag, try and restore from
-- history or select the first tag on the screen.
function tag.delete(target_tag, fallback_tag)
    util.deprecate("Use t:delete(fallback_tag) instead of atomi.tag.delete")

    return tag.object.delete(target_tag, fallback_tag)
end

--- Update the tag history.
-- @function atomi.tag.history.update
-- @param obj Screen object.
function tag.history.update(obj)
    local s = get_screen(obj)
    local curtags = s.selected_tags
    -- create history table
    if not data.history[s] then
        data.history[s] = {}
    else
        if data.history[s].current then
            -- Check that the list is not identical
            local identical = #data.history[s].current == #curtags
            if identical then
                for idx, _tag in ipairs(data.history[s].current) do
                    if curtags[idx] ~= _tag then
                        identical = false
                        break
                    end
                end
            end

            -- Do not update history the table are identical
            if identical then return end
        end

        -- Limit history
        if #data.history[s] >= tag.history.limit then
            for i = tag.history.limit, #data.history[s] do
                data.history[s][i] = nil
            end
        end
    end

    -- store previously selected tags in the history table
    table.insert(data.history[s], 1, data.history[s].current)
    data.history[s].previous = data.history[s][1]
    -- store currently selected tags
    data.history[s].current = setmetatable(curtags, { __mode = 'v' })
end

--- Revert tag history.
-- @function atomi.tag.history.restore
-- @param screen The screen.
-- @param idx Index in history. Defaults to "previous" which is a special index
-- toggling between last two selected sets of tags. Number (eg 1) will go back
-- to the given index in history.
function tag.history.restore(screen, idx)
    local s = get_screen(screen or ascreen.focused())
    local i = idx or "previous"
    local sel = s.selected_tags
    -- do nothing if history empty
    if not data.history[s] or not data.history[s][i] then return end
    -- if all tags been deleted, try next entry
    if #data.history[s][i] == 0 then
        if i == "previous" then i = 0 end
        tag.history.restore(s, i + 1)
        return
    end
    -- deselect all tags
    tag.viewnone(s)
    -- select tags from the history entry
    for _, t in ipairs(data.history[s][i]) do
        if t.activated and t.screen then
            t.selected = true
        end
    end
    -- update currently selected tags table
    data.history[s].current = data.history[s][i]
    -- store previously selected tags
    data.history[s].previous = setmetatable(sel, { __mode = 'v' })
    -- remove the reverted history entry
    if i ~= "previous" then table.remove(data.history[s], i) end

    s:emit_signal("tag::history::update")
end

--- Find a tag by name
-- @tparam[opt] screen s The screen of the tag
-- @tparam string name The name of the tag
-- @return The tag found, or `nil`
function tag.find_by_name(name)
    local tags = root.tags()
    for _, t in ipairs(tags) do
        if name == t.name then
            return t
        end
    end
end

--- The tag screen.
--
-- **Signal:**
--
-- * *property::screen*
--
-- @property screen
-- @param screen
-- @see screen

function tag.object.set_screen(t, s)

    s = get_screen(s or ascreen.focused())
    local sel = tag.selected
    local old_screen = get_screen(tag.getproperty(t, "screen"))

    if s == old_screen then return end

    -- Change the screen
    tag.setproperty(t, "screen", s)

    -- Make sure the client's screen matches its tags
    for _,c in ipairs(t:clients()) do
        c.screen = s --Move all clients
        c:tags({t})
    end

    -- Restore the old screen history if the tag was selected
    if sel then
        tag.history.restore(old_screen, 1)
    end
end

--- The tag master width factor.
--
-- The master width factor is one of the 5 main properties used to configure
-- the `layout`. Each layout interpret (or ignore) this property differenly.
--
-- See the layout suit documentation for information about how the master width
-- factor is used.
--
-- **Signal:**
--
-- * *property::mwfact* (deprecated)
-- * *property::master_width_factor*
--
-- @property master_width_factor
-- @param number Between 0 and 1
-- @see master_count
-- @see column_count
-- @see master_fill_policy
-- @see gap

function tag.object.set_master_width_factor(t, mwfact)
    if mwfact >= 0 and mwfact <= 1 then
        tag.setproperty(t, "mwfact", mwfact)
        tag.setproperty(t, "master_width_factor", mwfact)
    end
end

function tag.object.get_master_width_factor(t)
    return tag.getproperty(t, "master_width_factor") or 0.5
end

--- Increase master width factor.
-- @function atomi.tag.incmwfact
-- @see master_width_factor
-- @param add Value to add to master width factor.
-- @param t The tag to modify, if null tag.selected() is used.
function tag.incmwfact(add, t)
    t = t or t or ascreen.focused().selected_tag
    tag.object.set_master_width_factor(t, tag.object.get_master_width_factor(t) + add)
end

--- An ordered list of layouts.
-- `atomi.tag.layout` Is usually defined in `rc.lua`. It store the list of
-- layouts used when selecting the previous and next layouts. This is the
-- default:
--
--     -- Table of layouts to cover with atomi.layout.inc, order matters.
--     atomi.layout.layouts = {
--         atomi.layout.suit.floating,
--         atomi.layout.suit.tile,
--         atomi.layout.suit.tile.left,
--         atomi.layout.suit.tile.bottom,
--         atomi.layout.suit.tile.top,
--         atomi.layout.suit.fair,
--         atomi.layout.suit.fair.horizontal,
--         atomi.layout.suit.spiral,
--         atomi.layout.suit.spiral.dwindle,
--         atomi.layout.suit.max,
--         atomi.layout.suit.max.fullscreen,
--         atomi.layout.suit.magnifier,
--         atomi.layout.suit.corner.nw,
--         -- atomi.layout.suit.corner.ne,
--         -- atomi.layout.suit.corner.sw,
--         -- atomi.layout.suit.corner.se,
--     }
--
-- @field atomi.tag.layouts

--- The tag client layout.
--
-- This property hold the layout. A layout can be either stateless or stateful.
-- Stateless layouts are used by default by Awesome. They tile clients without
-- any other overhead. They take an ordered list of clients and place them on
-- the screen. Stateful layouts create an object instance for each tags and
-- can store variables and metadata. Because of this, they are able to change
-- over time and be serialized (saved).
--
-- Both types of layouts have valid usage scenarios.
--
-- **Stateless layouts:**
--
-- These layouts are stored in `atomi.layout.suit`. They expose a table with 2
-- fields:
--
-- * **name** (*string*): The layout name. This should be unique.
-- * **arrange** (*function*): The function called when the clients need to be
--     placed. The only parameter is a table or arguments returned by
--     `atomi.layout.parameters`
--
-- **Stateful layouts:**
--
-- The stateful layouts API is the same as stateless, but they are a function
-- returining a layout instead of a layout itself. They also should have an
-- `is_dynamic = true` property. If they don't, `atomi.tag` will create a new
-- instance everytime the layout is set. If they do, the instance will be
-- cached and re-used.
--
-- **Signal:**
--
-- * *property::layout*
--
-- @property layout
-- @see atomi.tag.layouts
-- @tparam layout|function layout A layout table or a constructor function
-- @return The layout

function tag.object.set_layout(t, layout)
    -- Check if the signature match a stateful layout
    if type(layout) == "function" or (
        type(layout) == "table"
        and getmetatable(layout)
        and getmetatable(layout).__call
    ) then
        if not data.dynamic_cache[t] then
            data.dynamic_cache[t] = {}
        end

        local instance = data.dynamic_cache[t][layout] or layout(t)

        -- Always make sure the layout is notified it is enabled
        if tag.getproperty(t, "screen").selected_tag == t and instance.wake_up then
            instance:wake_up()
        end

        -- Avoid creating the same layout twice, use layout:reset() to reset
        if instance.is_dynamic then
            data.dynamic_cache[t][layout] = instance
        end

        layout = instance
    end

    tag.setproperty(t, "layout", layout)

    return layout
end

--- The default gap.
--
-- @beautiful beautiful.useless_gap
-- @param number (default: 0)
-- @see gap

--- The gap (spacing, also called `useless_gap`) between clients.
--
-- This property allow to waste space on the screen in the name of style,
-- unicorns and readability.
--
-- **Signal:**
--
-- * *property::useless_gap*
--
-- @property gap
-- @param number The value has to be greater than zero.

function tag.object.set_gap(t, useless_gap)
    if useless_gap >= 0 then
        tag.setproperty(t, "useless_gap", useless_gap)
    end
end

function tag.object.get_gap(t)
    return tag.getproperty(t, "useless_gap") or ugly.useless_gap or 0
end

--- Increase the spacing between clients
-- @function atomi.tag.incgap
-- @see gap
-- @param add Value to add to the spacing between clients
-- @param t The tag to modify, if null tag.selected() is used.
function tag.incgap(add, t)
    t = t or t or ascreen.focused().selected_tag
    tag.object.set_gap(t, tag.object.get_gap(t) + add)
end

--- Set size fill policy for the master client(s).
--
-- **Signal:**
--
-- * *property::master_fill_policy*
--
-- @property master_fill_policy
-- @param string "expand" or "master_width_factor"

function tag.object.get_master_fill_policy(t)
    return tag.getproperty(t, "master_fill_policy") or "expand"
end

--- Toggle size fill policy for the master client(s)
-- between "expand" and "master_width_factor".
-- @function atomi.tag.togglemfpol
-- @see master_fill_policy
-- @tparam tag t The tag to modify, if null tag.selected() is used.
function tag.togglemfpol(t)
    t = t or ascreen.focused().selected_tag

    if t.master_fill_policy == "expand" then
        t.master_fill_policy = "master_width_factor"
    else
        t.master_fill_policy = "expand"
    end
end

--- Set the number of master windows.
--
-- **Signal:**
--
-- * *property::nmaster* (deprecated)
-- * *property::master_count* (deprecated)
--
-- @property master_count
-- @param integer nmaster Only positive values are accepted

function tag.object.set_master_count(t, nmaster)
    if nmaster >= 0 then
        tag.setproperty(t, "nmaster", nmaster)
        tag.setproperty(t, "master_count", nmaster)
    end
end

function tag.object.get_master_count(t)
    return tag.getproperty(t, "master_count") or 1
end

--- Increase the number of master windows.
-- @function atomi.tag.incnmaster
-- @see master_count
-- @param add Value to add to number of master windows.
-- @param[opt] t The tag to modify, if null tag.selected() is used.
-- @tparam[opt=false] boolean sensible Limit nmaster based on the number of
--   visible tiled windows?
function tag.incnmaster(add, t, sensible)
    t = t or ascreen.focused().selected_tag

    if sensible then
        local screen = get_screen(tag.getproperty(t, "screen"))
        local ntiled = #screen.tiled_clients

        local nmaster = tag.object.get_master_count(t)
        if nmaster > ntiled then
            nmaster = ntiled
        end

        local newnmaster = nmaster + add
        if newnmaster > ntiled then
            newnmaster = ntiled
        end
        tag.object.set_master_count(t, newnmaster)
    else
        tag.object.set_master_count(t, tag.object.get_master_count(t) + add)
    end
end

--- Set the number of columns.
--
-- **Signal:**
--
-- * *property::ncol* (deprecated)
-- * *property::column_count*
--
-- @property column_count
-- @tparam integer ncol Has to be greater than 1

function tag.object.set_column_count(t, ncol)
    if ncol >= 1 then
        tag.setproperty(t, "ncol", ncol)
        tag.setproperty(t, "column_count", ncol)
    end
end

function tag.object.get_column_count(t)
    return tag.getproperty(t, "column_count") or 1
end

--- Increase number of column windows.
-- @function atomi.tag.incncol
-- @param add Value to add to number of column windows.
-- @param[opt] t The tag to modify, if null tag.selected() is used.
-- @tparam[opt=false] boolean sensible Limit column_count based on the number of visible
-- tiled windows?
function tag.incncol(add, t, sensible)
    t = t or ascreen.focused().selected_tag

    if sensible then
        local screen = get_screen(tag.getproperty(t, "screen"))
        local ntiled = #screen.tiled_clients
        local nmaster = tag.object.get_master_count(t)
        local nsecondary = ntiled - nmaster

        local ncol = tag.object.get_column_count(t)
        if ncol > nsecondary then
            ncol = nsecondary
        end

        local newncol = ncol + add
        if newncol > nsecondary then
            newncol = nsecondary
        end

        tag.object.set_column_count(t, newncol)
    else
        tag.object.set_column_count(t, tag.object.get_column_count(t) + add)
    end
end

--- View no tag.
-- @function atomi.tag.viewnone
-- @tparam[opt] int|screen screen The screen.
function tag.viewnone(screen)
    screen = screen or ascreen.focused()
    local tags = screen.tags
    for _, t in pairs(tags) do
        t.selected = false
    end
end

--- View a tag by its taglist index.
--
-- This is equivalent to `screen.tags[i]:view_only()`
-- @function atomi.tag.viewidx
-- @see screen.tags
-- @param i The **relative** index to see.
-- @param[opt] screen The screen.
function tag.viewidx(i, screen)
    screen = get_screen(screen or ascreen.focused())
    local tags = screen.tags
    local showntags = {}
    for _, t in ipairs(tags) do
        if not tag.getproperty(t, "hide") then
            table.insert(showntags, t)
        end
    end
    local sel = screen.selected_tag
    tag.viewnone(screen)
    for k, t in ipairs(showntags) do
        if t == sel then
            showntags[util.cycle(#showntags, k + i)].selected = true
        end
    end
    screen:emit_signal("tag::history::update")
end

--- View next tag. This is the same as tag.viewidx(1).
-- @function atomi.tag.viewnext
-- @param screen The screen.
function tag.viewnext(screen)
    return tag.viewidx(1, screen)
end

--- View previous tag. This is the same a tag.viewidx(-1).
-- @function atomi.tag.viewprev
-- @param screen The screen.
function tag.viewprev(screen)
    return tag.viewidx(-1, screen)
end

--- View only a tag.
-- @function tag.view_only
-- @see selected
function tag.object.view_only(self, screen)
    screen = get_screen(screen or ascreen.focused())
    local tags = screen.selected_tags
    -- First, untag everyone except the viewed tag
    for _, _tag in pairs(tags) do
        if _tag ~= self then
            _tag.selected = false
        end
    end

    -- Am I selected on another screen?
    if self.screen ~= screen then
        self.selected = false
        self.screen = screen
    end
    -- Then, set this one to selected.
    -- We need to do that in 2 operations so we avoid flickering and several tag
    -- selected at the same time.
    self.selected = true
    capi.screen[screen]:emit_signal("tag::history::update")
end

--- View only a set of tags.
-- @function atomi.tag.viewmore
-- @param tags A table with tags to view only.
-- @param[opt] screen The screen of the tags.
function tag.viewmore(tags, s)
    s = get_screen(s or ascreen.focused())
    local stags = s.selected_tags
    for _, _tag in ipairs(stags) do
        if not util.table.hasitem(tags, _tag) then
            _tag.selected = false
        end
    end
    for _, _tag in ipairs(tags) do
        if _tag.screen ~= s then
            _tag.screen = s
        end
        _tag.selected = true
    end
    s:emit_signal("tag::history::update")
end

--- Toggle selection of a tag
-- @function tag.view_toggle
-- @see selected
-- @tparam tag t Tag to be toggled
function tag.object.view_toggle(self, screen)
    screen = get_screen(screen or ascreen.focused())
    if self.screen ~= screen then
        self.screen = screen
        self.selected = true
    else
        self.selected = not self.selected
    end

    capi.screen[tag.getproperty(self, "screen")]:emit_signal("tag::history::update")
end

--- Get tag data table.
--
-- Do not use.
--
-- @deprecated atomi.tag.getdata
-- @tparam tag _tag The tag.
-- @return The data table.
function tag.getdata(_tag)
    return data.tags[_tag]
end

--- Get a tag property.
--
-- Use `_tag.prop` directly.
--
-- @deprecated atomi.tag.getproperty
-- @tparam tag _tag The tag.
-- @tparam string prop The property name.
-- @return The property.
function tag.getproperty(_tag, prop)
    if data.tags[_tag] then
        return data.tags[_tag][prop]
    end
end

--- Set a tag property.
-- This properties are internal to atomi. Some are used to draw taglist, or to
-- handle layout, etc.
--
-- Use `_tag.prop = value`
--
-- @deprecated atomi.tag.setproperty
-- @param _tag The tag.
-- @param prop The property name.
-- @param value The value.
function tag.setproperty(_tag, prop, value)
    if not data.tags[_tag] then
        data.tags[_tag] = {}
    end

    if data.tags[_tag][prop] ~= value then
        data.tags[_tag][prop] = value
        _tag:emit_signal("property::" .. prop)
    end
end

local function attached_connect_signal_screen(screen, sig, func)
    screen = get_screen(screen)
    capi.tag.connect_signal(sig, function(_tag)
        if get_screen(tag.getproperty(_tag, "screen")) == screen then
            func(_tag)
        end
    end)
end

--- Add a signal to all attached tags and all tags that will be attached in the
-- future. When a tag is detached from the screen, its signal is removed.
--
-- @function atomi.tag.attached_connect_signal
-- @param screen The screen concerned, or all if nil.
function tag.attached_connect_signal(screen, ...)
    if screen then
        attached_connect_signal_screen(screen, ...)
    else
        capi.tag.connect_signal(...)
    end
end

-- Register standard signals.
capi.client.connect_signal("manage", function(c)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for "normal" windows (i.e. no dock, etc).
    if not awesome.startup and c.type ~= "desktop" and c.type ~= "dock" then
        if c.transient_for then
            c.screen = c.transient_for.screen
            if not c.sticky then
                c:tags(c.transient_for:tags())
            end
        else
            c.screen = ascreen.focused()
        end
    end
    c:connect_signal("property::screen", function() c:to_selected_tags() end)
end)

-- Keep track of the number of urgent clients.
local function update_urgent(t, modif)
    local count = tag.getproperty(t, "urgent_count") or 0
    count = (count + modif) >= 0 and (count + modif) or 0
    tag.setproperty(t, "urgent"      , count > 0)
    tag.setproperty(t, "urgent_count", count    )
end

-- Update the urgent counter when a client is tagged.
local function client_tagged(c, t)
    if c.urgent then
        update_urgent(t, 1)
    end
end

-- Update the urgent counter when a client is untagged.
local function client_untagged(c, t)
    if c.urgent then
        update_urgent(t, -1)
    end

    if #t:clients() == 0 and tag.getproperty(t, "volatile") then
        tag.object.delete(t)
    end
end

-- Count the urgent clients.
local function urgent_callback(c)
    for _,t in ipairs(c:tags()) do
        update_urgent(t, c.urgent and 1 or -1)
    end
end

capi.client.connect_signal("property::urgent", urgent_callback)
capi.client.connect_signal("untagged", client_untagged)
capi.client.connect_signal("tagged", client_tagged)
capi.tag.connect_signal("request::select", tag.object.view_only)

--- True when a tagged client is urgent
-- @signal property::urgent
-- @see client.urgent

--- The number of urgent tagged clients
-- @signal property::urgent_count
-- @see client.urgent

capi.screen.connect_signal("tag::history::update", tag.history.update)

capi.screen.connect_signal("removed", function(s)
    -- Move all tags to screen 1
    for _, t in pairs(root.tags()) do
        if t.screen == s then
            t.selected = false
            t.screen = get_screen(1)
        end
    end
end)

function tag.mt:__call(...)
    return tag.new(...)
end

-- Extend the luaobject
-- `atomi.tag.setproperty` currently handle calling the setter method itself
-- while `atomi.tag.getproperty`.
object.properties(capi.tag, {
    getter_class    = tag.object,
    setter_class    = tag.object,
    getter_fallback = tag.getproperty,
    setter_fallback = tag.setproperty,
})

return setmetatable(tag, tag.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
