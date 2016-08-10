local layout = require("atomi.proton.layout")
local widgets = require("atomi.proton.widget")
local battery = { mt = {} }
local timer = require("gears.timer")
local ugly = require("ugly")

local ps_path = "/sys/class/power_supply/"
local function update_battery(tb, pb, name)
    local f = io.open(ps_path..name.."/energy_full")
    local full = tonumber(f:read("*all"))

    f = io.open(ps_path..name.."/energy_now")
    local now = tonumber(f:read("*all"))

    local cent = now / full

    f = io.open(ps_path..name.."/status")
    local status = f:read("*line")
    print(status)

    local color = ugly.fg_normal
    if status == "Discharging" then
        color = "#ff2000"
    elseif status == "Charging" then
        color = "#f0c020"
    elseif stauts == "Unknown" or status == "Charged" then
        color = "#20f020"
    end

    pb:set_color(color)

    tb:set_markup("<span color=\"#ffffff\">"..tostring(math.floor(cent*100)).."%</span>")
    pb:set_value(cent)
end
function battery.new(s, name)
    s = s and screen[s]
    name = name or "BAT0"

    local w = layout.stack()
    local tb = widgets.textbox(ugly.get_font(nil, s))
    local pb = widgets.progressbar({ border_color =  ugly.progressbar_border_color or "#ffffff",
                                     background_color = ugly.bg_normal,
                                     color = ugly.fg_normal,
                                     width = 20
                                   })

    pb:set_vertical(true)
    w:add(pb, tb)

    update_battery(tb, pb, name)

    local t = timer.start_new(5, function()
        update_battery(tb, pb, name)
        return true
    end)

    return w
end

function battery.mt:__call(...)
    return battery.new(...)
end

return setmetatable(battery, battery.mt)
