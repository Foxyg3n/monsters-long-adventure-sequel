Json = require("src/utils/json")

local function copy_obj(obj)
    local copy = {}
    for k,v in pairs(obj) do
       copy[k] = v
    end
    return copy
end

local function load_map(map_name)
    local map = {}
    local map_file = "maps/" .. map_name .. ".txt"
    local index = 1
    for line in io.lines(map_file) do
        table.insert(map, {})
        for i = 1, #line do
            local c = line:sub(i, i)
            table.insert(map[index], c)
        end
        index = index + 1
    end
    return map
end

local function load_maps()
    local maps_file = assert(io.open("maps/maps.json", "rb"))
    local maps = Json.decode(maps_file:read("*all"))
    for k, _ in pairs(maps) do
        maps[k].data = load_map(maps[k].map_name)
    end
    return maps
end

local function save_map(origin_map)
    local map = copy_obj(origin_map)
    -- saving map data
    local map_file = assert(io.open("maps/" .. map.map_name .. ".txt", "w"))
    for y = 1, #map.data do
        local line = ""
        for x = 1, #map.data[1] do
            line = line .. map.data[y][x]
        end
        map_file:write(line .. "\n")
    end
    -- saving map.json
    local maps = load_maps()
    maps[map.map_name] = map
    for k, _ in pairs(maps) do
        maps[k].data = ""
    end
    local maps_file = assert(io.open("maps/maps.json", "w"))
    maps_file:write(Json.encode(maps))
    map_file:close()
    maps_file:close()
end

Maps = {
    load_maps = load_maps,
    save_map = save_map
}

return Maps
