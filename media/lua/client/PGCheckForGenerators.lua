local generatorUtil = require("PGGeneratorUtils")
local DUAL_FUEL = generatorUtil.GENERATOR_TYPES.DualFuel
local GENERATOR_TYPES = generatorUtil.GENERATOR_TYPES
local getRandomCondition = generatorUtil.getRandomCondition
local getRandomDualFuelSetting = generatorUtil.getRandomDualFuelSetting
local getRandomFuelLevel = generatorUtil.getRandomFuelLevel
local getRandomGeneratorType = generatorUtil.getRandomGeneratorType
local isModded = generatorUtil.isModded

local function log(...)
    print('[Propane Generators (PGCheckForGenerators.lua)]: ', ...)
end

PGCheckForGenerators = {}

function PGCheckForGenerators:checkRoomForGenerator(square)
    if not square:getModData().checkedForGenerator then
        local room = square:getRoom()
        if room then
            local squares = room:getSquares()
            if squares:size() > 1 then
                for i = 0, squares:size() - 1 do
                    self:checkSquareForGenerator(squares:get(i))
                end
            else
                self:checkSquareForGenerator(square)
            end
        end
    end
end

function PGCheckForGenerators:checkSquareForGenerator(square)
    if not square then
        return
    end

    local modData = square:getModData()
    local generator = square:getGenerator()

    if generator and not isModded(generator) then
        log('We have an unmodded generator!')
        local fuel = getRandomFuelLevel()
        local condition = getRandomCondition()
        local generatorType = getRandomGeneratorType()
        local dualFuelSetting = (DUAL_FUEL == generatorType and getRandomDualFuelSetting()) or nil
        log('Settings-- fuel:', fuel, ', condition:', condition, ', generatorType:', generatorType, ', dualFuelSetting: ', dualFuelSetting)

        generator:setCondition(condition)
        generator:setFuel(fuel)
        generator:update()
        log('Grabbing modData freshly off of generator to set further data points')
        modData = generator:getModData()
        modData.dualFuelSetting = dualFuelSetting
        modData.fuel = fuel
        modData.generatorType = generatorType
        generator:transmitModData()
        generator:transmitCompleteItemToServer()
        log('Grabbing modData freshly off of generator after transmit to query data points')
        modData = generator:getModData()
        for k,v in pairs(modData) do
            log('Key:', k, ', value:', v)
        end
    end

    square:getModData().checkedForGenerator = true
    -- IsoGridSquare's method is typo'd :(
    square:transmitModdata()
end

function PGCheckForGenerators:checkSquaresForGenerator(squares)
    for i = 0, #squares - 1 do
        self:checkSquareForGenerator(square)
    end
end

function PGCheckForGenerators:checkForGeneratorOnMove(player)
    local square = player:getSquare()

    if not square then
        return
    end

    local squares = {}
    table.insert(squares, square:getN())
    table.insert(squares, square:getS())
    table.insert(squares, square:getW())
    table.insert(squares, square:getE())

    self:checkRoomForGenerator(square)
    self:checkSquareForGenerator(square)
    self:checkSquaresForGenerator(squares)
end

log('Adding PGCheckForGenerators:checkForGeneratorOnMove to OnPlayerMove')
Events.OnPlayerMove.Add(function(isoPlayer)
    PGCheckForGenerators:checkForGeneratorOnMove(isoPlayer)
end)