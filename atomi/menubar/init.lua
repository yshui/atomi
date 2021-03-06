---------------------------------------------------------------------------
--- Menubar module, which aims to provide a freedesktop menu alternative
--
-- List of menubar keybindings:
-- ---
--
--  *  "Left"  | "C-j" select an item on the left
--  *  "Right" | "C-k" select an item on the right
--  *  "Backspace"     exit the current category if we are in any
--  *  "Escape"        exit the current directory or exit menubar
--  *  "Home"          select the first item
--  *  "End"           select the last
--  *  "Return"        execute the entry
--  *  "C-Return"      execute the command with atomi.spawn
--  *  "C-M-Return"    execute the command in a terminal
--
-- @author Alexander Yakushev &lt;yakushev.alex@gmail.com&gt;
-- @copyright 2011-2012 Alexander Yakushev
-- @release v3.5.2-1890-ge472339
-- @module menubar
---------------------------------------------------------------------------

-- Grab environment we need
local capi = {
    client = client,
    mouse = mouse,
    screen = screen
}
local autil = require("atomi.util")
local awidget = require("atomi.widget")
local ascreen = require("atomi.screen")
local spawn = require("atomi.spawn")
local aprompt = require("atomi.prompt")
local acompletion = require("atomi.completion")
local common = require("atomi.widget.common")
local theme = require("ugly")
local wibox = require("atomi.proton")
local adpi = require("ugly").x.apply_dpi

local function get_screen(s)
    return s and capi.screen[s]
end

-- menubar
local menubar = { mt = {}, menu_entries = {} }
menubar.menu_gen = require("atomi.menubar.menu_gen")
menubar.utils = require("atomi.menubar.utils")
local compute_text_width = menubar.utils.compute_text_width

-- Options section

--- When true the .desktop files will be reparsed only when the
-- extension is initialized. Use this if menubar takes much time to
-- open.
menubar.cache_entries = true

--- When true the categories will be shown alongside application
-- entries.
menubar.show_categories = true

--- Specifies the geometry of the menubar. This is a table with the keys
-- x, y, width and height. Missing values are replaced via the screen's
-- geometry. However, missing height is replaced by the font size.
menubar.geometry = { width = nil,
                     height = nil,
                     x = nil,
                     y = nil }
--- Width of blank space left in the right side.
menubar.right_margin = theme.x.apply_dpi(8)

--- Label used for "Next page", default "▶▶".
menubar.right_label = "▶▶"

--- Label used for "Previous page", default "◀◀".
menubar.left_label = "◀◀"

-- awidget.common.list_update adds three times a margin of dpi(4)
-- for each item:
local list_interspace = theme.x.apply_dpi(4) * 3

--- Allows user to specify custom parameters for prompt.run function
-- (like colors).
menubar.prompt_args = {}

-- Private section
local current_item = 1
local previous_item = nil
local current_category = nil
local shownitems = nil
local instance = { prompt = nil,
                   widget = nil,
                   wibox = nil }

local common_args = { w = wibox.layout.fixed.horizontal(),
                      data = setmetatable({}, { __mode = 'kv' }) }

--- Wrap the text with the color span tag.
-- @param s The text.
-- @param c The desired text color.
-- @return the text wrapped in a span tag.
local function colortext(s, c)
    return "<span color='" .. autil.ensure_pango_color(c) .. "'>" .. s .. "</span>"
end

--- Get how the menu item should be displayed.
-- @param o The menu item.
-- @return item name, item background color, background image, item icon.
local function label(o)
    if o.focused then
        return colortext(o.name, (theme.menu_fg_focus or theme.fg_focus)), (theme.menu_bg_focus or theme.bg_focus), nil, o.icon
    else
        return o.name, (theme.menu_bg_normal or theme.bg_normal), nil, o.icon
    end
end

local function load_count_table()
    local count_file_name = autil.getdir("cache") .. "/menu_count_file"

    local count_file = io.open (count_file_name, "r")
    local count_table = {}

    -- read count file
    if count_file then
        io.input (count_file)
        for line in io.lines() do
            local name, count = string.match(line, "([^;]+);([^;]+)")
            if name ~= nil and count ~= nil then
                count_table[name] = count
            end
        end
    end

    return count_table
end

