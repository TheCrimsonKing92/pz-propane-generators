require "TimedActions/ISBaseTimedAction"
local generatorUtil = require("PGGeneratorUtils")
local changeFuelSetting = generatorUtil.changeFuelSetting
local isDualFuel = generatorUtil.isDualFuel
local isDualFuelSetTo = generatorUtil.isDualFuelSetTo

PGChangeGeneratorFuel = ISBaseTimedAction:derive("PGChangeGeneratorFuel")

local function log(...)
    print('[Propane Generators (PGChangeGeneratorFuel.lua)]: ', ...)
end

function PGChangeGeneratorFuel:isValid()
    if self.generator:getCondition() <= 0 or not isDualFuel(self.generator) then
        return false
    end

    if isDualFuelSetTo(self.generator, self.otherFuel) then
        log('Given generator is already set to use ' .. self.otherFuel)
        return false
    end

    return self.generator:getObjectIndex() ~= -1
end

function PGChangeGeneratorFuel:waitToStart()
    self.character:faceThisObject(self.generator)
    return self.character:shouldBeTurning()
end

function PGChangeGeneratorFuel:update()
    self.character:faceThisObject(self.generator)
end

function PGChangeGeneratorFuel:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function PGChangeGeneratorFuel:stop()
    ISBaseTimedAction.stop(self)
end

function PGChangeGeneratorFuel:perform()
    changeFuelSetting(self.generator, self.otherFuel)

    ISBaseTimedAction.perform(self)
end

function PGChangeGeneratorFuel:new(player, generator, otherFuel)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = getSpecificPlayer(player)
    o.generator = generator
    o.otherFuel = otherFuel
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    if o.character:isTimedActionInstant() then
        o.maxTime = 1
    end
    
    return o
end