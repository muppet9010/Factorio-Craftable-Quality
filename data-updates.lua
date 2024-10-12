local Utility = require("utility")

local uncommonTest = Utility.DeepCopy(data.raw["assembling-machine"]["assembling-machine-3"]) ---@type data.AssemblingMachinePrototype
uncommonTest.name = "uncommonTest"
uncommonTest.localised_name = "uncommonTest"
uncommonTest.fixed_quality = "uncommon"

data:extend({ uncommonTest })
