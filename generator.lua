local parser = require 'parser'
local template = require 'template'

local function generate(target, version)
    local t, e = template.compile_file('targets/' .. target .. '.tmpl', _G)
    if t == nil then return nil, e end

    local spec = parser.gl('registry/gl.spec', 'registry/gl.tm',
        'registry/enum.spec', 'registry/enumext.spec', version)

    return t {spec = spec}
end

return {
    generate = generate;
}
