local generatorUtil = require("PGGeneratorUtils");
local getName = generatorUtil.getName
local isDualFuel = generatorUtil.isDualFuel
local isGeneratorType = generatorUtil.isGeneratorType
local isModded = generatorUtil.isModded
local usesGas = generatorUtil.usesGas
local usesPropane = generatorUtil.usesPropane

local function log(...)
    print('[Propane Generators (PGGeneratorInfoWindow.lua)]: ', ...)
end

local originalGetRichText = ISGeneratorInfoWindow.getRichText

function ISGeneratorInfoWindow.getRichText(object, displayStats)
    local originalText = originalGetRichText(object, displayStats)

    if not isModded(object) or not isDualFuel(generator) or not displayStats then
        return originalText
    end

    local fuelType = string.lower(object:getModData().dualFuelSetting)
    return "<LINE>" .. getText("IGUI_DualFuel_CurrentSetting", fuelType) .. "<LINE>" .. originalText
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