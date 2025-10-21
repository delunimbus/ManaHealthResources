---@class PartyMember : Class
---
---@field stats {magic: number, defense: number, attack: number, health: number, mana: number}
---
---@field main_spell_resource string
---@field spell_cost_resources table<table>
---@field resource_used string
---
---@field resource_used string
---@field encountered_spells string[]
---
---@field uses_mana boolean
---@field mana number
---@field lw_mana number
---@field can_auto_regen_mana boolean
---@field mana_mode string
local PartyMember, super = Class("PartyMember", true)

function PartyMember:init()

    super.init(self)

    self.main_spell_resource = "tension"        --The default resource the party member uses for their spells. Any subsequent spells added will have their resource type set to this automatically.
    self.spell_cost_resources = {}              --The cost type for spells
    self.resource_used = "tension"              --Resourced used for a spell during a turn during battle (used for the onDeselect actions.) (defaults to tension) (is this still used?)

    self.spell_used = nil                       --The spell that the party member (will) use[d] for the turn
    self.encountered_spells = {}                --The IDs of the spells that the party member has encountered (you decide what "encountered" means).                  --Whether the neccesary resources were paid to active the passive (if any).

    self.uses_mana = false                      --Whether the party member uses mana (defaults to false)
    self.can_auto_regen_mana = false            --Whether the party member can regenerate mana passively (defaults to false
    self.auto_mana_regen_settings = {}          --Scaling of auto mana regen: {flat_increase: number, tp_scaling: number}   ((TP * (10x))/max MP)
    --Type of mana-based gameplay:  
    -- `traditional`    = standard, 
    -- `gotr`           = Same as FFT A2: GotR (Unsuable outside battle. Starts at 0 in the first turn. Gain mana every subsequent turn. Resets to 0 after battle ends.)
    self.mana_mode = "traditional"
    self.mana = 0                               --Current mana points (saved to the save file)
    self.lw_mana = 0                            --Current light world mana points (saved to the save file)

    self.stats = {
        health = 100,
        attack = 10,
        defense = 2,
        mana = 0,
    }

end

---------------------------------------------Resource Functions---------------------------------------------------------------------

--Sets the resource used for the spell.
---@param resource string The resource used. (...)
function PartyMember:setResourceUsed(resource)
    self.resource_used = resource
    --print("Resource used: " .. self.resource_used)
end

--Sets the spell used
---@param spell Spell|nil The spell used...
function PartyMember:setSpellUsed(spell)
    --print(spell)
    self.spell_used = spell or nil
end
--Gets the spell used
---@return Spell
function PartyMember:getSpellUsed()
    return self.spell_used
end

--Gets the party member's main resource type
function PartyMember:getMainSpellResourceType()
    return self.main_spell_resource
end

--Sets the party member's main resource type
---@param resource string The party member's resource type to set as their default/main one.
function PartyMember:setMainSpellResourceType(resource)
    self.main_spell_resource = resource
end

--Sets the type of cost the user will use for the spell.
---@param spell string|Spell The spell to set the resource for
---@param resource string|nil The type of resource to use. (Defaults to "tension" if variable not given.)
function PartyMember:setSpellResourceType(spell, resource)

    local exists = false

    if type(spell) ~= "string" then
        spell = spell.id
    end

    --print(spell)
    resource = resource or self:getMainSpellResourceType()
    --print(resource)

    for _,s in ipairs(self:getSpellResourceTypes()) do
        if s.spell_id == spell then
            exists = true
            s.resource = resource
        end
    end

    if not exists then
        local cost_info = {
        ["spell_id"] = spell,
        ["resource"] = resource
    }
    table.insert(self.spell_cost_resources, cost_info)
    end


end

--Gets the dafault resource that the spell uses.
---@param spell Spell|string The `Spell` to check for
function PartyMember:getSpellDefaultResourceType(spell)

    --local SPELL = spell

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end

    return spell:getResourceType(self)

end

--Gets the spell resource type that the party member uses for the spell.
---@param spell Spell|string The `Spell` to check for
function PartyMember:getSpellResourceType(spell)

    local exists = false

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end

    if self:getSpellResourceTypes() ~= nil then
        for _,s in ipairs(self:getSpellResourceTypes()) do
            if s.spell_id == spell.id then
                exists = true
                return s.resource
            end
        end
    end

    if not exists then
        return self:getSpellDefaultResourceType(spell)
    end

end

--Sets up all the user's available spells to use one resource across all of them.
---@param resource string The resource to set all spells to use.
function PartyMember:setUniformSpellResourceType(resource)

    local exists = false

    for _,spell in ipairs(self:getSpells()) do

        for _,s in ipairs(self:getSpellResourceTypes()) do
            exists = true
            s["resource"] = resource
        end
        if not exists then
            self:setSpellResourceType(spell, resource)
        end
    end

end

--Gets the spell cost resources attributed to the party member.
function PartyMember:getSpellResourceTypes() return self.spell_cost_resources end

---------------------------------------------Mana Functions---------------------------------------------------------------------

--Checks whether the party member uses mana.
---@return boolean
function PartyMember:usesMana() return self.uses_mana end

--Sets whether the party member uses mana or not.
---@param bool boolean
function PartyMember:setManaUserStatus(bool)
    self.uses_mana = bool
end

--Gets the current MP of the party member.
---@return integer
function PartyMember:getMana() return Game:isLight() and self.lw_mana or self.mana end

--Gets the mana gameplay mode of the party member.
---@return string
function PartyMember:getManaMode()
    return self.mana_mode
end

--Sets the mana mode of the party member.
---@param mode string the name of the mode
function PartyMember:setManaMode(mode)
    self.mana_mode = mode
end

---Sets this party member's MP value
---@param amount number
function PartyMember:setMana(amount)
    if Game:isLight() then
        self.lw_mana = amount
    else
        self.mana = amount
    end
end

--Simple mana removal function.
---@param amount number
function PartyMember:removeMana(amount)
    self:setMana(self:getMana() - amount)
end

--How much to regenerate mana (works identical to 'PartyMember:heal())
function PartyMember:regenMana(amount, playsound)
    if playsound == nil or playsound then
        Assets.stopAndPlaySound("PMD2_PP_Up", 0.8)
    end
    self:setMana(math.min(self:getStat("mana"), self:getMana() + amount))
    return self:getStat("mana") == self:getMana()
end

function PartyMember:canAutoRegenMana() return self.can_auto_regen_mana end

--- *(Override)* Gets the amount of health this party member should regain mana points each turn (unused by default).
---@param tp_scaling number Sets the scaling of the auto-regen in proportion to current TP: ((TP% * (10x))/max MP)
---@param flat_increase number Sets the flat increase number of MP per turn.
---@return number
function PartyMember:autoRegenManaAmount(tp_scaling, flat_increase)
    tp_scaling =      3
    flat_increase =   8
    -- TODO: Is this round or ceil? Both were used before this function was added. ---idk

    local bonus = MathUtils.round((Game:getTension() * (10 * tp_scaling)) / self:getStat("mana"))

    return MathUtils.round(flat_increase + bonus)
end

--Gets the list of spells that the player has encountered.
---@return table
function PartyMember:getEncounteredSpells()
    return self.encountered_spells
end

--Adds an encountered spell to the party
---@param spell Spell|string The spell to add.
function PartyMember:addEncounteredSpell(spell)

    local spell_already_added = false

    local exists = false

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    for _,s in ipairs(self:getEncounteredSpells()) do
        --print(s)
        if s == spell then
            --print("AMONGUSSSS")
            exists = true
        end
    end

    for _,S in ipairs(self:getSpells()) do
        if S.id == spell then
            --print("YOLOOOOOOOO")
            spell_already_added = true
        end
    end

    if exists and not spell_already_added then

        self:addSpell(spell)

    elseif not exists then Kristal.Console:warn("Spell not found in the encountered spells list.") --Does this work as intended?
    end

end

--Adds the spell to the encountered spells list.
---@param spell Spell|string The spell to add.
function PartyMember:addToEncounteredSpellsList(spell)

    local spell_already_encountered = false

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    for _,s in ipairs(self.encountered_spells) do
        if s == spell then
            --print("poppE")
            spell_already_encountered = true
        end
    end

    if not spell_already_encountered then
        --if self:hasDrawMagicSkill()  then
            --self:addSpell(spell)
            --self:setSpellResourceType(spell, "stock")
            --self:setSpellStockData(spell, 0, SPELL:getStartingStockLimit())
        --end
        table.insert(self.encountered_spells, spell)
    end

end

--Adds all spells in the encountered list into the party member's regular spells list.
function PartyMember:addAllEncounteredSpells()

    local spell_already_added = false

    for _,s in ipairs(self:getEncounteredSpells()) do
        for _,spell in ipairs(self:getSpells()) do
            if spell.id == s then
                spell_already_added = true
            end
        end
        if not spell_already_added then
            self:addSpell(s)
        end
        spell_already_added = false
    end

end

---------------------------------------------Save Data---------------------------------------------------------------------

---@param spell string|Spell
function PartyMember:addSpell(spell)

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end
    table.insert(self.spells, spell)
---------------------------------------------------
    self:addToEncounteredSpellsList(spell)
    self:setSpellResourceType(spell)
---------------------------------------------------
end

---@return string[] spells An array of the spell IDs this party member has encountered
function PartyMember:saveEncounteredSpells()
    local result = {}
    for _,v in pairs(self.encountered_spells) do
        --print("Save encountered spell for " .. self:getName() .. ": " .. v)
        table.insert(result, v)
    end
    return result
end

---@return table
function PartyMember:saveSpellResourceTypes()
    local result = {}
    for _,v in pairs(self.spell_cost_resources) do
        local spell = v.spell_id
        local resource = v.resource or self:getMainSpellResourceType()
        --print("Save spell resource by " .. self:getName() .. " for " .. Registry.createSpell(spell):getName() .. ": " .. resource)
        local cost_data = {
            ["spell_id"] = spell,
            ["resource"] = resource
        }
        table.insert(result, cost_data)
    end
    return result
end

---@param data string[] An array of the spell IDs this party member has encountered
function PartyMember:loadEncounteredSpells(data)
    self.encountered_spells = {}
    --print("monkaOmega")
    for _,v in ipairs(data) do
        if Registry.getSpell(v) then
            --print("Load encountered spell for " .. self:getName() .. ": " .. v)
            self:addToEncounteredSpellsList(v)
        else
            Kristal.Console:error("Could not load encountered spell \"".. (v or "nil") .."\"")
        end
    end
end

---@param data table
function PartyMember:loadSpellResourceTypes(data)
    self.spell_cost_resources = {}
    for _,v in ipairs(data) do
        --print("peepeepoopoo")
        if Registry.createSpell(v.spell_id) then
            local spell = v.spell_id
            local resource = v.resource or self:getMainSpellResourceType()
            --print("Load spell resource by " .. self:getName() .. " for " .. Registry.createSpell(spell):getName() .. ": " .. resource)
            self:setSpellResourceType(spell, resource)
        else
            Kristal.Console:error("Could not load spell \"".. (v or "nil") .."\"")
        end
    end
end

---@return PartyMemberSaveData
function PartyMember:save()
    local data = {
        id = self.id,
        title = self.title,
        level = self.level,
        health = self.health,
        stats = self.stats,
        lw_lv = self.lw_lv,
        lw_exp = self.lw_exp,
        lw_health = self.lw_health,
        lw_stats = self.lw_stats,
        spells = self:saveSpells(),
        equipped = self:saveEquipment(),
        flags = self.flags,
------------------------------------------------
        uses_mana = self.uses_mana,
        mana_mode = self.mana_mode,
        --can_auto_heal = self.can_auto_heal,
        main_spell_resource = self.main_spell_resource,
        spell_cost_resources = self:saveSpellResourceTypes(),
        mana = self.mana,
        lw_mana = self.lw_mana,
        auto_mana_regen_flat_increase = self.auto_mana_regen_flat_increase,
        auto_mana_regen_tp_scaling = self.auto_mana_regen_tp_scaling,
        encountered_spells = self:saveEncounteredSpells(),
-----------------------------------------------
    }
    self:onSave(data)
    return data
end

---@param data PartyMemberSaveData
function PartyMember:load(data)
    self.title = data.title or self.title
    self.level = data.level or self.level
    self.stats = data.stats or self.stats
    self.lw_lv = data.lw_lv or self.lw_lv
    self.lw_exp = data.lw_exp or self.lw_exp
    self.lw_stats = data.lw_stats or self.lw_stats
    if data.spells then
        self:loadSpells(data.spells)
    end
    if data.equipped then
        self:loadEquipment(data.equipped)
    end
------------------------------------------------
    self.uses_mana = data.uses_mana or self.uses_mana
    self.mana_mode = data.mana_mode or self.mana_mode
    --self.can_auto_heal = data.can_auto_heal or self.can_auto_heal
    self.main_spell_resource = data.main_spell_resource or self.main_spell_resource
    if data.spell_cost_resources then
        self:loadSpellResourceTypes(data.spell_cost_resources)
    end
    self.mana = data.mana or self:getStat("mana", 0, false)
    self.lw_mana = data.lw_mana or self:getStat("mana", 0, true)
    self.auto_mana_regen_flat_increase = data.auto_mana_regen_flat_increase or self.auto_mana_regen_flat_increase
    self.auto_mana_regen_tp_scaling = data.auto_mana_regen_tp_scaling or self.auto_mana_regen_tp_scaling
    if data.encountered_spells then
        self:loadEncounteredSpells(data.encountered_spells)
    end
-----------------------------------------------
    self.flags = data.flags or self.flags
    self.health = data.health or self:getStat("health", 0, false)
    self.lw_health = data.lw_health or self:getStat("health", 0, true)

    self:onLoad(data)
end

return PartyMember