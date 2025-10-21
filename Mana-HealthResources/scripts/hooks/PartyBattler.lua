---@class PartyBattler : Class
---@field revived_this_turn boolean
local PartyBattler, super = Class("PartyBattler", true)

function PartyBattler:init(chara, x, y)
    super.init(self, chara, x, y)

    self.revived_this_turn = false

end

function PartyBattler:checkHealth(swoon)
    if (not self.is_down) and self.chara:getHealth() <= 0 then
        if swoon then
            self:swoon()
        else
            self:down()
        end
    elseif (self.is_down) and self.chara:getHealth() > 0 then
        self:revive()
        -------------------
        self.revived_this_turn = true
        -------------------
    end
end

--Prevents mana from going below 0
function PartyBattler:checkMana()
    if self.chara:getMana() <= 0 then
        self.chara:setMana(0)
    end
end

---@param amount    number  The depletion from the incoming hit
---@param exact?    boolean Whether the depletion should be treated as exact depletion instead of applying defense and element modifiers
---@param color?    table   The color of the depletion number
---@param element?  string  The element to make damage calculations with (if any)
---@param options?  table   A table defining additional properties to control the way depletion is taken
---|"all"   # Whether the depletion being taken comes from a strike targeting the whole party
function PartyBattler:depleteMana(amount, exact, color, element, options)
    local passive = self.chara:getPassive()
    options = options or {}

    if not options["all"] then
        Assets.stopAndPlaySound("PMD2_PP_Down", 0.7)
        if not exact then
            amount = self:calculateDamage(amount)
            if self.defending then
                amount = math.ceil((2 * amount) / 3)
            end
            -- we don't have elements right now
            --local element = 0
            --amount = math.ceil((amount * self:getElementReduction(element)))
        end
        self:removeMana(amount)
    else
        -- We're targeting everyone.
        if not exact then
            amount = self:calculateDamage(amount)
            if passive then
                amount = passive:applyPhysicalDamageRecievedMod(self, amount, nil, element)
            end
            -- we don't have elements right now
            --local element = 0
            --amount = math.ceil((amount * self:getElementReduction(element)))

            if self.defending then
                amount = math.ceil((3 * amount) / 4) -- Slightly different than the above
            end
        end

        self:removeMana(amount) -- Use a separate function for cleanliness (nuh uh)
    end

    if (self.chara:getMana() <= 0) then
        if self.chara:usesMana() then
            self:statusMessageMana("damage", -amount, {30/255, 144/255, 1}, true)
        end
    else
        self:statusMessageMana("damage", -amount or 0, {30/255, 144/255, 1}, true)
    end

    self.hurt_timer = 0
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then
        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            if self.hurting then
                self.hurting = false
                self:toggleOverlay(false)
            end
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
        end
    end
end

--- Removes MP from the character
---@param amount number
function PartyBattler:removeMana(amount)
    if (self.chara:getMana() <= 0) then
        self.chara:setMana(0)
    else
        self.chara:setMana(self.chara:getMana() - amount)
    end
    self:checkMana()
end

--- Heals the Battler by `amount` mana and does healing effects
---@param amount            number  The amount of mana to restore
---@param sparkle_color?    table   The color of the heal sparkles (defaults to the standard green)
function PartyBattler:regenMana(amount, sparkle_color)
    Assets.stopAndPlaySound("PMD2_PP_Up")

    amount = math.floor(amount)

    self.chara:setMana(self.chara:getMana() + amount)

    self:flash()

    if self.chara:usesMana() and self.chara:getMana() >= self.chara:getStat("mana") then
        self.chara:setMana(self.chara:getStat("mana"))
        self:statusMessageMana("msg", "mp_max", nil, nil, 8)
        --self:statusMessage("heal", amount)
    else
        self:statusMessageMana("regen", amount, {30/255, 144/255, 254/255})
    end

    self:sparkle(unpack(sparkle_color or {0, 193/255, 242/255}))
end

function PartyBattler:statusMessageMana(...)    --This is just me being lazy (y did i type this for?)
    local message = super.super.statusMessage(self, 0, (self.height/2) - 10, ...)
    message.y = message.y - 4
    return message
end

return PartyBattler