local generatorUtil = require("PGGeneratorUtils");
local getName = generatorUtil.getName
local isDualFuel = generatorUtil.isDualFuel
local usesGas = generatorUtil.usesGas
local usesPropane = generatorUtil.usesPropane

local function log(...)
    print('[Propane Generators (PGGeneratorInfoWindow.lua)]: ', ...)
end

local originalGetRichText = ISGeneratorInfoWindow.getRichText

function ISGeneratorInfoWindow.getRichText(object, displayStats)
    local originalText = originalGetRichText(object, displayStats)

    -- Fairly uninvasive for these cases, but...
    if not isDualFuel(object) or usesGas(object) then
        return originalText
    end

    -- TODO Reevaluate for propane use case
    if usesPropane(object) and not isDualFuel(object) then
        return originalText
    end

    -- We are forced to prepend or append the Dual-Fuel setting
    -- (and it might look better interspersed, perhaps before the fuel amount)
    local modData = object:getModData()
    local generatorType = modData.generatorType
    local fuelType = string.lower(modData.dualFuelSetting)
    -- TODO Replace with getText calls
    return "<LINE>Currently set to use " .. fuelType .. " fuel.<LINE>" .. originalText
end

local originalSetObject = ISGeneratorInfoWindow.setObject

function ISGeneratorInfoWindow:setObject(object)
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

local originalUpdate = ISGeneratorInfoWindow.update

function ISGeneratorInfoWindow:update()
    originalUpdate(self)

    if usesGas(self.object) then
        return
    end

    self.panel.description = ISGeneratorInfoWindow.getRichText(self.object, true)
    self:setWidth(self.panel:getWidth())
end