local function write_count_table(count_table)
    local count_file_name = autil.getdir("cache") .. "/menu_count_file"

    local count_file = io.open (count_file_name, "w")

    if count_file then
        io.output (count_file)

        for name,count in pairs(count_table) do
            local str = string.format("%s;%d\n", name, count)
            io.write(str)
        end
        io.flush()
    end
end

--- Perform an action for the given menu item.
-- @param o The menu item.
-- @return if the function processed the callback, new atomi.prompt command, new atomi.prompt prompt text.
local function perform_action(o)
    if not o then return end
    if o.key then
        current_category = o.key
        local new_prompt = shownitems[current_item].name .. ": "
        previous_item = current_item
        current_item = 1
        return true, "", new_prompt
    elseif shownitems[current_item].cmdline then
        spawn(shownitems[current_item].cmdline)

        -- load count_table from cache file
        local count_table = load_count_table()

        -- increase count
        local curname = shownitems[current_item].name
        if count_table[curname] ~= nil then
            count_table[curname] = count_table[curname] + 1
        else
            count_table[curname] = 1
        end

        -- write updated count table to cache file
        write_count_table(count_table)

        -- Let atomi.prompt execute dummy exec_callback and
        -- done_callback to stop the keygrabber properly.
        return false
    end
end

-- Cut item list to return only current page.
-- @tparam table all_items All items list.
-- @tparam str query Search query.
-- @tparam number|screen scr Screen
-- @return table List of items for current page.
local function get_current_page(all_items, query, scr)
    scr = get_screen(scr)
    if not instance.prompt.width then
        instance.prompt.width = compute_text_width(instance.prompt.prompt, scr)
    end
    if not menubar.left_label_width then
        menubar.left_label_width = compute_text_width(menubar.left_label, scr)
    end
    if not menubar.right_label_width then
        menubar.right_label_width = compute_text_width(menubar.right_label, scr)
    end
    local available_space = instance.geometry.width - adpi(8, scr) -
        menubar.right_label_width - menubar.left_label_width -
        compute_text_width(query, scr) - instance.prompt.width

    local width_sum = 0
    local current_page = {}
    for i, item in ipairs(all_items) do
        item.width = item.width or
            compute_text_width(item.name, scr) +
            (item.icon and instance.geometry.height or 0) + adpi(4, scr)*3
        if width_sum + item.width > available_space then
            if current_item < i then
                table.insert(current_page, { name = menubar.right_label, icon = nil })
                break
            end
            current_page = { { name = menubar.left_label, icon = nil }, item, }
            width_sum = item.width
        else
            table.insert(current_page, item)
            width_sum = width_sum + item.width
        end
    end
    return current_page
end

--- Update the menubar according to the command entered by user.
-- @tparam str query Search query.
-- @tparam number|screen scr Screen
local function menulist_update(query, scr)
    query = query or ""
    shownitems = {}
    local pattern = autil.query_to_pattern(query)
    local match_inside = {}

    -- First we add entries which names match the command from the
    -- beginning to the table shownitems, and the ones that contain
    -- command in the middle to the table match_inside.

    -- Add the categories
    if menubar.show_categories then
        for _, v in pairs(menubar.menu_gen.all_categories) do
            v.focused = false
            if not current_category and v.use then
                if string.match(v.name, pattern) then
                    if string.match(v.name, "^" .. pattern) then
                        table.insert(shownitems, v)
                    else
                        table.insert(match_inside, v)
                    end
                end
            end
        end
    end

    local count_table = load_count_table()
    local command_list = {}

    -- Add the applications according to their name and cmdline
    for _, v in ipairs(menubar.menu_entries) do
        v.focused = false
        if not current_category or v.category == current_category then
            if string.match(v.name, pattern)
                or string.match(v.cmdline, pattern) then
                if string.match(v.name, "^" .. pattern)
                    or string.match(v.cmdline, "^" .. pattern) then

                    v.count = 0
                    -- use count from count_table if present
                    if string.len(pattern) > 0 and count_table[v.name] ~= nil then
                        v.count = tonumber(count_table[v.name])
                    end

                    table.insert (command_list, v)
                end
            end
        end
    end

    local function compare_counts(a,b)
        return a.count > b.count
    end

    -- sort command_list by count (highest first)
    table.sort(command_list, compare_counts)
    -- copy into showitems
    shownitems = command_list

    if #shownitems > 0 then
        -- Insert a run item value as the last choice
        table.insert(shownitems, { name = "Exec: " .. query, cmdline = query, icon = nil })

        if current_item > #shownitems then
            current_item = #shownitems
        end
        shownitems[current_item].focused = true
    else
        table.insert(shownitems, { name = "", cmdline = query, icon = nil })
    end

    common.list_update(common_args.w, theme.get_font(nil, scr), theme.x.get_dpi(scr),
                       nil, label, common_args.data,
                       get_current_page(shownitems, query, scr))
