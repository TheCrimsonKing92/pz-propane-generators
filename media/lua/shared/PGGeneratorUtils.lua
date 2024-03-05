local generatorUtils = {};

local function log(...)
    print('[Propane Generators (PGGeneratorUtils.lua)]: ', ...)
end

local function getWeightedRandom(probabilityTable)
    local p = ZombRandFloat(0, 1)
    local cumulativeProbability = 0
    for hitRegion, probability in pairs(probabilityTable) do
        cumulativeProbability = cumulativeProbability + probability
        if p <= cumulativeProbability then
            return hitRegion
        end
    end
end

generatorUtils.GENERATOR_TYPES = {
    Gas = 'Gas',
    Propane = 'Propane',
    DualFuel = 'Dual-Fuel'
}

local GENERATOR_TYPES = generatorUtils.GENERATOR_TYPES

generatorUtils.GENERATOR_PROBABILITIES = {
    Gas = 7 / 20,
    Propane = 9 / 20,
    DualFuel = 4 / 20
}

local GENERATOR_PROBABILITIES = generatorUtils.GENERATOR_PROBABILITIES

generatorUtils.GENERATOR_SPRITES = {
    Propane = "generator_propane_0",
    DualFuel = "generator_dual-fuel_0"
}

local GENERATOR_SPRITES = generatorUtils.GENERATOR_SPRITES

generatorUtils.DUAL_FUEL_SETTINGS = {
    Gas = GENERATOR_TYPES.Gas,
    Propane = GENERATOR_TYPES.Propane
}

local DUAL_FUEL_SETTINGS = generatorUtils.DUAL_FUEL_SETTINGS

generatorUtils.DUAL_FUEL_PROBABILITIES = {
    Gas = 3 / 10,
    Propane = 7 / 10
}

local DUAL_FUEL_PROBABILITIES = generatorUtils.DUAL_FUEL_PROBABILITIES

local function log(...)
    print('[Propane Generators (PGGeneratorUtils.lua)]: ', ...)
end

generatorUtils.changeFuelSetting = function(generator, fuelType)
    local currentType = generator:getModData().dualFuelSetting
    local currentFuel = generator:getFuel()
    local nextFuel = nil

    if DUAL_FUEL_SETTINGS.Gas == currentType then
        generator:getModData().gasFuel = currentFuel
        nextFuel = generator:getModData().propaneFuel or 0
    else
        generator:getModData().propaneFuel = currentFuel
        nextFuel = generator:getModData().gasFuel or 0
    end

    generator:setFuel(nextFuel)
    generator:getModData().fuel = nextFuel
    generator:getModData().dualFuelSetting = fuelType
    generator:update()
    generator:transmitModData()
end

generatorUtils.getName = function(generator)
    if not generatorUtils.isModded(generator) or
       generatorUtils.isGeneratorType(generator, GENERATOR_TYPES.Gas) then
        return getText("IGUI_Generator_TypeGas")
    end

    if generatorUtils.isGeneratorType(generator, GENERATOR_TYPES.Propane) then
        return getText("IGUI_Generator_TypePropane")
    end

    local setting = generator:getModData().dualFuelSetting
    return getText("IGUI_Generator_TypeDualFuel", setting)
end

generatorUtils.getNewGeneratorSettings = function()
    local fuel = generatorUtils.getRandomFuelLevel()
    local condition = generatorUtils.getRandomCondition()
    local generatorType = generatorUtils.getRandomGeneratorType()
    local dualFuelSetting = ('DualFuel' == generatorType and generatorUtils.getRandomDualFuelSetting()) or nil
    return fuel, condition, generatorType, dualFuelSetting
end

generatorUtils.getRandomCondition = function()
    -- Generators have a chance to catch on fire at condition <= 20, so we give some buffer
    return ZombRand(40, 100)
end

generatorUtils.getRandomDualFuelSetting = function()
    return getWeightedRandom(DUAL_FUEL_PROBABILITIES)
end

generatorUtils.getRandomFuelLevel = function()
    return ZombRand(0, 100)
end

generatorUtils.getRandomGeneratorType = function()
    return getWeightedRandom(GENERATOR_PROBABILITIES)
end

generatorUtils.isDualFuel = function(generator) 
    return generatorUtils.isModded(generator) and generatorUtils.isGeneratorType(generator, 'DualFuel')
end

generatorUtils.isDualFuelSetTo = function(generator, settingType) 
    return generatorUtils.isModded(generator) and generatorUtils.isGeneratorType(generator, 'DualFuel') and settingType == generator:getModData().dualFuelSetting
end

generatorUtils.isGenerator = function(item)
    if item == nil then
        return false
    end

    local fullType = item:getFullType()

    if "Base.Generator" == fullType then
        return true
    elseif "PropaneGenerators.PropaneGenerator" == fullType then
        return true
    elseif "PropaneGenerators.DualFuelGenerator" == fullType then
        return true
    else
        log("Couldn't identify item with type " .. fullType .. " as a generator")
        return false
    end
end

generatorUtils.isGeneratorType = function(generator, targetType)
    return targetType == generator:getModData().generatorType
end

generatorUtils.isModded = function(generator)
    return generator:getModData().generatorType ~= nil
end

generatorUtils.modNewGenerator = function(generator)
    log('New generator settings --')
    local fuel, condition, generatorType, dualFuelSetting = generatorUtils.getNewGeneratorSettings()
    log('Fuel: ' .. tostring(fuel))
    log('Condition: ' .. tostring(condition))
    log('Generator Type: ' .. generatorType)
    log('Dual-Fuel Setting: ' .. (dualFuelSetting or 'N/A'))
    local gasFuel = 0
    local propaneFuel = 0

    if 'DualFuel' == generatorType then
        if DUAL_FUEL_SETTINGS.Gas == dualFuelSetting then
            gasFuel = fuel
        else
            propaneFuel = fuel
        end

        generator:setSprite(GENERATOR_SPRITES.DualFuel)
        generator:getModData().gasFuel = gasFuel
        generator:getModData().propaneFuel = propaneFuel
    elseif 'Propane' == generatorType then
        generator:setSprite(GENERATOR_SPRITES.Propane)
    end

    generator:setCondition(condition)
    generator:setFuel(fuel)
    generator:update()
    generator:getModData().dualFuelSetting = dualFuelSetting
    generator:getModData().fuel = fuel
    generator:getModData().generatorType = generatorType
    generator:transmitCompleteItemToServer()
    generator:transmitModData()
end

generatorUtils.modVanillaGenerator = function(generator)
    generator:getModData().generatorType = GENERATOR_TYPES.Gas
    generator:transmitModData()
end

generatorUtils.usesGas = function(generator)
    if not generatorUtils.isModded(generator) then
        return true
    end

    local gas = GENERATOR_TYPES.Gas

    return generatorUtils.isGeneratorType(generator, gas) or generatorUtils.isDualFuelSetTo(generator, gas)
end

generatorUtils.usesPropane = function(generator)
    if not generatorUtils.isModded(generator) then
        return false
    end

    local propane = GENERATOR_TYPES.Propane

    return generatorUtils.isGeneratorType(generator, propane) or generatorUtils.isDualFuelSetTo(generator, propane)
end

return generatorUtils;