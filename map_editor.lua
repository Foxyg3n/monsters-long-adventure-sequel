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
Widget = require("src/utils/widget")

Maps = Map_handler.load_maps()

Text_buffer = ""

Map_symbols = {
    empty = " ",
    wall = "#"
}

Menu = {
    main = {},
    map_choice = {},
    quit_without_saving = {}
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

Editing_selection_color = Color.background_bright_cyan

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
end

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function print_text(text)
    Text_buffer = text
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
            os.exit()
        end
    elseif Current_menu == Menu.map_choice then
        local map_name = Current_menu:retrieve_option()
        Maps = Map_handler.load_maps()
        Editing_map = Maps[map_name]
        Current_mode = Mode.edit
    elseif Current_menu == Menu.quit_without_saving then
        if option == "Yes" then
            Current_mode = Mode.menu
            Current_menu = Menu.main
            Editing_cursor_pos.x = 1
            Editing_cursor_pos.y = 1
            Is_saved = true
        elseif option == "No" then
            Current_mode = Mode.edit
            Current_menu = Menu.main
        end
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
            if Is_multiselect then update_selection_position() end
        elseif input == Key_code.arrow.down then
            Editing_cursor_pos.y = Editing_cursor_pos.y + 1
            if Is_multiselect then update_selection_position() end
        elseif input == Key_code.arrow.left then
            Editing_cursor_pos.x = Editing_cursor_pos.x - 1
            if Is_multiselect then update_selection_position() end
        elseif input == Key_code.arrow.right then
            Editing_cursor_pos.x = Editing_cursor_pos.x + 1
            if Is_multiselect then update_selection_position() end
        end
        if Editing_cursor_pos.x < 1 then Editing_cursor_pos.x = 1 end
        if Editing_cursor_pos.x > #Editing_map.data[1] then Editing_cursor_pos.x = #Editing_map.data[1] end
        if Editing_cursor_pos.y < 1 then Editing_cursor_pos.y = 1 end
        if Editing_cursor_pos.y > #Editing_map.data then Editing_cursor_pos.y = #Editing_map.data end
    end
    if input == "q" then
        if Is_saved then
            Current_mode = Mode.menu
            Current_menu = Menu.main
            Editing_cursor_pos.x = 1
            Editing_cursor_pos.y = 1
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
                if x == Editing_cursor_pos.x and y == Editing_cursor_pos.y then io.write(Color.underline) end
            else
                if x >= Editing_selection_pos1.x and x <= Editing_selection_pos2.x and y >= Editing_selection_pos1.y and y <= Editing_selection_pos2.y then
                    io.write(Editing_selection_color)
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
