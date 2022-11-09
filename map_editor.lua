#!/usr/bin/luajit

--[[

TODOs:
-- add map size as map property
-- create change history (so you can CTRL Z)
-- export setting mode/menu to function

]] --

Map_handler = require("src/maps")
Color = require("src/colors")
Cursor_util = require("src/utils/cursor_util")
Input_reader = require("src/input_reader")
Widget, Input_requester = require("src/utils/widget")()

Maps = Map_handler.load_maps()

Text_buffer = ""

Editing_map = nil
Editing_region = nil

Map_symbols = {
    empty = " ",
    wall = "#"
}

Mode = {
    menu = "menu",
    edit = "edit"
}

Menu = {
    main = {},
    map_choice = {},
    map_regions = {},
    quit_without_saving = {},
    region = {}
}

Current_mode = Mode.menu
Current_menu = Widget:new()

Cursor_direction = {
    up = Input_reader.Key_code.arrow.up,
    down = Input_reader.Key_code.arrow.down,
    left = Input_reader.Key_code.arrow.left,
    right = Input_reader.Key_code.arrow.right
}

Editing_cursor_pos = {
    x = 1,
    y = 1
}

Editing_selection_origin = {}
Editing_selection_pos1 = {}
Editing_selection_pos2 = {}

Is_saved = true
Is_multiselect = false

local function copy_obj(obj)
    local copy = {}
    for k,v in pairs(obj) do
       copy[k] = v
    end
    return copy
end

local function table_contains(table, contains)
    for _, value in pairs(table) do
        if value == contains then
            return true
        end
    end
    return false
end

local function initialize_menus()
    Menu.main = Widget:new("SONIC MAP EDITOR", { "Edit map", "Add map", "Remove map", "Quit" })
    local map_names = {}
    for k, _ in pairs(Maps) do table.insert(map_names, Maps[k].map_name) end
    table.sort(map_names)
    Menu.map_choice = Widget:new("Choose map to edit", map_names)
    Menu.quit_without_saving = Widget:new("Are you sure you want quit without saving?", { "Yes", "No" })
    Menu.map_regions = Widget:new("Choose a region to edit (+ add / - remove)", {})
    Menu.region = Widget:new("", { "Edit name", "Edit region bounds", "Edit monster chances" })
end

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function exit()
    clear_screen()
    print(Color.yellow .. "\nBye bye!\n" .. Color.reset)
    os.exit(0)
end

local function print_text(text)
    Text_buffer = text
end

local function reset_cursor_pos()
    Editing_cursor_pos = { x = 1, y = 1 }
end

local function update_selection_position()
    if Editing_cursor_pos.x > Editing_selection_origin.x then
        Editing_selection_pos2.x = Editing_cursor_pos.x
    elseif Editing_cursor_pos.x == Editing_selection_origin.x then
        Editing_selection_pos1.x = Editing_cursor_pos.x
        Editing_selection_pos2.x = Editing_cursor_pos.x
    else
        Editing_selection_pos1.x = Editing_cursor_pos.x
    end
    if Editing_cursor_pos.y > Editing_selection_origin.y then
        Editing_selection_pos2.y = Editing_cursor_pos.y
    elseif Editing_cursor_pos.y == Editing_selection_origin.y then
        Editing_selection_pos1.y = Editing_cursor_pos.y
        Editing_selection_pos2.y = Editing_cursor_pos.y
    else
        Editing_selection_pos1.y = Editing_cursor_pos.y
    end
end

local function update_cursor_position(cursor_direction)
    if cursor_direction == Cursor_direction.up then
        Editing_cursor_pos.y = Editing_cursor_pos.y - 1
    elseif cursor_direction == Cursor_direction.down then
        Editing_cursor_pos.y = Editing_cursor_pos.y + 1
    elseif cursor_direction == Cursor_direction.left then
        Editing_cursor_pos.x = Editing_cursor_pos.x - 1
    elseif cursor_direction == Cursor_direction.right then
        Editing_cursor_pos.x = Editing_cursor_pos.x + 1
    end

    if Editing_cursor_pos.x < 1 then Editing_cursor_pos.x = 1 end
    if Editing_cursor_pos.x > #Editing_map.data[1] then Editing_cursor_pos.x = #Editing_map.data[1] end
    if Editing_cursor_pos.y < 1 then Editing_cursor_pos.y = 1 end
    if Editing_cursor_pos.y > #Editing_map.data then Editing_cursor_pos.y = #Editing_map.data end

    if Is_multiselect then update_selection_position() end
