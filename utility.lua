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

--[[ Simple adhoc function not in Muppet Utils]]
--- Make a copy of a table's values by references. Useful for making reference tables to shared objects.
---@param object table # The object to copy.
---@return table
Utility.CopyValuesByReference = function(object)
    ---@cast object table<any, any>
    local newTable = {} ---@type table<any, any>
    for k, v in pairs(object) do
        newTable[k] = v
    end
    return newTable
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

--[[ Simple adhoc function not in Muppet Utils]]
Utility.ErrorMessageTextColor = { r = 255, g = 45, b = 45 }
Utility.WarningMessageTextColor = { r = 255, g = 230, b = 45 }

--[[ Simple adhoc function not in Muppet Utils]]
--- Print an error message.
---@param message string
Utility.PrintError = function(message)
    game.print("Mod '" .. script.mod_name .. "' caused an error:", { color = Utility.ErrorMessageTextColor })
    game.print(message, { color = Utility.ErrorMessageTextColor })
    game.print("Report to mod author", { color = Utility.ErrorMessageTextColor })
end

--[[ Simple adhoc function not in Muppet Utils]]
--- Print a warning message.
---@param message string
Utility.PrintWarning = function(message)
    game.print("Mod '" .. script.mod_name .. "' raised a warning for your consideration:", { color = Utility.WarningMessageTextColor })
    game.print(message, { color = Utility.WarningMessageTextColor })
end

--[[ Simple adhoc function not in Muppet Utils]]
--- Make a GPS location string.
---@param position MapPosition
---@param surfaceId SurfaceIdentification
---@return string
Utility.MakeGpsString = function(position, surfaceId)
    local surface ---@type string
    if type(surfaceId) == "string" then
        surface = surfaceId
    elseif type(surfaceId) == "number" then
        ---@cast surfaceId uint
        local luaSurface = game.surfaces[surfaceId] ---@type LuaSurface
        if luaSurface == nil then error("invalid surfaceId number passed to Utility.MakeGpsString(): " .. surfaceId) end
        surface = luaSurface.name
    elseif type(surfaceId) == "table" then
        ---@cast surfaceId LuaSurface
        if surfaceId.object_name ~= "LuaSurface" then error("invalid surfaceId object passed to Utility.MakeGpsString(): " .. surfaceId.object_name) end
        surface = surfaceId.name
    else
        error("unhandled surfaceId passed to Utility.MakeGpsString(): " .. surfaceId)
    end
    local gpsString = "[gps=" .. position.x .. "," .. position.y .. "," .. surface .. "]"
    return gpsString
end

return Utility
