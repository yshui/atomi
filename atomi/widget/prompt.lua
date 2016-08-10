---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.5.2-1890-ge472339
-- @classmod atomi.widget.prompt
---------------------------------------------------------------------------

local setmetatable = setmetatable

local completion = require("atomi.completion")
local util = require("atomi.util")
local spawn = require("atomi.spawn")
local prompt = require("atomi.prompt")
local widget_base = require("atomi.proton.widget.base")
local textbox = require("atomi.proton.widget.textbox")
local type = type

local widgetprompt = { mt = {} }

--- Run method for promptbox.
--
-- @param promptbox The promptbox to run.
local function run(promptbox)
    return prompt.run({ prompt = promptbox.prompt },
                      promptbox.widget,
                      function (...)
                          promptbox:spawn_and_handle_error(...)
                      end,
                      completion.shell,
                      util.get_cache_dir() .. "/history")
end

local function spawn_and_handle_error(self, ...)
    local result = spawn(...)
    if type(result) == "string" then
        self.widget:set_text(result)
    end
end

--- Create a prompt widget which will launch a command.
--
-- @param args Arguments table. "prompt" is the prompt to use.
-- @return A launcher widget.
function widgetprompt.new(args)
    args = args or {}
    local widget = textbox()
    local promptbox = widget_base.make_widget(widget)

    promptbox.widget = widget
    promptbox.widget:set_ellipsize("start")
    promptbox.run = run
    promptbox.spawn_and_handle_error = spawn_and_handle_error
    promptbox.prompt = args.prompt or "Run: "
    return promptbox
end

function widgetprompt.mt:__call(...)
    return widgetprompt.new(...)
end

return setmetatable(widgetprompt, widgetprompt.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