end

local function set_map_symbol(pos, symbol)
    Editing_map.data[pos.y][pos.x] = symbol
end

local function set_map_symbols(pos1, pos2, symbol)
    for x = 1, pos2.x - pos1.x + 1 do
        for y = 1, pos2.y - pos1.y + 1 do
            Editing_map.data[pos1.y + y - 1][pos1.x + x - 1] = symbol
        end
    end
end

local function handle_menu_option(option)
    if Current_menu == Menu.main then
        if option == Current_menu.options[1] then
            Current_menu = Menu.map_choice
        elseif option == Current_menu.options[2] then
            print_text("Adding map...")
        elseif option == Current_menu.options[3] then
            print_text("Removing map...")
        elseif option == Current_menu.options[4] then
            exit()
        end
    elseif Current_menu == Menu.map_choice then
        local map_name = Current_menu:retrieve_option()
        Maps = Map_handler.load_maps()
        Editing_map = Maps[map_name]
        local regions = {}
        for i = 1, #Editing_map.regions do
            table.insert(regions, Editing_map.regions[i].name)
        end
        Menu.map_regions:setOptions(regions)
        Current_mode = Mode.edit
    elseif Current_menu == Menu.quit_without_saving then
        if option == "Yes" then
            Current_mode = Mode.menu
            Current_menu = Menu.main
            reset_cursor_pos()
            Is_saved = true
        elseif option == "No" then
            Current_mode = Mode.edit
            Current_menu = Menu.main
        end
    elseif Current_menu == Menu.map_regions then
        local region_index = Current_menu:retrieve_option_index()
        Editing_region = Editing_map.regions[region_index]
        Current_menu = Menu.region
        Current_menu:setTitle(Editing_map.map_name .. " - " .. Editing_region.name)
    elseif Current_menu == Menu.region then
        if option == Current_menu.options[1] then
            local region_name = Input_requester:new("Type region's new name (" .. Editing_region.name .. ")"):request_input()
            if region_name == "" then
                print_text("Aborting")
            else
                Editing_region.name = region_name
                local regions = {}
                for i = 1, #Editing_map.regions do
                    table.insert(regions, Editing_map.regions[i].name)
                end
                Menu.map_regions:setOptions(regions)
                Current_menu:setTitle(Editing_map.map_name .. " - " .. Editing_region.name)
                Is_saved = false
            end
        elseif option == Current_menu.options[2] then
            -- edit boundries of the region
        elseif option == Current_menu.options[3] then
            -- edit monster ecounter probabilities
        end
    end
end

local function handle_menu_input(input)
    if input == "q" then
        if Current_menu == Menu.map_regions then
            Current_mode = Mode.edit
        elseif Current_menu == Menu.region then
            Current_mode = Mode.menu
            Current_menu = Menu.map_regions
        else
            exit()
        end
    elseif input == "+" then
        local region_name = Input_requester:new("Type new region's name"):request_input()
        if region_name == "" then
            print_text("Aborting...")
            return
        end
        table.insert(Editing_map.regions, { name = region_name, x1 = 1, y1 = 1, x2 = 1, y2 = 1 })
        local regions = {}
        for i = 1, #Editing_map.regions do
            table.insert(regions, Editing_map.regions[i].name)
        end
        Menu.map_regions:setOptions(regions)
        Is_saved = false
        print_text("Added new region " .. region_name)
    elseif input == "-" then
        print_text("Removing this region...")
    end
    if input == Key_code.arrow.up then
        Current_menu:previous_option()
    elseif input == Key_code.arrow.down then
        Current_menu:next_option()
    elseif input == Key_code.enter then
        local option = Current_menu:retrieve_option()
        handle_menu_option(option)
    end
