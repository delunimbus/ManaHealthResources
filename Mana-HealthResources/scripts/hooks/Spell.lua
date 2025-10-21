
---@class Spell : Class
---@field mana_cost integer                 The MP cost of the spell.
---@field health_cost integer               The HP cost of a spell.
local Spell, super = Class("Spell", true)

function Spell:init()

    super.init(self)

    --self.default_resource = "tension"

    self.mana_cost = 0
    self.health_cost = 0

end

--Gets the mana cost of the spell.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getMPCost(chara) return self.mana_cost
end

--Gets the health cost of the spell.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getHPCost(chara) return self.health_cost
end

--Gets the spell resource type that the party member uses for the spell.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getResourceType(chara)

    local exists = false

    if chara.spell_cost_resources ~= nil then
        --table_setup = true
        for _,s in ipairs(chara.spell_cost_resources) do
            if s.spell_id == self.id then
                exists = true
                return s.resource
            end
        end
    end

    if not exists then
        return chara:getMainSpellResourceType()
    end

end

return Spell