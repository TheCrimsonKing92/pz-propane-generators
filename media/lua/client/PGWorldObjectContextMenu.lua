local generatorUtil = require("PGGeneratorUtils");
local isDualFuel = generatorUtil.isDualFuel;
local usesGas = generatorUtil.usesGas;
local usesPropane = generatorUtil.usesPropane;

local function log(...)
    print('[Propane Generators (PGWorldObjectContextMenu.lua)]: ', ...)
end

local function isValidPropane(item)
    return item:getFullType() == 'Base.PropaneTank' and (not item:isBroken()) and instanceof(item, "DrainableComboItem") and item:getUsedDelta() > 0
end

local function isValidPetrol(item)
    return item:hasTag("Petrol") and not item:isBroken() and instanceof(item, "DrainableComboItem") and item:getUsedDelta() > 0
end

function ISWorldObjectContextMenu.findAvailableGeneratorFuel(playerInventory, generator)
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
    local modData = generator:getModData()

    if modData.generatorType == nil or modData.generatorType == 'Gas' then
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

    local fillOption = context:addOption(getText("ContextMenu_GeneratorAddFuel"), worldObjects, nil)

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

--[[
    I think this is actually unnecessary. Since we've modified onAddFuelGenerator, the correct context options should be generated when called by the vanilla code
---@param context ISContextMenu
PGWorldObjectContextMenu.substituteContextEntries = function(player, context)
    for i = 1, #context.options do
        local opt = context.options[i]
        local eligibleForChange = function(generator)
            return isDualFuel(generator) or usesPropane(generator)
        end

        -- Context options are bound in this form:
        -- function ISContextMenu:addOption(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10)
        -- We have no need to replace onActivateGenerator, onInfoGenerator, or onPlugGenerator, they simply queue timed actions or defer to modified code like the generator info window
        if opt.onSelect == ISWorldObjectContextMenu.doAddFuelGenerator then
            context:removeOptionByName(opt.name)
            -- Do add fuel binding replacement
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(substituteContextEntries)
--]]
log('Modified ISWorldObjectContextMenu')
