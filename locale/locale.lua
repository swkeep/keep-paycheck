Locale = {
    phrases = {},
    warnOnMissing = false
}

function string.split(inputstr, delimiter)
    if delimiter == nil then delimiter = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. delimiter .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function Locale:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.phrases = o.phrases or {}
    self.warnOnMissing = o.warnOnMissing or false
    return o
end

function Locale:translate(key)
    local keys = string.split(key, '.')
    local value = self.phrases

    for _, k in ipairs(keys) do
        if type(value) == 'table' then
            value = value[k]
        else
            if self.warnOnMissing then
                print(('Missing translation for key: %s'):format(key))
            end
            return key
        end
    end

    return value or key
end

function Locale:t(key) return self:translate(key) end
