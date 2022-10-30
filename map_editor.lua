#!/usr/bin/luajit

--[[

TODOs:
-- add map size as map property
-- create change history (so you can CTRL Z)

]] --

Map_handler = require("src/maps")
Color = require("src/colors")
Cursor_util = require("src/utils/cursor_util")
Input_reader = require("src/input_reader")
Widget = require("src/utils/widget")

Maps = Map_handler.load_maps()

Text_buffer = ""

Menu = {
    main = {},
    map_choice = {}
}

Current_menu = Widget:new()

Mode = {
    menu = "menu",
    edit = "edit"
}

Current_mode = Mode.menu

Editing_map = nil

Editing_cursor_pos = {
    x = 1,
    y = 1
}

local function table_contains(table, contains)
    for _, value in pairs(table) do
        if value == contains then
            return true
        end
    end
    return false
end

local function initialize_menus()
    Menu.main = Widget:new("SONIC MAP EDITOR", { "Edit map", "Add map", "Remove map" })
    local map_names = {}
    for k, _ in pairs(Maps) do table.insert(map_names, Maps[k].map_name) end
    table.sort(map_names)
    Menu.map_choice = Widget:new("Choose map to edit", map_names)
end

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function print_text(text)
    Text_buffer = text
end

local function handle_menu_option(option)
    if Current_menu == Menu.main then
        if option == Current_menu.options[1] then
            Current_menu = Menu.map_choice
        elseif option == Current_menu.options[2] then
            print_text("Adding map...")
        elseif option == Current_menu.options[3] then
            print_text("Removing map...")
        end
    elseif Current_menu == Menu.map_choice then
        local map_name = Current_menu:retrieve_option()
        Editing_map = Maps[map_name]
        Current_mode = Mode.edit
    end
end

local function handle_menu_input(input)
    if input == "q" then os.exit() end
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
    -- cursor position
    if table_contains(Key_code.arrow, input) then
        if input == Key_code.arrow.up then
            Editing_cursor_pos.y = Editing_cursor_pos.y - 1
        elseif input == Key_code.arrow.down then
            Editing_cursor_pos.y = Editing_cursor_pos.y + 1
        elseif input == Key_code.arrow.left then
            Editing_cursor_pos.x = Editing_cursor_pos.x - 1
        elseif input == Key_code.arrow.right then
            Editing_cursor_pos.x = Editing_cursor_pos.x + 1
        end
        if Editing_cursor_pos.x < 1 then Editing_cursor_pos.x = 1 end
        if Editing_cursor_pos.x > #Editing_map.data[1] then Editing_cursor_pos.x = #Editing_map.data[1] end
        if Editing_cursor_pos.y < 1 then Editing_cursor_pos.y = 1 end
        if Editing_cursor_pos.y > #Editing_map.data then Editing_cursor_pos.y = #Editing_map.data end
    end
    if input == "q" then
        Map_handler.save_map(Editing_map)
        print("Saving map " .. Editing_map.map_name .. "...")
        os.exit()
    elseif input == "t" then
        Editing_map.data[Editing_cursor_pos.y][Editing_cursor_pos.x] = "#"
    elseif input == "d" then
        Editing_map.data[Editing_cursor_pos.y][Editing_cursor_pos.x] = " "
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
            if x == Editing_cursor_pos.x and y == Editing_cursor_pos.y then io.write(Color.underline) end
            if Editing_map.data[y][x] == nil then
                io.write("\u{2800}")
            else
                io.write(Editing_map.data[y][x])
            end
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
    Cursor_util.print_in_pos("q - Quit", { offset_x, offset_y + 2 })
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
            -- TODO: handle text buffer properly
            print(Text_buffer)
            Text_buffer = ""
            user_input = Input_reader.read_key()
            handle_input(user_input)
        elseif Current_mode == Mode.edit then
            render_map()
            render_legend()
            -- TODO: handle text buffer properly
            print(Text_buffer)
            Text_buffer = ""
            user_input = Input_reader.read_key()
            handle_input(user_input)
        end
    end
end

Editor()
