local generatorUtil = require("PGGeneratorUtils")
local DUAL_FUEL = generatorUtil.GENERATOR_TYPES.DualFuel
local GENERATOR_TYPES = generatorUtil.GENERATOR_TYPES
local getNewGeneratorSettings = generatorUtil.getNewGeneratorSettings
local isModded = generatorUtil.isModded
local modNewGenerator = generatorUtil.modNewGenerator

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
    elseif square:getModData().checkedForGenerator then
        return
    end

    local generator = square:getGenerator()

    if generator and not isModded(generator) then
        modNewGenerator(generator)
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

    local squares = self:extractSearchSquares(square)

    self:checkRoomForGenerator(square)
    self:checkSquareForGenerator(square)
    self:checkSquaresForGenerator(squares)
end

function PGCheckForGenerators:extractSearchSquares(square)
    local squares = {}
    local n = square:getN()
    local s = square:getS()
    local w = square:getW()
    local e = square:getE()
    table.insert(squares, n)
    table.insert(squares, s)
    table.insert(squares, w)
    table.insert(squares, e)

    if n then
        table.insert(squares, n:getW())
        table.insert(squares, n:getE())
    else
        if e then
            table.insert(squares, e:getN())
        end

        if w then
            table.insert(squares, w:getN())
        end
    end

    if s then
        table.insert(squares, s:getW())
        table.insert(squares, s:getE())
    else
        if e then
            table.insert(squares, e:getS())
        end

        if w then
            table.insert(squares, w:getS())
        end
    end

    return squares
end

log('Adding PGCheckForGenerators:checkForGeneratorOnMove to OnPlayerMove')
Events.OnPlayerMove.Add(function(isoPlayer)
    PGCheckForGenerators:checkForGeneratorOnMove(isoPlayer)
end)