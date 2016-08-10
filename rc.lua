-- Standard awesome library
local config_root = os.getenv("HOME").."/.config/awesome/"
local logf = io.open(config_root.."awesome.log", "a")
logf:write("\n\n")
print = function(...)
	logf:write(os.date("[%c] "))
	logf:write(table.concat({...}, " "))
	logf:write("\n")
	logf:flush()
end

print("Awesome loading rc.lua...")
local awallpaper = require("atomi.wallpaper")
local atomi = require("atomi")
require("atomi.autofocus")
-- Widget and layout library
local proton = require("atomi.proton")
-- Theme handling library
local ugly = require("ugly")
-- Notification library
local photon = require("atomi.photon")
local menubar = atomi.menubar
local hotkeys_popup = require("atomi.hotkeys_popup").widget

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    photon.notify({ preset = photon.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        photon.notify({ preset = photon.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
ugly.init(config_root.."theme.lua")

-- This is used later as the default terminal and editor to run.
term_emu = "urxvt"
terminal = term_emu.." -e tmux"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = term_emu.." -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with atomi.layout.inc, order matters.
atomi.layout.layouts = {
    atomi.layout.suit.max,
    atomi.layout.suit.floating,
    atomi.layout.suit.tile,
    atomi.layout.suit.tile.left,
    atomi.layout.suit.tile.bottom,
    atomi.layout.suit.tile.top,
    atomi.layout.suit.fair,
    atomi.layout.suit.fair.horizontal,
    atomi.layout.suit.spiral,
    atomi.layout.suit.spiral.dwindle,
    atomi.layout.suit.max.fullscreen,
    atomi.layout.suit.magnifier,
    atomi.layout.suit.corner.nw,
    -- atomi.layout.suit.corner.ne,
    -- atomi.layout.suit.corner.sw,
    -- atomi.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = atomi.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", term_emu .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = atomi.menu({ items = { { "awesome", myawesomemenu, ugly.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = atomi.widget.launcher({ image = ugly.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = term_emu -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = atomi.widget.keyboardlayout()

-- {{{ Wibox

-- Create a wibox for each screen and add it
mywibar = {}
mypromptbox = {}
mylayoutbox = {}
mytextclock = {}
mytaglist = {}
mytaglist.buttons = atomi.util.table.join(
                    atomi.button({ }, 1, function(t) t:view_only() end),
                    atomi.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    atomi.button({ }, 3, function(t) t:view_toggle() end),
                    atomi.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    atomi.button({ }, 4, function(t) atomi.tag.viewnext(t.screen) end),
                    atomi.button({ }, 5, function(t) atomi.tag.viewprev(t.screen) end)
                )

mytasklist = {}
mytasklist.buttons = atomi.util.table.join(
                     atomi.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     atomi.button({ }, 3, client_menu_toggle_fn()),
                     atomi.button({ }, 4, function ()
                                              atomi.client.focus.byidx(1)
                                          end),
                     atomi.button({ }, 5, function ()
                                              atomi.client.focus.byidx(-1)
                                          end))

-- Create the tag table.
atomi.tag({ "1", "2", "3", "4" }, atomi.layout.layouts[1])
atomi.screen.connect_for_each_screen(function(s)
    local swidth = 0
    local sheight = 0
    for k, v in pairs(s.outputs) do
        -- Estimate screen dimension, probably
        -- won't work for screen with mulitple outputs
        swidth = swidth+v.mm_width
        sheight = sheight+v.mm_height
        print("Outputs: "..k)
    end

    -- Calculate DPI
    local hori_dpi = s.geometry.width/(swidth*0.04)
    local vert_dpi = s.geometry.height/(sheight*0.04)

    local dpi = (hori_dpi+vert_dpi)/2

    print("Raw DPI: "..dpi)

    -- Round to a mulitple of 96, some applications might
    -- not handle fractional scale factor (e.g. gtk)
    dpi = math.floor(dpi)
    print("Set DPI: "..dpi)

    ugly.x.set_dpi(dpi, s)

    -- Wallpaper
    if ugly.wallpaper then
        local wallpaper = ugly.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        awallpaper.maximized(wallpaper, s, true)
    end

    -- Create a textclock widget
    mytextclock[s] = atomi.widget.textclock(s)
    -- Create a promptbox for each screen
    mypromptbox[s] = atomi.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = atomi.widget.layoutbox(s)
    mylayoutbox[s]:buttons(atomi.util.table.join(
                           atomi.button({ }, 1, function () atomi.layout.inc( 1) end),
                           atomi.button({ }, 3, function () atomi.layout.inc(-1) end),
                           atomi.button({ }, 4, function () atomi.layout.inc( 1) end),
                           atomi.button({ }, 5, function () atomi.layout.inc(-1) end)))
    -- Create a taglist widget
    mytaglist[s] = atomi.widget.taglist(s, atomi.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = atomi.widget.tasklist(s, atomi.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibar
    mywibar[s] = atomi.wibar({ position = "top", screen = s })

    -- Add widgets to the wibar
    mywibar[s]:setup {
        layout = proton.layout.align.horizontal,
        { -- Left widgets
            layout = proton.layout.fixed.horizontal,
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
        },
        mytasklist[s], -- Middle widget
        { -- Right widgets
            layout = proton.layout.fixed.horizontal,
            mykeyboardlayout,
            atomi.widget.systray(),
            mytextclock[s],
            atomi.widget.battery(s, "BAT0"),
            mylayoutbox[s],
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(atomi.util.table.join(
    atomi.button({ }, 3, function () mymainmenu:toggle() end),
    atomi.button({ }, 4, atomi.tag.viewnext),
    atomi.button({ }, 5, atomi.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = atomi.util.table.join(
    atomi.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    atomi.key({ modkey,           }, "Left",   atomi.tag.viewprev,
              {description = "view previous", group = "tag"}),
    atomi.key({ modkey,           }, "Right",  atomi.tag.viewnext,
              {description = "view next", group = "tag"}),
    atomi.key({ modkey,           }, "Escape", atomi.tag.history.restore,
              {description = "go back", group = "tag"}),
    atomi.key({ modkey,           }, "d", function() atomi.spawn("rofi -show run") end),

    atomi.key({ modkey,           }, "j",
        function ()
            atomi.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    atomi.key({ modkey,           }, "k",
        function ()
            atomi.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    atomi.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    atomi.key({ modkey, "Shift"   }, "j", function () atomi.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    atomi.key({ modkey, "Shift"   }, "k", function () atomi.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    atomi.key({ modkey, "Control" }, "j", function () atomi.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    atomi.key({ modkey, "Control" }, "k", function () atomi.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    atomi.key({ modkey,           }, "u", atomi.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    atomi.key({ modkey,           }, "Tab",
        function ()
            atomi.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    atomi.key({ modkey,           }, "Return", function () atomi.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    atomi.key({ modkey, "Shift"   }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    atomi.key({ modkey, "Shift"   }, "e", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    atomi.key({ modkey,           }, "l",     function () atomi.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    atomi.key({ modkey,           }, "h",     function () atomi.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    atomi.key({ modkey, "Shift"   }, "h",     function () atomi.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    atomi.key({ modkey, "Shift"   }, "l",     function () atomi.tag.incnmaster(-1, nil, true) end,
              screen{description = "decrease the number of master clients", group = "layout"}),
    atomi.key({ modkey, "Control" }, "h",     function () atomi.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    atomi.key({ modkey, "Control" }, "l",     function () atomi.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    --atomi.key({ modkey,           }, "space", function () atomi.layout.inc( 1)                end,
    --          {description = "select next", group = "layout"}),
    --atomi.key({ modkey, "Shift"   }, "space", function () atomi.layout.inc(-1)                end,
    --          {description = "select previous", group = "layout"}),

    atomi.key({ modkey, "Control" }, "n",
              function ()
                  local c = atomi.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    atomi.key({ modkey },            "r",     function () mypromptbox[atomi.screen.focused()]:run() end,
              {description = "run prompt", group = "launcher"}),

    atomi.key({ modkey }, "x",
              function ()
                  atomi.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[atomi.screen.focused()].widget,
                  atomi.util.eval, nil,
                  atomi.util.get_cache_dir() .. "/history_eval")
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    atomi.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = atomi.util.table.join(
    atomi.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    atomi.key({ modkey, "Shift"   }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    atomi.key({ modkey, "Shift"   }, "space",  atomi.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    atomi.key({ modkey, "Control" }, "Return", function (c) c:swap(atomi.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    atomi.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    atomi.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    atomi.key({ modkey,           }, "m",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    atomi.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = atomi.util.table.join(globalkeys,
        -- View tag only.
        atomi.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = atomi.screen.focused()
                        local tag = root.tags()[i]
                        if tag then
                           tag:view_only(screen)
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag.
        atomi.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = atomi.screen.focused()
                      local tag = root.tags()[i]
                      if tag then
                         tag:view_toggle(screen)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        atomi.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = root.tags()[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        atomi.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = root.tags()[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = atomi.util.table.join(
    atomi.button({ }, 1, function (c) client.focus = c; c:raise() end),
    atomi.button({ modkey }, 1, atomi.mouse.client.move),
    atomi.button({ modkey }, 3, atomi.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
atomi.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = ugly.border_width,
                     border_color = ugly.border_normal,
                     focus = atomi.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     placement = atomi.placement.no_overlap+atomi.placement.no_offscreen,
                     titlebars_enabled = false
     }
    },
    { rule = { class = "URxvt" },
      properties = { size_hints_honor = false } },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    --{ rule_any = {type = { "normal", "dialog" }
    --  }, properties = { titlebars_enabled = true }
    --},

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then atomi.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        atomi.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = atomi.util.table.join(
        atomi.button({ }, 1, function()
            client.focus = c
            c:raise()
            atomi.mouse.client.move(c)
        end),
        atomi.button({ }, 3, function()
            client.focus = c
            c:raise()
            atomi.mouse.client.resize(c)
        end)
    )

    atomi.titlebar(c) : setup {
        { -- Left
            atomi.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = proton.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = atomi.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = proton.layout.flex.horizontal
        },
        { -- Right
            atomi.titlebar.widget.floatingbutton (c),
            atomi.titlebar.widget.maximizedbutton(c),
            atomi.titlebar.widget.stickybutton   (c),
            atomi.titlebar.widget.ontopbutton    (c),
            atomi.titlebar.widget.closebutton    (c),
            layout = proton.layout.fixed.horizontal()
        },
        layout = proton.layout.align.horizontal
    }
end)

-- Enable sloppy focus
client.connect_signal("mouse::enter", function(c)
    if atomi.layout.get(c.screen) ~= atomi.layout.suit.magnifier
        and atomi.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = ugly.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = ugly.border_normal end)


-- Restore previously selected tags
atomi.restore()
-- }}}
