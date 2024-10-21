local Utility = require("utility")

local SpoilingItem = {}

--- Triggered when a conversion item spoils outside of a container that the trigger can insert the new item into via prototype code.
---@param eventData EventData.on_script_trigger_effect
SpoilingItem.OnSpoiltOutOfSafeInventoryScriptTriggerEvent = function(eventData)
    local spoiltUnsafelyStartIndex, spoiltUnsafelyEndIndex = string.find(eventData.effect_id, "craftable_quality-spoilt_out_of_safe_inventory-", 0, true)
    local spoiltItemName = string.sub(eventData.effect_id, spoiltUnsafelyEndIndex + 1)
    local itemQualitySplitterStart, itemQualitySplitterEnd = string.find(spoiltItemName, "!!!", 0, true)
    local itemName = string.sub(spoiltItemName, 0, itemQualitySplitterStart - 1)
    local qualityName = string.sub(spoiltItemName, itemQualitySplitterEnd + 1)

    local holdingEntity = eventData.source_entity
    if holdingEntity ~= nil then
        -- Was in an inventory of some type, but that inventory type can't handle a trigger trying to `insert` the new item into it, e.g. assembling machine output inventory slot or on a belt.
        local holdingEntityType = holdingEntity.type
        if holdingEntityType == "inserter" then
            local heldStack = holdingEntity.held_stack
            if not heldStack.valid_for_read then
                heldStack.set_stack({ name = itemName, quality = qualityName, count = 1 } --[[@as ItemStackDefinition]])
            else
                heldStack.count = heldStack.count + 1
            end
        elseif holdingEntityType == "transport-belt" then
            -- TODO: this will place the item back onto the belt on either side. Do a check on both belt lanes to see if either have this item and quality on them (or the pre-spoilt item) and add to that lane specifically.
            -- TODO: detect if the items are stacked on the belt already. ANd then make stacks to match, as we get separate trigger events or each item in a stack and so don't know what shape it came from.
        elseif holdingEntityType == "assembling-machine" then
            local inventory = holdingEntity.get_inventory(defines.inventory.assembling_machine_output)
            if inventory == nil then
                Utility.PrintError("assembling-machine failed to accept new spoilt item: " .. Utility.MakeGpsString(eventData.source_position, eventData.surface_index))
                return
            end
            inventory.insert({ name = itemName, quality = qualityName, count = 1 } --[[@as ItemStackDefinition]])
        else
            Utility.PrintError(qualityName .. " " .. itemName .. " spoilt in unhandled situation: " .. Utility.MakeGpsString(eventData.source_position, eventData.surface_index))
        end
    else
        -- Was on the ground or in an unhandled inventory. This includes: player's editor mode inventory (no character).
        game.surfaces[eventData.surface_index].spill_item_stack({ position = eventData.source_position, stack = { name = itemName, quality = qualityName, count = 1 } --[[@as ItemStackDefinition]], allow_belts = false, max_radius = 10 })
    end
end

return SpoilingItem
