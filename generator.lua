local parser = require 'parser'
local template = require 'template'

local function generate(spec, version, target)
    local t, e = template.compile_file('targets/' .. target .. '.tmpl', _G)
    if t == nil then return nil, e end

    local result = parser[spec]('registry/', version)

    return t {spec = result}
end

return {
    generate = generate;
}
