--- RegenItem is an extension of Item that provides additional functionality for items that regenerate mana when used. \
--- This class can be extended from in an item file instead of `Item` to include this functionality in the item.
--- 
---@class RegenItem : Item
---
---@field regen_amount           integer
---
---@field world_regen_amount     integer
---@field battle_regen_amount    integer
---
---@field regen_amounts          table<string, integer>
---
---@field world_regen_amounts    table<string, integer>
---@field battle_regen_amounts   table<string, integer>
---
---@overload fun(...) : RegenItem
local RegenItem, super = Class(Item)

function RegenItem:init()
    super.init(self)

    -- Amount this item regens
    self.regen_amount = 0

    -- Amount this item regens for in the overworld (optional)
    self.world_regen_amount = nil
    -- Amount this item regens for in battle (optional)
    self.battle_regen_amount = nil

    -- Amount this item regens for specific characters
    self.regen_amounts = {}

    -- Amount this item regens for specific characters in the overworld (optional)
    self.world_regen_amounts = {}
    -- Amount this item regens for specific characters in battle (optional)
    self.battle_regen_amounts = {}
end

--- Gets the amount of MP this item should restore for a specific character
---@param id string The id of the character to get the MP amount for
---@return integer
function RegenItem:getRegenAmount(id)
    if Registry.createPartyMember(id):usesMana() then
        return  self.regen_amounts[id] or self.regen_amount
    else
        return 0
    end
end

--- Gets the amount of MP this item should restore for a specific character when used in the world
---@param id string The id of the character to get the MP amount for
---@return integer
function RegenItem:getWorldRegenAmount(id)
    if Registry.createPartyMember(id):usesMana() then
        return self.world_regen_amounts[id] or self.world_regen_amount or self:getRegenAmount(id)
    else
        return 0
    end
end

--- Gets the amount of MP this item should restore for a specific character when used in battle
---@param id string The id of the character to get the MP amount for
---@return integer
function RegenItem:getBattleRegenAmount(id)
    if Registry.createPartyMember(id):usesMana() then
        return self.battle_regen_amounts[id] or self.battle_regen_amount or self:getRegenAmount(id)
    else
        return 0
    end
end

--- Applies `Battle:applyRegenBonuses()` to the battle regen amount. Can be overriden to disable or change behaviour.
---@param id string             The id of the character to get the MP amount for
---@param regener PartyMember    The party member performing the regen action
function RegenItem:getBattleRegenAmountModified(id, regener)
    local amount = self:getBattleRegenAmount(id)
    return Game.battle:applyManaRegenBonuses(amount, regener)
end

--- Modified to regenerate mana based on the set regeneration amounts
---@param target PartyMember|PartyMember[]
---@return boolean
function RegenItem:onWorldUse(target)
    if self.target == "ally" then
        -- Regen single party member
        local amount = self:getWorldRegenAmount(target.id)
        if target:usesMana() then
            Game.world:regenMana(target, amount)
        else
            Game.world:regenMana(target, 0)
        end
        return true
    elseif self.target == "party" then
        -- Regen all party members
        for _,party_member in ipairs(target) do
            local amount = self:getWorldRegenAmount(party_member.id)
            if party_member:usesMana() then
                Game.world:regenMana(party_member, amount)
            else
                Game.world:regenMana(party_member, 0)
            end
        end
        return true
    else
        -- No target or enemy target (?), do nothing
        return false
    end
end

--- Modified to perform regening based on the set regening amounts
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function RegenItem:onBattleUse(user, target)
    if self.target == "ally" then
        -- Regen single party member
        local amount = self:getBattleRegenAmountModified(target.chara.id, user.chara)
        if target.chara:usesMana() then
            target:regenMana(amount)
        else
            target:regenMana(0)
        end
    elseif self.target == "party" then
        -- Regen all party members
        for _,battler in ipairs(target) do
            local amount = self:getBattleRegenAmountModified(battler.chara.id, user.chara)
            if battler.chara:usesMana() then
                battler:regenMana(amount)
            else
                battler:regenMana(0)
            end
        end
    elseif self.target == "enemy" then
        -- Regen single enemy (why)
        local amount = self:getBattleRegenAmountModified(target.id, user.chara)
        target:regenMana(amount)
    elseif self.target == "enemies" then
        -- Regen all enemies (why????)
        for _,enemy in ipairs(target) do
            local amount = self:getBattleRegenAmountModified(enemy.id, user.chara)
            enemy:regenMana(amount)
        end
    else
        -- No target, do nothing
    end
end

return RegenItem