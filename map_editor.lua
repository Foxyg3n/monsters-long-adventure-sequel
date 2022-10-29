#!/usr/bin/luajit

Map_handler = require("src/maps")
Cursor_util = require("src/utils/cursor_util")
Input_reader = require("src/input_reader")
Widget = require("src/utils/widget")

Maps = Map_handler.load_maps()

Text_buffer = ""

Menu_cursor_origin = {
    x = 5,
    y = 4
}

Menu_cursor_pos = {
    x = Menu_cursor_origin.x,
    y = Menu_cursor_origin.y
}

Menu = {
    main_menu = {}
}

Current_menu = Widget:new()

local function initialize_menus()
    Menu.main_menu = Widget:new(nil, "SONIC MAP EDITOR", { "Edit map", "Add map", "Remove map" })
end

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function print_text(text)
    Text_buffer = text
end

local function handle_menu_option(option)
    if Current_menu == Menu.main_menu then
        if option == 1 then
            print_text("Editing map...")
        elseif option == 2 then
            print_text("Adding map...")
        elseif option == 3 then
            print_text("Removing map...")
        end
    end
end

local function handle_input(input)
    Key_code = Input_reader.Key_code
    if input == "q" then
        os.exit()
    elseif input == Key_code.arrow.up then
        Current_menu.previous_option()
    elseif input == Key_code.arrow.down then
        Current_menu.next_option()
    elseif input == Key_code.enter then
        local option = Current_menu.retrieve_option()
        handle_menu_option(option)
    end
end

local function Editor()
    initialize_menus()
    Current_menu = Menu.main_menu
    Current_menu.render()

    local user_input = ""

    -- editor loop
    while true do
        clear_screen()
        Current_menu.render()
        print(Text_buffer)
        user_input = Input_reader.read_key()
        handle_input(user_input)
    end
end

Editor()
