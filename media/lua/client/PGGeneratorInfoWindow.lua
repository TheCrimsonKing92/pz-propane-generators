local generatorUtil = require("PGGeneratorUtils");
local GENERATOR_TYPES = generatorUtil.GENERATOR_TYPES
local getName = generatorUtil.getName
local isDualFuel = generatorUtil.isDualFuel
local isGeneratorType = generatorUtil.isGeneratorType
local isModded = generatorUtil.isModded
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
    
    if not isModded(object) or isGeneratorType(object, GENERATOR_TYPES.Gas) then
        return
    end

    self.object = object;
    self.panel:setName(getName(object))
    -- Theoretically when we set the sprite on the generator it should pass the name through getTextureName()
    -- Might be a timing issue on our end
    self.panel:setTexture(object:getSpriteName())
    self.fuel = object:getFuel()
    self.condition = object:getCondition()
end

local originalUpdate = ISGeneratorInfoWindow.update

function ISGeneratorInfoWindow:update()
    originalUpdate(self)

    if not isModded(self.object) or not isDualFuel(self.object) then
        return
    end

    self.panel.description = ISGeneratorInfoWindow.getRichText(self.object, true)
    self:setWidth(self.panel:getWidth())
end