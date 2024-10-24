--- This returns the items needing a conversion process as they are "base" items.
--- Any recipe that needs a base resource (ores) or ONLY fluid(s) needs one.

--TODO: add mod option for "Refinement Point". Options of "Minimal Processed Items" with code below. Also add an "Ore" option that just allows raw ore refinement and this would avoid all of the messyness. Also an "All Items" option to allow for every item.

local itemNamesNeedingConversion = {} ---@type table<string, string>
local targettedItemIngredients = {} ---@type table<string, string>
local targettedFluidIngredients = {} ---@type table<string, string>

-- Record the ingredients in recipes that would lead to issues.
for _, resourcePrototype in pairs(data.raw["resource"]) do
    targettedItemIngredients[resourcePrototype.name] = resourcePrototype.name
end
for _, fluidPrototype in pairs(data.raw["fluid"]) do
    targettedFluidIngredients[fluidPrototype.name] = fluidPrototype.name
end

-- Record the output items from recipes that have the targetted ingredients in them.
for _, recipePrototype in pairs(data.raw["recipe"]) do
    if recipePrototype.parameter then goto continue end

    local problematicRecipe = false
    local hasNonFluidIngredient = false
    local hasFluidIngredient = false
    for _, ingredientEntry in pairs(recipePrototype.ingredients) do
        if ingredientEntry.type == "item" then
            hasNonFluidIngredient = true
            if targettedItemIngredients[ingredientEntry.name] ~= nil then
                problematicRecipe = true
                break
            end
        end
        if ingredientEntry.type == "fluid" and targettedFluidIngredients[ingredientEntry.name] ~= nil then
            hasFluidIngredient = true
        end
    end

    if not problematicRecipe then
        if hasFluidIngredient and not hasNonFluidIngredient then
            -- Only has targetted fluid ingredient and no item ingredients.
            problematicRecipe = true
        end
    end

    if problematicRecipe then
        for _, result in pairs(recipePrototype.results) do
            -- Check that the output is an item and not a resource.
            -- We can't filter out any redundant items when there are multiple recipes as they're only redundant if the recipes are unlocked in a specific order. Metal casting recipes are redundant if starting on Nauvis, but not if starting on Vulcanus.
            -- Scrap recycling also pollutes this list, but again if starting on the planet then we don't craft it's output items from lower ingredients.
            if result.type == "item" and targettedItemIngredients[result.name] == nil then
                local itemName = result.name
                itemNamesNeedingConversion[itemName] = itemName
            end
        end
    end

    ::continue::
end

return itemNamesNeedingConversion
