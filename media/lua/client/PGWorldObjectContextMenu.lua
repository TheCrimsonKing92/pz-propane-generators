local generatorUtil = require("PGGeneratorUtils");
local DUAL_FUEL_SETTINGS = generatorUtil.DUAL_FUEL_SETTINGS
local getName = generatorUtil.getName
local isDualFuel = generatorUtil.isDualFuel
local isModded = generatorUtil.isModded
local modNewGenerator = generatorUtil.modNewGenerator
local usesGas = generatorUtil.usesGas
local usesPropane = generatorUtil.usesPropane

-- This sucks, but it provides a better user experience
-- If we encounter a generator that's not been modded by the OnPlayerMove event, we try to mod it on the spot
-- but we register it here so as not to keep running this backup
PGHackedGenerators = {}

local function log(...)
    print('[Propane Generators (PGWorldObjectContextMenu.lua)]: ', ...)
end

local function isValidPropane(item)
    return "Base.PropaneTank" == item:getFullType() and not item:isBroken() and
            instanceof(item, "DrainableComboItem") and item:getUsedDelta() > 0
end

local function isValidPetrol(item)
    return item:hasTag("Petrol") and not item:isBroken() and
           instanceof(item, "DrainableComboItem") and item:getUsedDelta() > 0
end

ISWorldObjectContextMenu.catchUnmoddedGenerators = function(player, context, worldObjects)
    for _, object in ipairs(worldObjects) do
        if instanceof(object, "IsoGenerator") and not isModded(object) and not PGHackedGenerators[object] then
            modNewGenerator(generator)
            PGHackedGenerators[generator] = true
        end
    end
end

ISWorldObjectContextMenu.findAvailableGeneratorFuel = function(playerInventory, generator)
    local modData = generator:getModData()
    local generatorType = modData.generatorType

    if usesGas(generator) then
        return playerInventory:getAllEvalRecurse(isValidPetrol)
    end

    if usesPropane(generator) then
        return playerInventory:getAllEvalRecurse(isValidPropane)
    end

    log("Couldn't find an applicable generator fuel type for which to search, returning empty ArrayList");    
    return java.util.ArrayList:new()
end

local originalOnAddFuelGenerator = ISWorldObjectContextMenu.onAddFuelGenerator

