local generatorUtil = require("PGGeneratorUtils")
local isModded = generatorUtil.isModded

local function log(...)
    print('[Propane Generators (PGDropWorldItemAction.lua)]: ', ...)
end

local originalOnPerform = ISDropWorldItemAction.perform

function ISDropWorldItemAction:perform()
    local item = self.item
    local fullType = item:getFullType()

    -- Leave other items and vanilla generators alone
    if "Base.Generator" == fullType or not luautils.stringEnds(fullType, "Generator") then
        originalOnPerform(self)
        return
    end

	if self.sound then
		local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.character)
		local nextAction = actionQueue.queue[2]
		if not nextAction or (nextAction.Type ~= ISDropWorldItemAction.Type) or (nextAction.item:getFullType() ~= self.item:getFullType()) then
			self.character:stopOrTriggerSound(self.sound)
		else
			nextAction.sound = self.sound -- pass it to the next action so it can be stopped
		end
	end

    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);

    -- The problem with AddWorldInventoryItem is that it looks for .Generator
    -- But the whole point of our mod is to have other kinds of generators
    -- So the "new IsoGenerator" part doesn't fire
    if "PropaneGenerators.PropaneGenerator" == fullType then

    elseif "PropaneGenerators.DualFuelGenerator" == fullType then

    else
        log("Unknown item fullType " .. fullType)
    end
end