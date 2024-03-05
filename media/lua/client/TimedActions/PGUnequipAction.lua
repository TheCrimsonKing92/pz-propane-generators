local generatorUtil = require("PGGeneratorUtils")
local GENERATOR_SPRITES = generatorUtil.GENERATOR_SPRITES
local isGenerator = generatorUtil.isGenerator
local isModded = generatorUtil.isModded
local modVanillaGenerator = generatorUtil.modVanillaGenerator

local function log(...)
    print('[Propane Generators (PGUnequipAction.lua)]: ', ...)
end

local originalPerform = ISUnequipAction.perform

function ISUnequipAction:perform()
    local fullType = self.item:getFullType()

    if not ("PropaneGenerators.PropaneGenerator" == fullType or
       "PropaneGenerators.DualFuelGenerator" == fullType) then
        originalPerform(self)

        if "Base.Generator" == fullType then
            if not isModded(self.item) then
                -- While it's pointless to take over every generator, we don't want to constantly flip types when one is dropped
                modVanillaGenerator(self.item)
            end
        end
        return
    end

    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
    end

    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
    self.character:removeWornItem(self.item)

    if self.item == self.character:getPrimaryHandItem() then
        if (self.item:isTwoHandWeapon() or self.item:isRequiresEquippedBothHands()) and self.item == self.character:getSecondaryHandItem() then
            self.character:setSecondaryHandItem(nil);
        end
		self.character:setPrimaryHandItem(nil);
    end
    if self.item == self.character:getSecondaryHandItem() then
        if (self.item:isTwoHandWeapon() or self.item:isRequiresEquippedBothHands()) and self.item == self.character:getPrimaryHandItem() then
            self.character:setPrimaryHandItem(nil);
        end
		self.character:setSecondaryHandItem(nil);
    end

	triggerEvent("OnClothingUpdated", self.character)

	if isForceDropHeavyItem(self.item) then
		self.character:getInventory():Remove(self.item);
		-- The problem with AddWorldInventoryItem is that it looks for .Generator
        -- But the whole point of our mod is to have other kinds of generators
        -- So the "new IsoGenerator" part doesn't fire
        local worldItem
        if "PropaneGenerators.PropaneGenerator" == fullType or
        "PropaneGenerators.DualFuelGenerator" == fullType then
            worldItem = IsoGenerator.new(self.item, getWorld():getCell(), self.character:getSquare())
            local wiModData = worldItem:getModData()
            local iiModData = self.item:getModData()

            -- LuaManager.copyTable(worldItem:getModData(), self.item:getModData())

            for k,v in pairs(iiModData) do
                wiModData[k] = v
            end

            if "PropaneGenerators.PropaneGenerator" == fullType then
                worldItem:setSprite(GENERATOR_SPRITES.Propane)
            else
                worldItem:setSprite(GENERATOR_SPRITES.DualFuel)
            end

            worldItem:transmitModData()
        else
            log("Unknown item fullType " .. fullType)
        end   

        if not worldItem then
            log("Failed to create a worldItem for placement")
        end
	end
	ISInventoryPage.renderDirty = true

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end