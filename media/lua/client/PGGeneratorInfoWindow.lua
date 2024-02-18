local generatorUtil = require("PGGeneratorUtils");
local isDualFuel = generatorUtil.isDualFuel;
local usesGas = generatorUtil.usesGas;

local function log(...)
    print('[Propane Generators (PGGeneratorInfoWindow.lua)]: ', ...)
end

local function getName(generator)
    if usesGas(generator) then
        return getText("IGUI_Generator_TypeGas")
    end

    -- TODO Replace with getText calls to set up for translation
    if not isDualFuel(generator) then
        return generator:getModData().generatorType .. ' Generator'
    else
        local friendlyName = 'Dual-Fuel Generator'
        local setting = '(' .. generator:getModData().dualFuelSetting .. ' Selected)'
        return friendlyName .. setting
    end
end

local originalGetRichText = ISGeneratorInfoWindow.getRichText

function ISGeneratorInfoWindow.getRichText(object, displayStats)
    local originalText = originalGetRichText(object, displayStats)

    -- Fairly uninvasive for these cases, but...
    if usesGas(object) and not isDualFuel(object) then
        return originalText
    end

    -- We are forced to prepend or append the Dual-Fuel setting
    -- (and it might look better interspersed, perhaps before the fuel amount)
    local modData = object:getModData()
    local generatorType = modData.generatorType
    local fuelType = string.lower(modData.dualFuelSetting)
    -- TODO Replace with getText calls
    return text .. " <LINE>Currently set to use " .. fuelType .. " fuel."
end

local originalSetObject = ISGeneratorInfoWindow.setObject

function ISGeneratorInfoWindow:setObject(object)
    log('Setting generator object for info window')
    originalSetObject(self, object)

    if usesGas(object) then
        return
    end

    self.object = object;
    self.panel:setName(getName(object))
    self.panel:setTexture(object:getTextureName())
    self.fuel = object:getFuel()
    self.condition = object:getCondition()
end

log('Modified ISGeneratorInfoWindow')