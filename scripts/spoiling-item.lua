local Utility = require("utility")

local SpoilingItem = {}

--- Triggered when a conversion item spoils outside of a container that the trigger can insert the new item into via prototype code.
---@param eventData EventData.on_script_trigger_effect
SpoilingItem.OnSpoiltOutOfSafeInventoryScriptTriggerEvent = function(eventData)
    local _, spoiltUnsafelyEndIndex = string.find(eventData.effect_id, "craftable_quality-spoilt_out_of_safe_inventory-", 0, true)
    local spoiltItemNameInTrigger = string.sub(eventData.effect_id, spoiltUnsafelyEndIndex + 1)
    local itemQualitySplitterStart, itemQualitySplitterEnd = string.find(spoiltItemNameInTrigger, "-conversion_quality-", 0, true)
    local qualityItemsItemName = string.sub(spoiltItemNameInTrigger, 0, itemQualitySplitterStart - 1)
    local qualityItemsQualityName = string.sub(spoiltItemNameInTrigger, itemQualitySplitterEnd + 1)
    local originalItemThatSpoiltName = "craftable_quality-" .. qualityItemsItemName .. "-conversion_quality-" .. qualityItemsQualityName

    local holdingEntity = eventData.source_entity
    local spoiltPosition = eventData.source_position --[[@as MapPosition]]
    local itemStackToPlace = { name = qualityItemsItemName, quality = qualityItemsQualityName, count = 1 } ---@type ItemStackDefinition

    if holdingEntity ~= nil then
        -- Was in an inventory of some type, but that inventory type can't handle a trigger trying to `insert` the new item into it, e.g. assembling machine output inventory slot or on a belt.
        local holdingEntityType = holdingEntity.type
        if holdingEntityType == "inserter" then
            local heldStack = holdingEntity.held_stack
            if not heldStack.valid_for_read then
                heldStack.set_stack(itemStackToPlace)
            else
                heldStack.count = heldStack.count + 1
            end
        elseif holdingEntityType == "transport-belt" or holdingEntityType == "splitter" or holdingEntityType == "underground-belt" or holdingEntityType == "linked-belt" or holdingEntityType == "loader" or holdingEntityType == "loader-1x1" then
            Utility.PrintWarning("Can't safely place the quality item back onto a belt after it spoils, so dropped on the ground instead. Don't put these quality conversion spoiling items on belts, wait for them to spoil into a standard quality item first: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
            game.surfaces[eventData.surface_index].spill_item_stack({ position = spoiltPosition, stack = itemStackToPlace, allow_belts = false, max_radius = 100 })
        elseif "SKIP" ~= "SKIP" and holdingEntityType == "transport-belt" then
            -- FUTURE: detect if the items are stacked on the belt already. And then make stacks to match, as we get separate trigger events or each item in a stack and so don't know what shape it came from.
            -- FUTURE: need to handle spoiling when on undergrounds and also in splitters. Splitters will be awkward as we'd need to spoil on the input side so that any filtering logic can run. Can use LuaEntity.belt_neighbours() to help with splitters.
            -- FUTURE: if belt stacking has been unlocked and is in use we could add our item to an existing item if below the stack size.
            -- FAILURE: this only checks the transport lanes on the current belt entity, not across the full length of connected belts. Need to check the connected belt entities as well. Checking for side loading.
            local itemInsertedOntoBeltLane = false
            for laneIndex = 1, 2 do
                local lane = holdingEntity.get_transport_line(laneIndex)
                for _, itemOnLane in pairs(lane.get_contents()) do
                    if (itemOnLane.name == qualityItemsItemName and itemOnLane.quality == qualityItemsQualityName) or (itemOnLane.name == originalItemThatSpoiltName) then
                        -- Found our desired item on this belt lanes, so add it to this belt lane in its spoilt location.
                        local placementLaneIndexFound, placementLanePositionFound = holdingEntity.get_item_insert_specification(spoiltPosition) -- FUTURE: we are just ignoring what lane it found it on for now to get the position on the line. Probably a bad idea...
                        local itemPlacedSuccessfully = lane.insert_at(placementLanePositionFound, itemStackToPlace, 1)
                        if not itemPlacedSuccessfully then
                            itemPlacedSuccessfully = lane.insert_at_back(itemStackToPlace, 1)
                            if itemPlacedSuccessfully then
                                Utility.PrintWarning("Failed to place quality item on belt after spoiling in same location, so placed at end of belt instead: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
                            else
                                Utility.PrintWarning("Failed to place quality item on belt after spoiling in expected location and also on end of belt, so dropped on the ground instead: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
                                game.surfaces[eventData.surface_index].spill_item_stack({ position = spoiltPosition, stack = itemStackToPlace, allow_belts = false, max_radius = 100 })
                            end
                        end
                        itemInsertedOntoBeltLane = true
                        break
                    end
                end
                if itemInsertedOntoBeltLane then break end
            end

            if not itemInsertedOntoBeltLane then
                Utility.PrintWarning("Failed to find any other quality items on the belt after spoiling and so didn't know where on the belt to place the new quality item, so dropped on the ground instead: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
                game.surfaces[eventData.surface_index].spill_item_stack({ position = spoiltPosition, stack = itemStackToPlace, allow_belts = false, max_radius = 100 })
            end
        elseif holdingEntityType == "assembling-machine" then
            local failed = false
            local inventory = holdingEntity.get_inventory(defines.inventory.assembling_machine_output)
            if inventory ~= nil then
                local insertedCount = inventory.insert(itemStackToPlace)
                if insertedCount == 0 then
                    failed = true
                end
            else
                failed = true
            end
            if failed then
                Utility.PrintError("assembling-machine failed to accept new spoilt item: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
                return
            end
        elseif holdingEntityType == "construction-robot" or holdingEntityType == "logistic-robot" then
            local failed = false
            local inventory = holdingEntity.get_inventory(defines.inventory.robot_cargo)
            if inventory ~= nil then
                local insertedCount = inventory.insert(itemStackToPlace)
                if insertedCount == 0 then
                    failed = true
                end
            else
                failed = true
            end
            if failed then
                Utility.PrintError("assembling-machine failed to accept new spoilt item: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
                return
            end
        else
            Utility.PrintError(qualityItemsQualityName .. " " .. qualityItemsItemName .. " spoilt in unhandled situation: " .. Utility.MakeGpsString(spoiltPosition, eventData.surface_index))
        end
    else
        -- Was on the ground or in an unhandled inventory. This includes: player's editor mode inventory (no character).
        game.surfaces[eventData.surface_index].spill_item_stack({ position = spoiltPosition, stack = itemStackToPlace, allow_belts = false, max_radius = 100 })
    end
end

return SpoilingItem
