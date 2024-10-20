local Utility = require("utility")


--[[
local testUncommonAssembler = Utility.DeepCopy(data.raw["assembling-machine"]["assembling-machine-3"]) ---@type data.AssemblingMachinePrototype
testUncommonAssembler.name = "testUncommonAssembler"
testUncommonAssembler.localised_name = "testUncommonAssembler"
testUncommonAssembler.fixed_quality = "uncommon"
data:extend({testUncommonAssembler})
]]



------------------------------------
---     Make all the qualities be 100% likely and not increase to the next quality.
------------------------------------
--[[
for _, qualityPrototype in pairs(data.raw["quality"]) do
    qualityPrototype.next_probability = 0
end

for _, modulePrototype in pairs(data.raw["module"]) do
    if modulePrototype.category ~= "quality" then goto continue end
    modulePrototype.effect.quality = 10.0
    ::continue::
end
--]]


------------------------------------
---     Make conversion machines to increase the quality of items.
------------------------------------

local conversionSmeltingRecipeCategory = {
    type = "recipe-category",
    name = "craftable_quality-conversion-quality"
}

-- TODO: these need to be dynamic generated for the quality types in the game (supporting modded added ones).
local assemblingMachineUncommonConversionPrototype = Utility.DeepCopy(data.raw["assembling-machine"]["assembling-machine-3"]) ---@type data.AssemblingMachinePrototype
assemblingMachineUncommonConversionPrototype.name = "craftable_quality-assembling-machine-uncommon-conversion"
assemblingMachineUncommonConversionPrototype.localised_name = "assembling-machine-uncommon-conversion"
--assemblingMachineUncommonConversionPrototype.fixed_quality = "uncommon"
assemblingMachineUncommonConversionPrototype.allowed_effects = {} -- Don't allow anything to keep it balanced to quality modules in a real machine.
assemblingMachineUncommonConversionPrototype.module_slots = 0
assemblingMachineUncommonConversionPrototype.crafting_categories = { "craftable_quality-conversion-quality" }
--[[assemblingMachineUncommonConversionPrototype.effect_receiver = {
    base_effect = {
        quality = 10.0
    }
}]]

data:extend({
    conversionSmeltingRecipeCategory,
    assemblingMachineUncommonConversionPrototype
})




------------------------------------
---     Make the lowest level items have craftable quality versions.
------------------------------------

-- TODO: work out a proper value for this based on base game cost.
local qualityLevelCost = 10

---@param itemName string
---@param qualityName string
local function CreateQualityRecipeForItemConversionToLevel(itemName, qualityName)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "craftable_quality-" .. itemName .. "-conversion-quality-" .. qualityName,
        category = "craftable_quality-conversion-quality",
        energy_required = 1,
        ingredients = { { type = "item", name = itemName, amount = qualityLevelCost } },
        results = {
            { type = "item", name = "craftable_quality-" .. itemName .. "-" .. qualityName, amount = 1 }
        }
    }
    data:extend({ recipe })
end

---@param itemName string
local function CreateQualityRecipesForItemConversion(itemName)
    -- TODO: Hardcoded base game quality numbers. Get from prototypes to support other mods.
    CreateQualityRecipeForItemConversionToLevel("iron-plate", "uncommon")
end

-- TODO: make this be procedural, but just hardcode examples for now.
local itemNames = { "iron-plate" }
for _, itemName in pairs(itemNames) do
    CreateQualityRecipesForItemConversion(itemName)
end

-- Test item for spoilage test.
---@param itemName string
---@param qualityName string
local function CreateSpoilingItemPrototype(itemName, qualityName)
    local spoilingItemPrototype = Utility.DeepCopy(data.raw["item"][itemName]) --[[@as data.ItemPrototype]]
    spoilingItemPrototype.name = "craftable_quality-" .. itemName .. "-" .. qualityName
    spoilingItemPrototype.localised_name = itemName .. "-" .. qualityName
    spoilingItemPrototype.spoil_ticks = 120 -- TODO: Must be greater than recipe craft time as start of recipe crafting is when the timer begins. Also must allow time to be moved to a container to spoil safely.
    spoilingItemPrototype.spoil_to_trigger_result = {
        items_per_trigger = 1,
        trigger = {
            {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    source_effects = {
                        -- These have to be in `nested-result` so that the trigger_target_mask's work correctly. If they are the root objects the trigger_target_mask is ignored and they fire on every entity type.
                        {
                            type = "nested-result",
                            action = {
                                -- This works in proper inventories, but not when inside machines or inserters, or on belts or the ground. In those cases the item just vanishes.
                                type = "direct",
                                trigger_target_mask = { "craftable_quality-chest" },
                                filter_enabled = true,
                                ignore_collision_condition = true,
                                action_delivery = {
                                    type = "instant",
                                    source_effects = {
                                        {
                                            type = "insert-item",
                                            item = itemName,
                                            quality = qualityName,
                                            count = 1
                                        },
                                        --[[{
                                            -- This is a test effect as its easy to see what is affected by it.
                                            type = "damage",
                                            damage = { amount = 1, type = "impact" }
                                        }]]
                                    }
                                }
                            }
                        },
                        {
                            type = "nested-result",
                            action = {
                                -- Catch when not in proper inventories.
                                type = "direct",
                                trigger_target_mask = { "craftable_quality-non_chest" },
                                filter_enabled = true,
                                ignore_collision_condition = true,
                                action_delivery = {
                                    type = "instant",
                                    source_effects = {
                                        {
                                            type = "script",
                                            effect_id = "craftable_quality-spoilt_out_of_chest"
                                        },
                                        --[[{
                                                -- This is a test effect as its easy to see what is affected by it.
                                                type = "damage",
                                                damage = { amount = 10, type = "impact" }
                                        }]]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    data:extend({ spoilingItemPrototype })
end

CreateSpoilingItemPrototype("iron-plate", "uncommon")




------------------------------------
---     Do the trigger target type settings to detect chests
------------------------------------

data:extend({
    {
        type = "trigger-target-type",
        name = "craftable_quality-chest"
    },
    {
        type = "trigger-target-type",
        name = "craftable_quality-non_chest"
    }
})

-- Everything our item could be in when it spoils.
-- TODO: these lists need expanding more.
for triggerTargetMaskName, entityPrototypeTypeNameArray in pairs({
    ["craftable_quality-chest"] = { "container", "character", "infinity-container" },
    ["craftable_quality-non_chest"] = { "transport-belt", "furnace", "assembling-machine", "inserter" }
}) do
    for _, entityPrototypeTypeName in pairs(entityPrototypeTypeNameArray) do
        local entityPrototypes = data.raw[entityPrototypeTypeName] --[[@as data.EntityWithOwnerPrototype[] ]]
        for _, entityPrototype in pairs(entityPrototypes) do
            if entityPrototype.trigger_target_mask == nil then
                entityPrototype.trigger_target_mask = data.raw["utility-constants"]["default"]["default_trigger_target_mask_by_type"][entityPrototype.type] or { "common" }
            end
            entityPrototype.trigger_target_mask[#entityPrototype.trigger_target_mask + 1] = triggerTargetMaskName
        end
    end
end
