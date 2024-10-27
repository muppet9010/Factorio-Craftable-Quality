local Utility = require("utility")

local Icons = {}

local qualityIconScaleModifier = 0.4

--- Make a new recipe Icons from the reference item Icons and the qualities involved.
---@param copyItemIcons data.IconData[]
---@param fromQuality data.QualityPrototype
---@param toQuality data.QualityPrototype
---@return data.IconData[]
Icons.MakeRecipeIcons = function(copyItemIcons, fromQuality, toQuality)
    local recipeIcons = copyItemIcons ---@type data.IconData[]
    local fromQualityIcons = Utility.MakeIconsCopyFromIconOrIcons(fromQuality.icon, fromQuality.icon_size, fromQuality.icons)
    local toQualityIcons = Utility.MakeIconsCopyFromIconOrIcons(toQuality.icon, toQuality.icon_size, toQuality.icons)

    Icons.AddSmallIconsToCornerOfIcons(copyItemIcons, fromQualityIcons, qualityIconScaleModifier, -1, 1)
    Icons.AddSmallIconsToCornerOfIcons(copyItemIcons, toQualityIcons, qualityIconScaleModifier, 1, 1)

    return recipeIcons
end

--- Make a new item Icons from the reference item Icons and the quality involved.
---@param copyItemIcons data.IconData[]
---@param quality data.QualityPrototype
---@return data.IconData[]
Icons.MakeQualityLabelledIcons = function(copyItemIcons, quality)
    local recipeIcons = copyItemIcons ---@type data.IconData[]
    local fromQualityIcons = Utility.MakeIconsCopyFromIconOrIcons(quality.icon, quality.icon_size, quality.icons)

    Icons.AddSmallIconsToCornerOfIcons(copyItemIcons, fromQualityIcons, qualityIconScaleModifier, -1, 1)

    return recipeIcons
end

--- Place a set of icons in the corner of another icon array at a reduced size.
---@param baseIcons data.IconData[]
---@param cornerIcons data.IconData[]
---@param cornerIconScaleModifier double
---@param cornerXDirection -1|1 # Offset direction from the center of base image.
---@param cornerYDirection -1|1 # Offset direction from the center of base image.
Icons.AddSmallIconsToCornerOfIcons = function(baseIcons, cornerIcons, cornerIconScaleModifier, cornerXDirection, cornerYDirection)
    -- Done on the basis the IconData is 64. Unsure how icons of other sizes behave with shift. Deal with if anything is found to have issues. I suspect I'd need to check each icon in the array and find the largest one to work out the overall size.
    local iconSize = 64
    local defaultIconScale = 0.5 -- Default scale of Space Age seems to be 0.5 and not 1.
    -- Shift over half the base image size to the edge of the image, and then back half the smaller quality image size. I suspect a lot of these sizes and scales could vary for modded items, but see if anything breaks.
    local qualityShiftX64 = ((iconSize * defaultIconScale) / 2) - math.floor(((iconSize * defaultIconScale) * cornerIconScaleModifier) / 2)
    local qualityShiftY64 = ((iconSize * defaultIconScale) / 2) - math.floor(((iconSize * defaultIconScale) * cornerIconScaleModifier) / 2)

    for _, iconData in pairs(cornerIcons) do
        iconData.scale = (iconData.scale ~= nil and iconData.scale or defaultIconScale) * cornerIconScaleModifier
        iconData.shift = {
            x = (iconData.shift ~= nil and iconData.shift.x ~= nil and iconData.shift.x or 0) + (cornerXDirection * qualityShiftX64),
            y = (iconData.shift ~= nil and iconData.shift.y ~= nil and iconData.shift.y or 0) + (cornerYDirection * qualityShiftY64)
        }
        baseIcons[#baseIcons + 1] = iconData
    end
end

return Icons
