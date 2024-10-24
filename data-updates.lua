local Utility = require("utility")

-- TODO: do conversion recipe and item categories.
-- TODO: tie conversion recipes into related base game item unlock techs.
-- TODO: add different tiers of machine based on quality modules and have them get productivity on outputs. Also add recipes and items for machines. Tie into core game technologies.

------------------------------------
---     Do some setup of reference data.
------------------------------------

local minQualityPrototype ---@type data.QualityPrototype
local minQualityLevel = 99999999
for _, qualityPrototype in pairs(data.raw["quality"]) do
    if qualityPrototype.next == nil then goto continue end
    if qualityPrototype.level < minQualityLevel then
        minQualityPrototype = qualityPrototype
        minQualityLevel = qualityPrototype.level
    end
    ::continue::
end

-- A sorted list of each quality prototype from lowest to highest level. Can't assume what the first level is though and the levels can be gappy, but the list isn't.
---@type data.QualityPrototype[]
local qualityPrototypesSortedByOrder = {}
local thisQuality = minQualityPrototype
while thisQuality ~= nil do
    qualityPrototypesSortedByOrder[#qualityPrototypesSortedByOrder + 1] = thisQuality
    thisQuality = data.raw["quality"][thisQuality.next] --[[@as data.QualityPrototype?]]
end

local maxQualityLevel = qualityPrototypesSortedByOrder[#qualityPrototypesSortedByOrder].level

local itemNamesNeedingConversion = require("data-updates.ItemNamesNeedingConversion")


------------------------------------
---     Make conversion machines to increase the quality of items.
------------------------------------

---@param fromQualityName string
---@param fromOrder int
---@param toQualityName string
---@param toOrder int
local function CreateQualityConversionMachinesForQuality(fromQualityName, fromOrder, toQualityName, toOrder)
    local recipeCategory = "craftable_quality-conversion_quality_from-" .. fromQualityName

    local conversionSmeltingRecipeCategory = {
        type = "recipe-category",
        name = recipeCategory
    }

    local assemblingMachineConversionPrototype = Utility.DeepCopy(data.raw["assembling-machine"]["assembling-machine-3"]) ---@type data.AssemblingMachinePrototype
    assemblingMachineConversionPrototype.name = "craftable_quality-assembling-machine-conversion_quality_from-" .. fromQualityName
    assemblingMachineConversionPrototype.localised_name = { "entity-name.craftable_quality-assembling-machine-conversion_quality_from-QUALITY", fromQualityName, toQualityName }
    assemblingMachineConversionPrototype.localised_description = { "entity-description.craftable_quality-assembling-machine-conversion_quality_from-QUALITY", fromQualityName, toQualityName }
    assemblingMachineConversionPrototype.allowed_effects = {} -- Don't allow anything to keep it balanced to quality modules in a real machine.
    assemblingMachineConversionPrototype.module_slots = 0
    assemblingMachineConversionPrototype.crafting_categories = { recipeCategory }
    assemblingMachineConversionPrototype.fixed_quality = fromQualityName
    assemblingMachineConversionPrototype.order = "craftable_quality-assembling-machine-" .. fromOrder

    data:extend({
        conversionSmeltingRecipeCategory,
        assemblingMachineConversionPrototype
    })
end

-- Make machines for each quality other than the highest quality.
for i = 1, #qualityPrototypesSortedByOrder - 1 do
    local thisQualityPrototype, nextQualityPrototype = qualityPrototypesSortedByOrder[i], qualityPrototypesSortedByOrder[i + 1]
    CreateQualityConversionMachinesForQuality(thisQualityPrototype.name, i, nextQualityPrototype.name, i + 1)
end




------------------------------------
---     Make the lowest sequence items have craftable quality versions.
------------------------------------

-- TODO: work out a proper value for this based on random quality game cost.
local QualityCost = 10

---@param itemName string
---@param fromQualityName string
---@param fromOrder int
---@param toQualityName string
---@param toOrder int
local function CreateQualityRecipeForItemConversion(itemName, fromQualityName, fromOrder, toQualityName, toOrder)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "craftable_quality-" .. itemName .. "-conversion_quality_from-" .. fromQualityName .. "-spoiling_to-" .. toQualityName,
        category = "craftable_quality-conversion_quality_from-" .. fromQualityName,
        energy_required = 1,
        ingredients = { { type = "item", name = itemName, amount = QualityCost } },
        results = {
            { type = "item", name = itemName, amount = 0 }, -- Needed so we have an output slot to insert spoilt items into via script as backup.
            { type = "item", name = "craftable_quality-" .. itemName .. "-conversion_quality-" .. toQualityName, amount = 1 }
        },
        main_product = "craftable_quality-" .. itemName .. "-conversion_quality-" .. toQualityName,
        order = itemName .. "-" .. fromOrder .. "-" .. toOrder
        -- TODO: Make icon autogenerated.
    }
    data:extend({ recipe })
end

---@param itemName string
local function CreateQualityRecipesForItemConversion(itemName)
    -- Make recipes for each starting ingredient quality other than the highest quality.
    for i = 1, #qualityPrototypesSortedByOrder - 1 do
        local thisQualityPrototype, nextQualityPrototype = qualityPrototypesSortedByOrder[i], qualityPrototypesSortedByOrder[i + 1]
        CreateQualityRecipeForItemConversion(itemName, thisQualityPrototype.name, i, nextQualityPrototype.name, i + 1)
    end
end

-- Make recipes for the items that need a conversion process.
for _, itemName in pairs(itemNamesNeedingConversion) do
    CreateQualityRecipesForItemConversion(itemName)
end

---@param itemName string
---@param qualityName string
---@param order int
local function CreateSpoilingItemPrototype(itemName, qualityName, order)
    local refPrototype = data.raw["item"][itemName] or data.raw["capsule"][itemName] or data.raw["ammo"][itemName] or data.raw["rail-planner"][itemName]
    local spoilingItemPrototype = Utility.DeepCopy(refPrototype) --[[@as data.ItemPrototype]]

    if spoilingItemPrototype == nil then
        error("'" .. itemName .. "' isn't an item we can make a spoiling conversion of.")
    end
    spoilingItemPrototype.name = "craftable_quality-" .. itemName .. "-conversion_quality-" .. qualityName
    spoilingItemPrototype.localised_name = { "item-name.craftable_quality-ITEM-conversion_quality-QUALITY", itemName, qualityName }
    spoilingItemPrototype.localised_description = { "item-description.craftable_quality-ITEM-conversion_quality-QUALITY", itemName, qualityName }
    spoilingItemPrototype.order = itemName .. "-" .. order
    spoilingItemPrototype.spoil_ticks = 120 -- Must be greater than recipe craft time as start of recipe crafting is when the timer begins. Also must allow time to be moved to a container to spoil safely. 120 seemed a good value from testing for this.
    spoilingItemPrototype.spoil_to_trigger_result = {
        items_per_trigger = 1,
        trigger = {
            -- The trigger_target_mask conditions have to be inside `nested-result` so that they work correctly in Factorio. Learnt from looking at a demolisher's ash cloud generation. If they are the root objects the trigger_target_mask is ignored and all triggers fire on every entity type.
            {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    source_effects = {
                        {
                            type = "nested-result",
                            action = {
                                -- This works in proper inventories, but not when inside machines or inserters, or on belts or the ground. In those cases the item just vanishes.
                                type = "direct",
                                trigger_target_mask = { "craftable_quality-can_spoil_within" },
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
                                trigger_target_mask = { "craftable_quality-can_not_spoil_within" },
                                filter_enabled = true,
                                ignore_collision_condition = true,
                                action_delivery = {
                                    type = "instant",
                                    source_effects = {
                                        {
                                            type = "script",
                                            effect_id = "craftable_quality-spoilt_out_of_safe_inventory-" .. itemName .. "-conversion_quality-" .. qualityName
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            -- Ideally the below would work if the `nested-result` wasn't needed for some internal Factorio code reason.
            --[[
            {
                -- This works in proper inventories, but not when inside machines or inserters, or on belts or the ground. In those cases the item just vanishes.
                type = "direct",
                trigger_target_mask = { "craftable_quality-can_spoil_within" },
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
                        {
                            -- This is a test effect as its easy to see what is affected by it.
                            type = "damage",
                            damage = { amount = 1, type = "impact" }
                        }
                    }
                }
            },
            {
                -- Catch when not in proper inventories.
                type = "direct",
                trigger_target_mask = { "craftable_quality-can_not_spoil_within" },
                filter_enabled = true,
                ignore_collision_condition = true,
                action_delivery = {
                    type = "instant",
                    source_effects = {
                        {
                            type = "script",
                            effect_id = "craftable_quality-spoilt_out_of_safe_inventory"
                        },
                        {
                            -- This is a test effect as its easy to see what is affected by it.
                            type = "damage",
                            damage = { amount = 10, type = "impact" }
                        }
                    }
                }
            }
            ]]
        }
    }

    data:extend({ spoilingItemPrototype })
end

---@param itemName string
local function CreateSpoilingItemPrototypesForItemName(itemName)
    -- Make items for each output item.
    for i = 2, #qualityPrototypesSortedByOrder do
        local thisQualityPrototype = qualityPrototypesSortedByOrder[i]
        CreateSpoilingItemPrototype(itemName, thisQualityPrototype.name, i)
    end
end

-- Make spoiling items for the items that need a conversion process.
for _, itemName in pairs(itemNamesNeedingConversion) do
    CreateSpoilingItemPrototypesForItemName(itemName)
end



------------------------------------
---     Do the trigger target type settings to detect chests
------------------------------------

data:extend({
    {
        type = "trigger-target-type",
        name = "craftable_quality-can_spoil_within"
    },
    {
        type = "trigger-target-type",
        name = "craftable_quality-can_not_spoil_within"
    }
})

-- Everything our item could be in when it spoils.
for triggerTargetMaskName, entityPrototypeTypeNameArray in pairs({
    ["craftable_quality-can_spoil_within"] = { "container", "character", "infinity-container", "logistic-container", "linked-container", "car", "cargo-wagon", "spider-vehicle" },
    ["craftable_quality-can_not_spoil_within"] = { "assembling-machine", "inserter", "transport-belt", "splitter", "underground-belt", "linked-belt", "loader", "loader-1x1", "construction-robot", "logistic-robot" }
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
