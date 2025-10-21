local item, super = Class(RegenItem, "l_potion")

function item:init()
    super.init(self)

    -- Display name
    self.name = "L-Potion"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Regens\n130MP"
    -- Shop description
    self.shop = "Nice\npotion that\nregens 130MP"
    -- Menu description
    self.description = "A large flask of clear liquid.\nRecovers 130 MP."

    -- Amount regened (RegenItem variable)
    self.regen_amount = 130

    -- Default shop price (sell price is halved)
    self.price = 450
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Character reactions (key = party member id)
    self.reactions = {
        susie = "Is this just water?",
        ralsei = "Y-yuck! Er, mmm, medicine?",
        noelle = "... Huh..."
    }
end

--[[function item:getRegenAmount(id)
    return self.regen_amount
end

function item:getBattleRegenAmountModified(id, healer)
    --local amount = self:getBattleHealAmount(id)

end

function item:onWorldUse(target)
    local consumed = super.onWorldUse(self, target)

    return consumed
end

function item:onBattleUse(user, target)
    super.onBattleUse(self, user, target)

end]]

return item