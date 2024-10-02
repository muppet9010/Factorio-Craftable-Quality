local lightBrightness = tonumber(settings.startup["electric_pole_free_light-light_brightness"].value) --[[@as double # 0-1]] ---@type double
local poweredAreaLightedMultiplier = tonumber(settings.startup["electric_pole_free_light-power_pole_powered_area_lighted_percent"].value) / 100
local connectionReachLightedMultiplier = tonumber(settings.startup["electric_pole_free_light-power_pole_connection_reach_lighted_percent"].value) / 100

for _, electricPolePrototype in pairs(data.raw["electric-pole"]) do
    local lightedAreaDistance, lightedReachDistance = 0, 0
    local powerPole_supplyAreaDistance = electricPolePrototype.supply_area_distance
    if poweredAreaLightedMultiplier > 0 and powerPole_supplyAreaDistance > 0 then
        -- The supply_area_distance is the diameter from the power pole.
        lightedAreaDistance = math.ceil(powerPole_supplyAreaDistance * poweredAreaLightedMultiplier)
    end
    local maxWireDistance = electricPolePrototype.maximum_wire_distance
    if connectionReachLightedMultiplier > 0 and maxWireDistance > 0 then
        -- The max_wire_distance is the distance between 2 power poles, so it's double the radius of any single power pole.
        lightedReachDistance = math.ceil((maxWireDistance * 0.5) * connectionReachLightedMultiplier)
    end
    -- The light size is the diameter, centered on the power pole.
    local lightedDistance = math.max(lightedAreaDistance, lightedReachDistance)

    if lightedDistance > 0 then
        lightedDistance = math.min(lightedDistance, 75) -- Max lighted tile area of 75 is a Factorio draw limitation (Factorio 1.1).
        local lightRange = lightedDistance * 5 -- Set the light value to cover the tiles required.
        -- NOTE: This can't handle quality as that's a runtime value of the prototype instance.
        electricPolePrototype.light = { intensity = lightBrightness, size = lightRange, color = { r = 1.0, g = 1.0, b = 1.0 } }
    end
end