ISWorldObjectContextMenu.onAddFuelGenerator = function(worldObjects, fuelContainer, generator, player, context)
    if usesGas(generator) then
        originalOnAddFuelGenerator(worldObjects, fuelContainer, generator, player, context)
        return
    end

    local playerObj = getSpecificPlayer(player)
    local playerNum = playerObj:getPlayerNum()
    local playerInv = playerObj:getInventory()
    local allContainers = {}
    local allContainerTypes = {}
    local allContainersOfType = {}
    local pourOut = ISWorldObjectContextMenu.findAvailableGeneratorFuel(playerInv, generator)

    if pourOut:isEmpty() then
        return
    end

    local fillOption = context:insertOptionAfter(getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_GeneratorAddFuel"), worldObjects, nil)

    if not generator:getSquare() or not AdjacentFreeTileFinder.Find(generator:getSquare(), playerObj) then
        fillOption.notAvailable = true
        return
    end

    for i = 0, pourOut:size() - 1 do
        local container = pourOut:get(i)
        table.insert(allContainers, container)
    end

    -- This sort groups identical containers together
    table.sort(allContainers, function(a,b) return not string.sort(a:getName(), b:getName()) end)

    -- Subdivide into table by (container) item type
    local previousContainer = nil;
    for _, container in pairs(allContainers) do
        if previousContainer ~= nil and container:getName() ~= previousContainer:getName() then
            table.insert(allContainerTypes, allContainersOfType)
            allContainersOfType = {}
        end
        table.insert(allContainersOfType, container)
        previousContainer = container
    end
    table.insert(allContainerTypes, allContainersOfType)

    local containerMenu = ISContextMenu:getNew(context)
    local containerOption
    context:addSubMenu(fillOption, containerMenu)

    if pourOut:size() > 1 then
        containerOption = containerMenu:addOption(getText("ContextMenu_AddAll"), worldObjects, ISWorldObjectContextMenu.doAddFuelGenerator, generator, allContainers, nil, playerNum);
    end

    -- Add a sub-menu for each type of container
    for _, containerType in pairs(allContainerTypes) do
        local destItem = containerType[1]

        if #containerType > 1 then
            containerOption = containerMenu:addOption(destItem:getName() .. " (" .. #containerType .. ")", worldObjects, nil);
            local containerTypeMenu = ISContextMenu:getNew(containerMenu)
            containerMenu:addSubMenu(containerOption, containerTypeNew)
            local containerTypeOption
            containerTypeOption = containerTypeMenu:addOption(getText("ContextMenu_AddOne"), worldObjects, ISWorldObjectContextMenu.doAddFuelGenerator, generator, nil, destItem, playerNum)
            if containerType[2] ~= nil then
                containerTypeOption = containerTypeMenu:addOption(getText("ContextMenu_AddAll"), worldObjects, ISWorldObjectContextMenu.doAddFuelGenerator, generator, containerType, nil, playerNum);                
            end
        else
            containerOption = containerMenu:addOption(destItem:getName(), worldObjects, ISWorldObjectContextMenu.doAddFuelGenerator, generator, nil, destItem, playerNum);
            if instanceof(destItem, "DrainableComboItem") then
                local t = ISWorldObjectContextMenu.addToolTip()
                t.maxLineWidth = 512;
                -- Each drainable unit adds 10% to a generator. Original code marked `FIXME: A partial unit also adds 10% to a generator`
                t.description = getText("ContextMenu_FuelCapacity") .. "+" .. math.ceil(destItem:getDrainableUsesFloat() * 10) .. "%"
                containerOption.toolTip = t
            end
        end
    end
end

ISWorldObjectContextMenu.doChangeGeneratorFuel = function(worldObjects, generator, otherFuel, player)
    local playerObj = getSpecificPlayer(player)
    if luautils.walkAdj(playerObj, generator:getSquare()) then
        -- function PGChangeGeneratorFuel:new(player, generator, otherFuel)
        local action = PGChangeGeneratorFuel:new(player, generator, otherFuel)
        ISTimedActionQueue.add(action)
    end
end

---@param player int
---@param context ISContextMenu
ISWorldObjectContextMenu.substituteContextEntries = function(player, context, worldObjects)
    local playerObj = getSpecificPlayer(player)
    local generator = nil
    local hasAddFuel = false
    for i = 1, #context.options do
        local opt = context.options[i]

        if opt.onSelect == ISWorldObjectContextMenu.onInfoGenerator then
            generator = opt.param1
    
            local eligibleForChange = function(generator)
                return isDualFuel(generator) or usesPropane(generator)
            end

            if not eligibleForChange(generator) then
                return
            end
            
            -- I made it work this way, but maybe we could just check if opt.toolTip ~= nil and assume this is true
            if playerObj:DistToSquared(generator:getX() + 0.5, generator:getY() + 0.5) < 2 * 2 then
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName(getName(generator))
                tooltip.description = ISGeneratorInfoWindow.getRichText(generator, true)
                opt.toolTip = tooltip
            end
        elseif opt.name == getText("ContextMenu_GeneratorAddFuel") then
            hasAddFuel = true
        end
    end

    if not hasAddFuel and generator then
        -- Default gas would already have been taken care of
        if usesPropane(generator) then
            local playerInv = playerObj:getInventory()
            local fuelContainer = playerInv:containsEvalRecurse(isValidPropane)
            ISWorldObjectContextMenu.onAddFuelGenerator(worldObjects, fuelContainer, generator, player, context)
        end
    end

    if generator and isDualFuel(generator) then
        local otherType = (usesGas(generator) and DUAL_FUEL_SETTINGS.Propane) or DUAL_FUEL_SETTINGS.Gas
        context:insertOptionAfter(getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_ChangeFuelSetting", otherType), worldObjects, ISWorldObjectContextMenu.doChangeGeneratorFuel, generator, otherType, player)
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.catchUnmoddedGenerators)
Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.substituteContextEntries)