---@class World : Class
---@field world_caster          PartyMember|nil           The party member that is casting a spell in the overworld.
local World, super = Class("World", true)

function World:init(map)
    super.init(self, map)

    self.world_caster = nil
end

function World:onKeyPressed(key)
    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if key == "s" then
            local save_pos = nil
            if Input.shift() then
                save_pos = {self.player.x, self.player.y}
            end
            if Game:getConfig("smallSaveMenu") then
                self:openMenu(SimpleSaveMenu(Game.save_id, save_pos))
            elseif Game:isLight() then
                self:openMenu(LightSaveMenu(save_pos))
            else
                self:openMenu(SaveMenu(save_pos))
            end
        end
        if key == "h" then
            for _,party in ipairs(Game.party) do
                party:heal(math.huge)
            end
        end
        if key == "p" then
            for _,party in ipairs(Game.party) do
                if party:usesMana() then
                    party:regenMana(math.huge)
                end
            end
        end
        if key == "b" then
            if Input.shift() then
                Game.world:hurtParty(20)
            else
                Game.world:hurtParty(math.huge)
            end
        end
        if key == "l" then
            for _,party in ipairs(Game.party) do
                party:setMana(0)
                Assets.stopAndPlaySound("PMD2_PP_Down", 0.7)
            end
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
    end

    if Game.lock_movement then return end

    if self.state == "GAMEPLAY" then
        if Input.isConfirm(key) and self.player and not self:hasCutscene() then
            if self.player:interact() then
                Input.clear("confirm")
            end
        elseif Input.isMenu(key) and not self:hasCutscene() then
            self:openMenu(nil, WORLD_LAYERS["ui"] + 1)
            Input.clear("menu")
        end
    elseif self.state == "MENU" then
        if self.menu and self.menu.onKeyPressed then
            self.menu:onKeyPressed(key)
        end
    end
end

---Regenerate mana for a party member
---@param target    string|PartyMember  The party member to regen
---@param amount    number              The amount of MP to restore
---@param text?     string              An optional text to display when MP is resotred in the Light World, before the MP restoration message
function World:regenMana(target, amount, text)
    if type(target) == "string" then
        target = Game:getPartyMember(target)
    end

    local maxed = target:regenMana(amount)

    if Game:isLight() then
        local message
        if maxed then
            message = "* Your MP was maxed out."
        else
            message = "* You recovered " .. amount .. " MP!"
        end
        if text then
            message = text .. " \n" .. message
        end
        Game.world:showText(message)
    --[[elseif self.healthbar then
        for _, actionbox in ipairs(self.healthbar.action_boxes) do
            if actionbox.chara.id == target.id then
                local text = MPText("+" .. amount, self.healthbar.x + actionbox.x + 69, self.healthbar.y + actionbox.y + 15)
                text.layer = WORLD_LAYERS["ui"] + 1
                Game.world:addChild(text)
                return
            end
        end]]
    end
end

--- Sets the world caster
---@param caster    PartyMember|nil    The party member that is casting, if any
function World:setWorldCaster(caster)
    self.world_caster = caster
end

--- Gets the world caster
---@return PartyMember|nil
function World:getWorldCaster()
    return self.world_caster
end

return World