end

--- Create the menubar wibox and widgets.
-- @tparam[opt] screen scr Screen.
local function initialize(scr)
    instance.wibox = wibox({})
    instance.widget = menubar.get(scr)
    instance.wibox.ontop = true
    instance.prompt = awidget.prompt()
    local layout = wibox.layout.fixed.horizontal()
    layout:add(instance.prompt)
    layout:add(instance.widget)
    instance.wibox:set_widget(layout)
end

--- Refresh menubar's cache by reloading .desktop files.
-- @tparam[opt] screen scr Screen.
function menubar.refresh(scr)
    menubar.menu_gen.generate(function(entries)
        menubar.menu_entries = entries
        menulist_update(nil, scr)
    end)
end

--- Awful.prompt keypressed callback to be used when the user presses a key.
-- @param mod Table of key combination modifiers (Control, Shift).
-- @param key The key that was pressed.
-- @param comm The current command in the prompt.
-- @return if the function processed the callback, new atomi.prompt command, new atomi.prompt prompt text.
local function prompt_keypressed_callback(mod, key, comm)
    if key == "Left" or (mod.Control and key == "j") then
        current_item = math.max(current_item - 1, 1)
        return true
    elseif key == "Right" or (mod.Control and key == "k") then
        current_item = current_item + 1
        return true
    elseif key == "BackSpace" then
        if comm == "" and current_category then
            current_category = nil
            current_item = previous_item
            return true, nil, "Run: "
        end
    elseif key == "Escape" then
        if current_category then
            current_category = nil
            current_item = previous_item
            return true, nil, "Run: "
        end
    elseif key == "Home" then
        current_item = 1
        return true
    elseif key == "End" then
        current_item = #shownitems
        return true
    elseif key == "Return" or key == "KP_Enter" then
        if mod.Control then
            current_item = #shownitems
            if mod.Mod1 then
                -- add a terminal to the cmdline
                shownitems[current_item].cmdline = menubar.utils.terminal
                        .. " -e " .. shownitems[current_item].cmdline
            end
        end
        return perform_action(shownitems[current_item])
    end
    return false
end

--- Show the menubar on the given screen.
-- @param scr Screen.
function menubar.show(scr)
    if not instance.wibox then
        initialize(scr)
    elseif instance.wibox.visible then -- Menu already shown, exit
        return
    elseif not menubar.cache_entries then
        menubar.refresh(scr)
    end

    -- Set position and size
    scr = scr or ascreen.focused() or 1
    scr = get_screen(scr)
    local scrgeom = capi.screen[scr].workarea
    local geometry = menubar.geometry
    instance.geometry = {x = geometry.x or scrgeom.x,
                             y = geometry.y or scrgeom.y,
                             height = geometry.height or autil.round(theme.get_font_height() * 1.5),
                             width = geometry.width or scrgeom.width}
    instance.wibox:geometry(instance.geometry)

    current_item = 1
    current_category = nil
    menulist_update(nil, scr)

    local prompt_args = menubar.prompt_args or {}
    prompt_args.prompt = "Run: "
    aprompt.run(prompt_args, instance.prompt.widget,
                function() end,            -- exe_callback function set to do nothing
                acompletion.shell,     -- completion_callback
                autil.get_cache_dir() .. "/history_menu",
                nil,
                menubar.hide, function(query) menulist_update(query, scr) end,
                prompt_keypressed_callback
                )
    instance.wibox.visible = true
end

--- Hide the menubar.
function menubar.hide()
    instance.wibox.visible = false
end

--- Get a menubar wibox.
-- @tparam[opt] screen scr Screen.
-- @return menubar wibox.
function menubar.get(scr)
    menubar.refresh(scr)
    -- Add to each category the name of its key in all_categories
    for k, v in pairs(menubar.menu_gen.all_categories) do
        v.key = k
    end
    return common_args.w
end

function menubar.mt.__call(_, ...)
    return menubar.get(...)
end

return setmetatable(menubar, menubar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
