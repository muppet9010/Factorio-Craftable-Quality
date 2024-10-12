--[[
    Utility Functions
]]
local Utility = {}
local string_match = string.match

--[[    STOLEN FROM MUPPET UTILS - string-utils    --]]
--- Separates out the number and unit from when they combined in a single string, i.e. 5KW
---@param text string
---@return double number
---@return string unit
Utility.GetValueAndUnitFromString = function(text)
    return string_match(text, "%d+%.?%d*"), string_match(text, "%a+")
end

--[[    STOLEN FROM MUPPET UTILS - table-utils   --]]
--- Copies a table and all of its children all the way down.
--- Based on code from Factorio "__core__.lualib.util.lua", table.deepcopy().
---@param object table # The object to copy.
---@return table
Utility.DeepCopy = function(object)
    local lookup_table = {} ---@type table<any, any>
    return Utility._DeepCopy_InnerCopy(object, lookup_table)
end

--[[    STOLEN FROM MUPPET UTILS - table-utils   --]]
--- Inner looping of DeepCopy. Kept as separate function as then its a copy of Factorio core utils.
---@param object any
---@param lookup_table table<any, any>
---@return any
Utility._DeepCopy_InnerCopy = function(object, lookup_table)
    if type(object) ~= "table" then
        -- don't copy factorio rich objects
        return object
    elseif object.__self then
        return object
    elseif lookup_table[object] then
        return lookup_table[object]
    end ---@cast object table<any, any>
    local new_table = {} ---@type table<any, any>
    lookup_table[object] = new_table
    for index, value in pairs(object) do
        new_table[Utility._DeepCopy_InnerCopy(index, lookup_table)] = Utility._DeepCopy_InnerCopy(value, lookup_table)
    end
    return setmetatable(new_table, getmetatable(object))
end

return Utility
