local generatorUtils = {};

local function log(...)
    print('[Propane Generators (PGGeneratorInfoWindow.lua)]: ', ...)
end

local function getRandom(table)
    -- With input n, generates a random int from 1 to n inclusive
    return table[math.random(#table)]
end

local function getWeightedRandom(probabilityTable)
    -- [0, 1) generation range
    local p = math.random()
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
    Gas = 5 / 10,
    Propane = 4 / 10,
    DualFuel = 1 / 10
}

local GENERATOR_PROBABILITIES = generatorUtils.GENERATOR_PROBABILITIES

generatorUtils.DUAL_FUEL_SETTINGS = {
    Gas = GENERATOR_TYPES.Gas,
    Propane = GENERATOR_TYPES.Propane
}

local function log(...)
    print('[Propane Generators (PGGeneratorUtils.lua)]: ', ...)
end

generatorUtils.getRandomDualFuelSetting = function()
    return getRandom(DUAL_FUEL_SETTINGS)
end


generatorUtils.getRandomDualFuelSetting = function()
    return getRandom(DUAL_FUEL_SETTINGS)
end

generatorUtils.getRandomGeneratorType = function()
    return getWeightedRandom(GENERATOR_PROBABILITIES)
end

generatorUtils.isDualFuel = function(generator) 
    return generatorUtils.isModded(generator) and generatorUtils.isGeneratorType(generator, GENERATOR_TYPES.DualFuel)
end

generatorUtils.isDualFuelSetTo = function(generator, settingType) 
    return generatorUtils.isModded(generator) and generatorUtils.isGeneratorType(generator, GENERATOR_TYPES.DualFuel) and settingType == generator:getModData().dualFuelSetting
end

generatorUtils.isGeneratorType = function(generator, targetType)
    return targetType == generator:getModDate().generatorType
end

generatorUtils.isModded = function(generator) 
    local modData = generator:getModData();

    return modData.generatorType ~= nil;
end

generatorUtils.usesGas = function(generator)
    log('Checking if generator uses gas...')
    if not generatorUtils.isModded(generator) then
        log('Generator is not modded, uses gas by default')
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