local generatorUtil = require("PGGeneratorUtils")
local isGenerator = generatorUtil.isGenerator
local isModded = generatorUtil.isModded

local function log(...)
    print('[Propane Generators (PGInventoryPaneContextMenu.lua)]: ', ...)
end

-- A correct generator has the following options

-- Within player inventory:
-- Put in Container (if one around, including floor/"loot")
-- Favorite 
-- Take Generator
-- Drop

-- Within non-player inventory:
-- Take Generator

-- Within Equipped items:
-- Put in Container (if one around, including floor/"loot")
-- Favorite
-- Drop
ISInventoryPaneContextMenu.substituteContextEntries = function(player, context, items)
    if #items == 0 or (#items == 1 and items[1] == nil) then
        return
    end

    local playerObject = getSpecificPlayer(player)

    -- Fake item table
    if #items == 1 and not instanceof(items[1], "InventoryItem") then
        local actualItems = items[1].items

        if #actualItems < 1 then
            return
        end
        -- First and second entries are duplicates of each other
        if #actualItems == 1 or #actualItems == 2 then
            local item = actualItems[1]

            -- Base generator and modded generator in hand work fine already
            if not isGenerator(item) or "Base.Generator" == item:getFullType() or playerObject:isHandItem(item) then
                return
            end

            local hasEquipInBothHands = false
            local equipInBothHandsIndex = nil
            local hasTakeGeneratorOption = false
            for i = 1, #context.options do
                local opt = context.options[i]

                if not hasEquipInBothHands and ISInventoryPaneContextMenu.OnTwoHandsEquip == opt.onSelect then
                    hasEquipInBothHands = true
                    equipInBothHandsIndex = i
                end

                if not hasTakeGeneratorOption and ISInventoryPaneContextMenu.equipHeavyItem == opt.onSelect then
                    hasTakeGeneratorOption = true
                end
            end

            if hasTakeGeneratorOption then
                return
            end

            if hasEquipInBothHands then
                context.options[equipInBothHandsIndex] = context:allocOption(getText("ContextMenu_GeneratorTake"), playerObject, ISInventoryPaneContextMenu.equipHeavyItem, item)
            else
                context:insertOptionBefore(getText("ContextMenu_Drop"), getText("ContextMenu_GeneratorTake"), playerObject, ISInventoryPaneContextMenu.equipHeavyItem, item)
            end
        end
    end

    -- I left this in here, but honestly I'm not sure it's ever a relevant case
    if #items > 0 and instanceof(items[1], "InventoryItem") then
        if #items == 1 then
            local item = items[1]

            -- Base generator and modded generator in hand work fine already
            if not isGenerator(item) or "Base.Generator" == item:getFullType() or playerObject:isHandItem(item) then
                return
            end

            local hasEquipInBothHands = false
            local hasTakeGeneratorOption = false
            for i = 1, #context.options do
                local opt = context.options[i]

                if not hasTakeGeneratorOption and ISInventoryPaneContextMenu.equipHeavyItem == opt.onSelect then
                    hasTakeGeneratorOption = true
                end
            end

            if hasTakeGeneratorOption then
                return
            end

            context:addOptionOnTop(getText("ContextMenu_GeneratorTake"), playerObject, ISInventoryPaneContextMenu.equipHeavyItem, item)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ISInventoryPaneContextMenu.substituteContextEntries)