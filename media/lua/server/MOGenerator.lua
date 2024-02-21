local generatorUtil = require("PGGeneratorUtils")
local DUAL_FUEL = generatorUtil.GENERATOR_TYPES.DualFuel
local getRandomDualFuelSetting = generatorUtil.getRandomDualFuelSetting
local getRandomGeneratorType = generatorUtil.getRandomGeneratorType

local function log(...)
    print('[Propane Generators (PGMOGenerator.lua)]: ', ...)
end

if isClient() then
    log('Not running this code on the client, returning')
    return
else
    log("Running the code, as we are on the server")
end

local function ReplaceExistingObject(object, generatorType, fuel, condition)
    log('Called to replace existing object')
    local cell = getWorld():getCell()
    log('World cell: ', cell)
    local square = object:getSquare()
    log('Existing object square: ', square)

    local item = InventoryItemFactory.CreateItem("Base.Generator")

    if item == nil then
        log('Failed to create Base.Generator item')
        return
    end

    item:setCondition(condition)
    local modData = item:getModData()
    modData.fuel = fuel
    modData.generatorType = generatorType
    modData.dualFuelSetting = (DUAL_FUEL == generatorType and getRandomDualFuelSetting()) or nil

    log('Generated new Base.Generator item with modData: ', modData);

    square:transmitRemoveItemFromSquare(object)
    log('Original object removal transmitted')

    local javaObject = IsoGenerator.new(item, cell, square)
    log('Got new java object from IsoGenerator constructor')
    javaObject:transmitCompleteItemToClients()
    log('Complete item transmitted ot clients from new java object')
end

local function NewGenerator(object)
    log('Received a new generator object to replace')
    local generatorType = getRandomGeneratorType()
    log('Generated new generator type: ' .. generatorType)
    local fuel = 0
    local condition = 100
    ReplaceExistingObject(object, generatorType, fuel, condition)
end

local PRIORITY = 5

log('Adding NewGenerator function to OnNewWithSprite for appliances_misc_01_0 (original gas generator, babyyyyy)')
MapObjects.OnNewWithSprite("appliances_misc_01_0", NewGenerator, PRIORITY)