Cursor_util = require("src/utils/cursor_util")

Widget = {}
Widget.__index = Widget

Input_requester = {}
Input_requester.__index = Input_requester

Cursor_origin = {
    x = 5,
    y = 6
}

local function getMaxLength(widget)
    local maxLength = string.len(widget.title)
    for i = 1, #widget.options do
        maxLength = math.max(string.len(widget.options[i]) + 2, maxLength)
    end
    return maxLength
end

local function clear_screen()
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
    io.flush()
end

local function table_contains(table, contains)
    for _, value in pairs(table) do
        if value == contains then
            return true
        end
    end
    return false
end

function Widget:new(title, options)
    local widget = {}
    setmetatable(widget, Widget)
    widget.title = title or ""
    widget.options = options or {}
    widget.width = getMaxLength(widget) + 8
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

function Widget:retrieve_option_index()
    return self.option_index
end

function Widget:setTitle(title)
    self.title = title
end

function Widget:setOptions(options)
    self.options = options
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

function Input_requester:new(prompt)
    local input_requester = {}
    setmetatable(input_requester, Input_requester)
    input_requester.prompt = prompt or ""
    input_requester.input = ""
    input_requester.width = string.len(input_requester.prompt) + 8
    input_requester.cursor_pos = 1
    return input_requester
end

function Input_requester:cursor_left()
    if self.cursor_pos == 1 then return end
    self.cursor_pos = self.cursor_pos - 1
end

function Input_requester:cursor_right()
    if self.cursor_pos == self.width - 7 then return end
    if self.cursor_pos == string.len(self.input) + 1 then return end
    self.cursor_pos = self.cursor_pos + 1
end

function Input_requester:remove_letter()
    local new_input = string.sub(self.input, 1, self.cursor_pos - 2) .. string.sub(self.input, self.cursor_pos, string.len(self.input))
    self.input = new_input
    self:cursor_left()
end

function Input_requester:print_letter(letter)
    local new_input
    if string.len(self.input) == self.width - 8 then
        new_input = string.sub(self.input, 1, self.cursor_pos - 1) .. letter .. string.sub(self.input, self.cursor_pos + 1, string.len(self.input))
    else
        new_input = string.sub(self.input, 1, self.cursor_pos - 1) .. letter .. string.sub(self.input, self.cursor_pos, string.len(self.input))
    end
    self.input = string.sub(new_input, 1, self.width - 8)
    self:cursor_right()
end

function Input_requester:retrieve_input()
    return self.input
end

function Input_requester:render()
    local origin = {
        x = 5,
        y = 4
    }
    print()
    print(string.rep("█", self.width))
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print("██" .. string.rep(" ", self.width - 4) .. "██")
    print(string.rep("█", self.width))
    print()
    Cursor_util.print_in_pos(self.prompt, { origin.x, origin.y })

    local cursor_sign
    if string.len(self.input) == self.cursor_pos - 1 then
        cursor_sign = "█"
    else
        cursor_sign = Color.invert .. string.sub(self.input, self.cursor_pos, self.cursor_pos)
    end
    Cursor_util.print_in_pos(self.input, { origin.x, origin.y + 2 })
    Cursor_util.print_in_pos(cursor_sign, { origin.x + self.cursor_pos - 1, origin.y + 2 })
end

function Input_requester:request_input()
    while true do
        clear_screen()
        self:render()
        print(Text_buffer)
        Text_buffer = ""
        local user_input = Input_reader.read_key()
        if table_contains(Input_reader.Key_code.arrow, user_input) then
            if user_input == Input_reader.Key_code.arrow.left then
                self:cursor_left()
            elseif user_input == Input_reader.Key_code.arrow.right then
                self:cursor_right()
            end
        elseif user_input == Input_reader.Key_code.enter then
            return self:retrieve_input()
        elseif user_input == Input_reader.Key_code.backspace then
            self:remove_letter()
        else
            self:print_letter(user_input)
        end
    end
end

return function() return Widget, Input_requester end
