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

-- A somewhat simplified OpenGL spec file parser designed to make it possible
-- to generate OpenGL bindings from your language of choice. It could also be
-- used to transcode spec files into something more reasonable like JSON.

-- A generic parser structure for parsing gl registry files.
-- Takes a path to the file and a pattern->callback table and then for each
-- non-comment line in the file tries to apply each pattern until one succeeds
-- at which point the captures are passed to the callback.
local function basic_parser(path, patterns)
    for line in io.lines(path) do
        -- Remove the comment part from any place in the line.
        line = line:gsub('#.*', '')

        -- If there was nothing but comment or an empty line there'll only be
        -- whitespace left in which case let's break out.
        if line:find('%S') then
            for pattern, callback in pairs(patterns) do
                local matches = {line:match(pattern)}

                -- Ensure that the pattern was successfully matched before
                -- invoking the callback.
                if matches[1] ~= nil then
                    callback(unpack(matches))
                    break
                end
            end
        end
    end
end

local function typemap(path)
    local map = {}

    local patterns = {
        ['([^,]+)%W+([^,]+)'] = function(a, b)
            -- 'void' causes trouble so let's fix it.
            if b == '*' then
                map[a] = a
            else
                map[a] = b
            end
        end;
    }

    basic_parser(path, patterns)

    return map
end

local function parse_enums(path, extpath, version, whitelist)
    local enums, drop = {}, false

    local patterns = {
        ['(%S+)%s*=%s*(%S+)'] = function(symbol, value)
            if drop then return end

            -- Expand references here as the hash table being unordered will
            -- otherwise muddle everything up.
            value = value:gsub('GL_', '')
            enums[symbol] = enums[value] or value
        end;

        ['^(%S+) enum:'] = function(name)
            if whitelist[name] then
                drop = false
                return
            end

            drop = true

            local major, minor, dep = name:match('VERSION_(%d)_(%d)_?(.*)')
            if major == nil then return end

            -- Drop all deprecated items for now.
            if dep ~= 'DEPRECATED' and (major * 10 + minor <= version) then
                drop = false
            end
        end;
    }

    basic_parser(path, patterns)
    basic_parser(extpath, patterns)

    return enums
end

local function parse_funcs(path, tm, version, whitelist)
    local functions = {}, current_function, current_name

    local patterns = {
        ['^(%w+)%(.*%)'] = function(name)
            -- Store the last function if finished
            if current_name then functions[current_name] = current_function end

            current_name = name
            current_function = {params = {}}
        end;

        -- TODO: Capture array length information in a useful manner.
        ['param%s+(%S+)%s+(%S+) (%S+) (%S+)'] = function(name, type, dir, mode)
            table.insert(current_function.params, {
                name = name;
                type = tm[type];
                dir = dir;
                mode = mode;
            })
        end;

        ['^\treturn%s+(%S+)'] = function(return_type)
            current_function.return_type = tm[return_type]
        end;

        ['^\tdeprecated%s+(%S+)'] = function(as_of)
            if (as_of * 10) <= version then
                current_name = nil
            end
        end;

        ['^\tversion%s+(%S+)'] = function(from)
            if (from * 10) > version then
                current_name = nil
            end
        end;

        ['^\talias%s+(%S+)'] = function(as)
            current_function.alias = as
        end;

        ['^\tcategory%s+(%S+)'] = function(name)
            -- Use the version information from the version specifier to save
            -- duplication.
            if not name:find('VERSION') and not whitelist[name] then
                current_name = nil
            end
        end;
    }

    basic_parser(path, patterns)

    return functions
end

local function gl(path, tm_path, enum_path, enumext_path, version, whitelist)
    whitelist = whitelist or {}

    local tm = typemap(tm_path)

    return {
        enums = parse_enums(enum_path, enumext_path, version, whitelist);
        funcs = parse_funcs(path, tm, version, whitelist);
    }
end

return {
    gl = gl;
}
