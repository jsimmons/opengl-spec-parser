local concat = table.concat
local insert = table.insert
local open = io.open
local loadstring = loadstring
local setfenv = setfenv
local setmetatable = setmetatable
local pcall = pcall

-- Takes source of given name and environment, and returns a function that will
-- evaluate the template with the given table of data.

-- @param source A collection of code blocks and arbitary text in a string.
--               '{{' and '}}' delimit a block and if the first character in a
--               block is '=' the value of the variable inside the block will
--               be output directly.
-- @param name   The name given to the chunk that makes up the template code.
--               This is used only for debugging and error messages.
-- @param env    The environment table in which the template is to be executed,
--               defaults to _G, however it is possible to pass in a custom
--               table in order to sandbox the template code.

-- @returns A function taking a table of data to be passed on to the generated
-- template code, this then, returns the result of the template execution or
-- nil followed by an error message.
local function compile(source, name, env)
    local code, index = {}, 1

    while true do
        -- Find code blocks delimited by {{ and }}.
        local start, stop, block = source:find('({%b{}})', index)

        -- Insert the block of plaintext prior to the code block as an echo.
        local middle = source:sub(index, (start or 0) - 1)
        insert(code, ('echo [====[%s]====]'):format(middle))

        -- If the pattern was not found we're at the end of the source so no
        -- need to continue.
        if not start then break end

        -- In this block determine if the result should be echoed or simply
        -- executed, as well as extract the actual code.
        local echo, block = block:match('{{(=?)(.+)}}')

        if echo:len() == 1 then
            block = ('echo(%s)'):format(block)
        end

        insert(code, block)

        index = stop + 1
    end

    local chunk, err = loadstring(concat(code, '\n'), name)
    if not chunk then return nil, err end

    return function(data)
        local output = {}
        function data.echo(...)
            insert(output, concat {...})
        end

        -- Instead of joining the two tables manually, we make lookups which
        -- fail in the data table fall back to the environment passed when we
        -- compiled. This means that views are unable to inadvertently mess
        -- with the global state, and with a restricted environment, are
        -- completely unable to.
        data = setmetatable(data or {}, {
            __index=env;
            __metatable='metatable is locked'
        })

        setfenv(chunk, data)

        local success, err = pcall(chunk)
        if not success then return nil, err end

        return concat(output)
    end
end

-- Shortcut function for loading a template from a file.
-- @see compile()
local function compile_file(path, env)
    local file, err = open(path, 'r')
    if not file then return nil, err end

    local source = file:read('*a')
    if not source then return nil, 'could not read from file' end

    file:close();

    return compile(source, path, env)
end

return {
    compile = compile;
    compile_file = compile_file;
}
