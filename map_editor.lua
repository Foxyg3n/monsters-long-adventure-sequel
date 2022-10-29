#!/usr/bin/luajit

Map_handler = require("src/maps")
Cursor_util = require("src/utils/cursor_util")
Input_reader = require("src/input_reader")

Maps = Map_handler.load_maps()

Cursor_pos = {
    x = 5,
    y = 6
}

Menu = {
    main_menu = {
        "Edit map",
        "Add map",
        "Remove map"
    }
}

Current_menu = "main_menu"

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function render_map()
    print()
    print("█████████████████████████")
    print("██                     ██")
    print("██  SONIC MAP EDITOR   ██")
    print("██                     ██")
    print("██    Edit map         ██")
    print("██    Add map          ██")
    print("██    Remove map       ██")
    print("██                     ██")
    print("█████████████████████████")
    print()
end

local function print_ui()
    clear_screen()
    render_map()
    Cursor_util.print_in_pos("█", { Cursor_pos.x, Cursor_pos.y })
end

local function handle_input(input)
    print(input)
end

local function Editor()
    print_ui()
    print(Menu)

    -- editor loop
    while true do
        print_ui()
        local user_input = Input_reader.read_key()
        if(user_input == "q") then os.exit() end -- temp
        handle_input(user_input)
    end
end

Editor()
