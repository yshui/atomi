local ok, mpack = pcall(require, "mpack")

if not ok then
    local function _dummy()
    end
    return _dummy
end

local ascreen = require("atomi.screen")
local atag = require("atomi.tag")

local function save_state()
    local stags = {}
    for s in screen do
        local tags = {}
        for _, t in ipairs(s.selected_tags) do
            table.insert(tags, t.name)
        end
        stags[s.name] = tags
    end

    local outf = io.output("/tmp/awesome_state.mpack")
    local pack = mpack.Packer()
    outf:write(pack(stags))
end

awesome.connect_signal("exit", function(restart)
    if restart then
        save_state()
    end
end)

local function _restore()
    local inf = io.open("/tmp/awesome_state.mpack")
    if inf == nil then
        return
    end

    local o = inf:read("*all")
    print("Restoring: ")

    local unpack = mpack.Unpacker()
    local stags = unpack(o)

    for s in screen do
        if stags[s.name] then
            local tags = {}
            for _, tname in ipairs(stags[s.name]) do
                table.insert(tags, atag.find_by_name(tname))
            end
            atag.viewmore(tags, s)
        end
    end

    os.remove("/tmp/awesome_state.mpack")
end

return _restore

