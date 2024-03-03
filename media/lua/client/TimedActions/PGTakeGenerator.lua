local generatorUtil = require("PGGeneratorUtils");
local isGeneratorType = generatorUtil.isGeneratorType
local isModded = generatorUtil.isModded
local GENERATOR_TYPES = generatorUtil.GENERATOR_TYPES

local originalPerform = ISTakeGenerator.perform
function ISTakeGenerator:perform()
    local generator = self.generator

    if not isModded(generator) or isGeneratorType(generator, GENERATOR_TYPES.Gas) then
        originalPerform(self)
        return
    end

    forceDropHeavyItems(self.character)

    local newItemType

    if isGeneratorType(generator, GENERATOR_TYPES.Propane) then
        newItemType = "PropaneGenerators.PropaneGenerator"
    else
        newItemType = "PropaneGenerators.DualFuelGenerator"
    end

    local item = self.character:getInventory():AddItem(newItemType)
    item:setCondition(generator:getCondition())
    -- Don't try to set this on the new item. It doesn't have such a field.
    -- item:setFuel(generator:getFuel())
    self.character:setPrimaryHandItem(item)
    self.character:setSecondaryHandItem(item)

    item:copyModData(generator:getModData())    
    item:update()

    self.character:getInventory():setDrawDirty(true)
    generator:remove()

    ISBaseTimedAction.perform(self)
end