local originalIsValid = ISEquipHeavyItem.isValid

function ISEquipHeavyItem:isValid()
    local isValidResult = originalIsValid(self)

    local fullType = self.item:getFullType()

    if not ("Base.Generator" == fullType or "PropaneGenerators.PropaneGenerator" == fullType or
       "PropaneGenerators.DualFuelGenerator" == fullType) then
        return isValidResult
    end

    if not isValidResult and self:isAlreadyTransferred(self.item) then
        -- Force this to work: we're equipping it, being in our inventory is fine
        return true
    end

    return isValidResult
end