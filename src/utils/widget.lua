Cursor_util = require("src/utils/cursor_util")

Widget = { name = "", width = 0, title = "", options = "" }

Cursor_pos = {
    x = 5,
    y = 6
}

Option_index = 1

function Widget:new(o, title, options)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.width = 10
    self.title = title or ""
    self.options = options or {}
    return o
end

function Widget.next_option()
    if Option_index < #Widget.options then
        Cursor_pos.y = Cursor_pos.y + 1
        Option_index = Option_index + 1
    end
end

function Widget.previous_option()
    if Option_index > 1 then
        Cursor_pos.y = Cursor_pos.y - 1
        Option_index = Option_index - 1
    end
end

function Widget.retrieve_option()
    return Option_index
end

function Widget.render()
   local widget_origin = {
        x = 5,
        y = 4
    }
    -- local widget_width = 15
    print()
    print("█████████████████████████")
    print("██                     ██")
    print("██                     ██")
    print("██                     ██")
    for _ = 1, #Widget.options do
    print("██                     ██")
    end
    print("██                     ██")
    print("█████████████████████████")
    print()
    Cursor_util.print_in_pos(Widget.title, { widget_origin.x, widget_origin.y })
    for i = 1, #Widget.options do
        Cursor_util.print_in_pos(Widget.options[i], { widget_origin.x + 2, widget_origin.y + 1 + i })
    end

    Cursor_util.print_in_pos("█", { Cursor_pos.x, Cursor_pos.y })
end

return Widget
