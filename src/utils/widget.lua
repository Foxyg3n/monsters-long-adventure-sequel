Cursor_util = require("src/utils/cursor_util")

Widget = {}
Widget.__index = Widget

Cursor_pos = {
    x = 5,
    y = 6
}

Option_index = 1

function Widget:new(title, options)
    local widget = {}
    setmetatable(widget, Widget)
    widget.title = title or ""
    widget.options = options or {}
--     widget.width = if (string.len(widget.title) + 8) < 10 then 10 else (string.len(widget.title) + 8) end
    return widget
end

function Widget:next_option()
    if Option_index < #self.options then
        Cursor_pos.y = Cursor_pos.y + 1
        Option_index = Option_index + 1
    end
end

function Widget:previous_option()
    if Option_index > 1 then
        Cursor_pos.y = Cursor_pos.y - 1
        Option_index = Option_index - 1
    end
end

function Widget:retrieve_option()
    return self.options[Option_index]
end

function Widget:render()
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
    for _ = 1, #self.options do
    print("██                     ██")
    end
    print("██                     ██")
    print("█████████████████████████")
    print()
    Cursor_util.print_in_pos(self.title, { widget_origin.x, widget_origin.y })
    for i = 1, #self.options do
        Cursor_util.print_in_pos(self.options[i], { widget_origin.x + 2, widget_origin.y + 1 + i })
    end

    Cursor_util.print_in_pos("█", { Cursor_pos.x, Cursor_pos.y })
end

return Widget
