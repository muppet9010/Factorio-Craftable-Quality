local SpoilingItem = {}

---@param eventData EventData.on_script_trigger_effect
SpoilingItem.OnScriptTriggerEffect = function(eventData)
    if eventData.source_entity ~= nil then
        -- Was in an inventory of some type, but that inventory type can't handle a trigger trying to `insert` the new item into it, e.g. assembling machine output inventory slot or on a belt.
        game.print(eventData.source_entity.name .. " - " .. game.tick)
        -- TODO
    else
        -- Was on the ground.
        -- TODO
        game.print("ground - " .. game.tick)
    end
end

return SpoilingItem
