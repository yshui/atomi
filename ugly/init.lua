----------------------------------------------------------------------------
--- Theme library.
--
-- @author Damien Leone &lt;damien.leone@gmail.com&gt;
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Damien Leone, Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @module ugly
----------------------------------------------------------------------------

-- Grab environment
local os = os
local pairs = pairs
local type = type
local dofile = dofile
local setmetatable = setmetatable
local lgi = require("lgi")
local Pango = lgi.Pango
local PangoCairo = lgi.PangoCairo
local gears_debug = require("gears.debug")
local protected_call = require("gears.protected_call")

local x_ = require("ugly.x")

local ugly = { x = x_, mt = {} }

-- Local data
local theme = {}
local descs = setmetatable({}, { __mode = 'k' })
local fonts = {} --setmetatable({}, { __mode = 'v' })

-- global_fonts: when load font without a screen
local global_fonts = setmetatable({}, { __mode = 'v' })
local active_font = {}
local global_active_font

local function get_screen(s)
    return s and screen[s]
end

--- Load a font from a string or a font description.
--
-- @see https://developer.gnome.org/pango/stable/pango-Fonts.html#pango-font-description-from-string
-- @tparam string|lgi.Pango.FontDescription name Font, which can be a
--   string or a lgi.Pango.FontDescription.
-- @tparam[opt] integer|screen The screen this font is going to be displayed
-- @treturn table A table with `name`, `description` and `height`.
local function load_font(name, s)
    name = name or ((s and active_font[s]) or global_active_font)
    if name and type(name) ~= "string" then
        if descs[name] then
            name = descs[name]
        else
            name = name:to_string()
        end
    end

    if s == nil then
        if global_fonts[name] ~= nil then
            return global_fonts[name]
        end
    else
        if fonts[s] == nil then
            fonts[s] = setmetatable({}, { __mode = 'v' })
        end
        if fonts[s][name] ~= nill then
            return fonts[s][name]
        end
    end

    -- Load new font
    local desc = Pango.FontDescription.from_string(name)
    local ctx = PangoCairo.font_map_get_default():create_context()
    ctx:set_resolution(ugly.x.get_dpi(s))

    -- Apply default values from the context (e.g. a default font size)
    desc:merge(ctx:get_font_description(), false)

    -- Calculate font height.
    local metrics = ctx:get_metrics(desc, nil)
    local height = math.ceil((metrics:get_ascent() + metrics:get_descent()) / Pango.SCALE)

    local font = { name = name, description = desc, height = height }
    if s ~= nil then
        fonts[s][name] = font
    else
        global_fonts[name] = font
    end
    descs[desc] = name
    return font
end

--- Set an active font
--
-- @param name The font
local function set_font(name, s)
    if s ~= nil then
        active_font[s] = load_font(name, s).name
    else
        global_active_font = load_font(name).name
    end
end

--- Get a font description.
--
-- See https://developer.gnome.org/pango/stable/pango-Fonts.html#PangoFontDescription.
-- @tparam string|lgi.Pango.FontDescription name The name of the font.
-- @treturn lgi.Pango.FontDescription
function ugly.get_font(name, s)
    return load_font(name, s).description
end

--- Get a new font with merged attributes, based on another one.
--
-- See https://developer.gnome.org/pango/stable/pango-Fonts.html#pango-font-description-from-string.
-- @tparam string|Pango.FontDescription name The base font.
-- @tparam string merge Attributes that should be merged, e.g. "bold".
-- @treturn lgi.Pango.FontDescription
function ugly.get_merged_font(name, merge)
    local font = ugly.get_font(name)
    merge = Pango.FontDescription.from_string(merge)
    local merged = font:copy_static()
    merged:merge(merge, true)
    return ugly.get_font(merged:to_string())
end

--- Get the height of a font.
--
-- @tparam string name Name of the font
-- @tparam integer|screen The screen
function ugly.get_font_height(name, s)
    return load_font(name, s).height
end

--- Init function, should be runned at the beginning of configuration file.
-- @tparam string|table config The theme to load. It can be either the path to
--   the theme file (returning a table) or directly the table
--   containing all the theme values.
function ugly.init(config)
    if config then
        local homedir = os.getenv("HOME")

        -- If `config` is the path to a theme file, run this file,
        -- otherwise if it is a theme table, save it.
        if type(config) == 'string' then
            -- Expand the '~' $HOME shortcut
            config = config:gsub("^~/", homedir .. "/")
            theme = protected_call(dofile, config)
        elseif type(config) == 'table' then
            theme = config
        end

        if theme then
            -- expand '~'
            if homedir then
                for k, v in pairs(theme) do
                    if type(v) == "string" then theme[k] = v:gsub("^~/", homedir .. "/") end
                end
            end

            if theme.font then set_font(theme.font) end
        else
            return gears_debug.print_error("ugly: error loading theme file " .. config)
        end
    else
        return gears_debug.print_error("ugly: error loading theme: no theme specified")
    end
end

--- Get the current theme.
--
-- @treturn table The current theme table.
function ugly.get()
    return theme
end

function ugly.mt:__index(k)
    return theme[k]
end

-- Set the default font
set_font("sans 8")

return setmetatable(ugly, ugly.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
