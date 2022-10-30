Cursor_util = require("src/utils/cursor_util")

Widget = {}
Widget.__index = Widget

Cursor_origin = {
    x = 5,
    y = 6
}

function Widget:new(title, options)
    local widget = {}
    setmetatable(widget, Widget)
    widget.title = title or ""
    widget.options = options or {}
    widget.width = 10
    if widget.width < string.len(widget.title) + 8 then
        widget.width = string.len(widget.title) + 8
    end
    widget.option_index = 1
    widget.cursor_pos = { x = Cursor_origin.x, y = Cursor_origin.y }
    return widget
end

function Widget:next_option()
    if self.option_index < #self.options then
        self.cursor_pos.y = self.cursor_pos.y + 1
        self.option_index = self.option_index + 1
    end
end

function Widget:previous_option()
    if self.option_index > 1 then
        self.cursor_pos.y = self.cursor_pos.y - 1
        self.option_index = self.option_index - 1
    end
end

function Widget:retrieve_option()
    return self.options[self.option_index]

end

function Widget:render()
    local widget_origin = {
        x = 5,
        y = 4
    }
    print()
    print(string.rep("█", self.width))
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    for _ = 1, #self.options do
        print("██" .. string.rep(" ", self.width - 4) .. "██")
    end
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print(string.rep("█", self.width))
    print()
    Cursor_util.print_in_pos(self.title, { widget_origin.x, widget_origin.y })
    for i = 1, #self.options do
        Cursor_util.print_in_pos(self.options[i], { widget_origin.x + 2, widget_origin.y + 1 + i })
    end

    Cursor_util.print_in_pos("█", { self.cursor_pos.x, self.cursor_pos.y })
end

return Widget
