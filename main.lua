--[[
Copyright (C) 2011 by Joshua Simmons

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

local parser = require 'parser'

local GL_VERSION = 42

local output, n = {}, 1

local function append(str)
    output[n] = str
    n = n + 1
end

local function append_file(path)
    local file = io.open(path)
    if file then
        output[n] = file:read('*a')
        n = n + 1
    end
end

local enums = parser.enum('registry/enum.spec', 'registry/enumext.spec')
local functions = parser.gl('registry/gl.spec', 'registry/gl.tm', GL_VERSION)

append_file('ffi_header.tmpl.lua')

append('enum {\n')
for name, value in pairs(enums) do
    append('GL_' .. name .. ' = ' .. value .. ',\n')
end
append('};\n')

for name, data in pairs(functions) do
    append(data.return_type .. ' gl' .. name .. '(')
    local count = #data.params
    for i = 1, count do
        local param = data.params[i]

        if param.dir == 'in' and param.mode ~= 'value' then
            append('const ')
        end

        append(param.type .. ((param.mode == 'value') and '' or '*'))

        if param.mode ~= 'value' then
            append('*')
        end

        if i < count then
            append(', ')
        end
    end
    append(');\n')
end

append_file('ffi_footer.tmpl.lua')

print(table.concat(output))
