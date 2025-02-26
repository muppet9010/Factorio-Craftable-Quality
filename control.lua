local SpoilingItem = require("scripts.spoiling-item")

-- TODO: add button to enable machine recipe reset.
-- TODO: add label in recipe selection screen to warn about setting the ingredient quality to the right option for the machine. See if I can do this on the machine being built or the user opening the recipe selection GUI.

---@param eventData EventData.on_script_trigger_effect
local function OnScriptTriggerEffect(eventData)
    if string.find(eventData.effect_id, "craftable_quality-spoilt_out_of_safe_inventory-", 0, true) ~= nil then
        SpoilingItem.OnSpoiltOutOfSafeInventoryScriptTriggerEvent(eventData)
    end
end

local function CreateGlobals()
end

local function OnLoad()
    -- Any Remote Interface or Command registration calls go in here.
    script.on_event(defines.events.on_script_trigger_effect, OnScriptTriggerEffect)
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
local function OnSettingChanged(event)
    --if event == nil or event.setting == "xxxxx" then
    --	local x = tonumber(settings.global["xxxxx"].value)
    --end
end

local function OnStartup()
    CreateGlobals()
    OnLoad()
    OnSettingChanged(nil)
end





script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_load(OnLoad)

-- Mod wide function interface table creation. Means EmmyLua can support it.
MOD = MOD or {} ---@class MOD
MOD.Interfaces = MOD.Interfaces or {} ---@class MOD_InternalInterfaces
--[[
    Populate and use from within module's OnLoad() functions with simple table reference structures, i.e:
        MOD.Interfaces.Tunnel = MOD.Interfaces.Tunnel or {} ---@class InternalInterfaces_XXXXXX
        MOD.Interfaces.Tunnel.CompleteTunnel = Tunnel.CompleteTunnel
--]]
--