end

local function handle_edit_input(input)
    if table_contains(Key_code.arrow, input) then
        update_cursor_position(input)
    end
    if input == "q" then
        if Is_saved then
            Current_mode = Mode.menu
            Current_menu = Menu.main
            reset_cursor_pos()
        else
            Current_mode = Mode.menu
            Current_menu = Menu.quit_without_saving
        end
    elseif input == "t" then
        if Is_multiselect then
            set_map_symbols(Editing_selection_pos1, Editing_selection_pos2, Map_symbols.wall)
            Is_multiselect = false
        else
            set_map_symbol(Editing_cursor_pos, Map_symbols.wall)
        end
        Is_saved = false
    elseif input == "d" then
        if Is_multiselect then
            set_map_symbols(Editing_selection_pos1, Editing_selection_pos2, Map_symbols.empty)
            Is_multiselect = false
        else
            set_map_symbol(Editing_cursor_pos, Map_symbols.empty)
        end
        Is_saved = false
    elseif input == "s" then
        Map_handler.save_map(Editing_map)
        print_text("Saving map " .. Editing_map.map_name .. "...")
        Is_saved = true
    elseif input == "r" then
        Current_mode = Mode.menu
        Current_menu = Menu.map_regions
    elseif input == "v" then
        if not Is_multiselect then
            Editing_selection_origin = copy_obj(Editing_cursor_pos)
            Editing_selection_pos1 = copy_obj(Editing_selection_origin)
            Editing_selection_pos2 = copy_obj(Editing_selection_origin)
            Is_multiselect = true
        else
            Is_multiselect = false
        end
    end
end

local function handle_input(input)
    Key_code = Input_reader.Key_code
    if Current_mode == Mode.menu then handle_menu_input(input)
    elseif Current_mode == Mode.edit then handle_edit_input(input)
    end
end

local function render_map()
    io.write("\u{250c}")
    for _ = 0, #Editing_map.data[1] - 1 do
        io.write("\u{2500}")
    end
    print("\u{2510}")
    for y = 1, #Editing_map.data do
        io.write("\u{2502}")
        for x = 1, #Editing_map.data[y] do
            if not Is_multiselect then
                if x == Editing_cursor_pos.x and y == Editing_cursor_pos.y then io.write(Color.invert) end
            else
                if x >= Editing_selection_pos1.x and x <= Editing_selection_pos2.x and y >= Editing_selection_pos1.y and y <= Editing_selection_pos2.y then
                    io.write(Color.invert)
                end
            end
            io.write(Editing_map.data[y][x])
            io.write(Color.reset)
        end
        io.write("\u{2502}")
        print()
    end
    io.write("\u{2514}")
    for _ = 0, #Editing_map.data[1] - 1 do
        io.write("\u{2500}")
    end
    print("\u{2518}")
end

local function render_legend()
    local offset_x = #Editing_map.data[1] + 4
    local offset_y = 2
    Cursor_util.print_in_pos("d - Delete character", { offset_x, offset_y })
    Cursor_util.print_in_pos("t - Set wall", { offset_x, offset_y + 1 })
    Cursor_util.print_in_pos("r - Edit regions", { offset_x, offset_y + 2 })
    Cursor_util.print_in_pos("q - Quit", { offset_x, offset_y + 3 })
    if not Is_saved then
        Cursor_util.print_in_pos("* Map not saved", { offset_x, offset_y + 5 })
    end
end

local function Editor()
    initialize_menus()
    Current_menu = Menu.main
    Current_menu:render()

    local user_input = ""

    -- editor loop
    while true do
        clear_screen()
        if Current_mode == Mode.menu then
            Current_menu:render()
            print(Text_buffer)
            Text_buffer = ""
            user_input = Input_reader.read_key()
            handle_input(user_input)
        elseif Current_mode == Mode.edit then
            render_map()
            render_legend()
            print(Text_buffer)
            Text_buffer = ""
            user_input = Input_reader.read_key()
            handle_input(user_input)
        end
    end
end

Editor()
