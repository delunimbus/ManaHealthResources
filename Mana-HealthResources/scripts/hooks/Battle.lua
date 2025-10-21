local Battle, super = Class("Battle", true)

function Battle:onKeyPressed(key)

    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "h" then
            for _,party in ipairs(self.party) do
                party:heal(math.huge)
                party:revive()
            end
        end
        if key == "y" then
            Input.clear(nil, true)
            self:setState("VICTORY")
        end
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if self.state == "DEFENDING" and key == "f" then
            self.encounter:onWavesDone()
        end
        if self.soul and self.soul.visible and key == "j" then
            local x, y = self:getSoulLocation()
            self.soul:shatter(6)

            -- Prevents a crash related to not having a soul in some waves
            self:spawnSoul(x, y)
            for _,heartbrust in ipairs(Game.stage:getObjects(HeartBurst)) do
                heartbrust:remove()
            end
            self.soul.visible = false
            self.soul.collidable = false
        end
        if key == "b" then
            for _,battler in ipairs(self.party) do
                if Input.shift() then
                    battler:hurt(Utils.floor(battler.chara:getHealth() / 2))
                else
                    battler:hurt(math.huge)
                end
            end
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
-------------------------------------------------
        if key == "p" then
            for _,battler in ipairs(self.party) do
                if battler.chara:usesMana() then
                    battler:regenMana(math.huge)
                end
            end
        end
        if key == "l" then
            for _,battler in ipairs(self.party) do
                if battler.chara:usesMana() then
                    Assets.stopAndPlaySound("PMD2_PP_Down", 0.7)
                    battler.chara:setMana(0)
                end
            end
        end
        if key == "u" then
            Game:setTension(0, true)
        end
-------------------------------------------------
    end
    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if Input.isConfirm(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            --self:updateSplitCost()
            if self.encounter:onMenuSelect(self.state_reason, menu_item, can_select) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuSelect, self.state_reason, menu_item, can_select) then return end
            if can_select then
                self.ui_select:stop()
                self.ui_select:play()
                menu_item["callback"](menu_item)
                return
            end
        elseif Input.isCancel(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            if self.encounter:onMenuCancel(self.state_reason, menu_item) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuCancel, self.state_reason, menu_item, can_select) then return end
            self.ui_move:stop()
            self.ui_move:play()
            Game:setTensionPreview(0)
            self:setState("ACTIONSELECT", "CANCEL")
            return
        elseif Input.is("left", key) then -- TODO: pagination
            self.current_menu_x = self.current_menu_x - 1
            if self.current_menu_x < 1 then
                self.current_menu_x = menu_width
                if not self:isValidMenuLocation() then
                    self.current_menu_x = 1
                end
            end
        elseif Input.is("right", key) then
            self.current_menu_x = self.current_menu_x + 1
            if not self:isValidMenuLocation() then
                self.current_menu_x = 1
            end
        end
        if Input.is("up", key) then
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = 1 -- No wrapping in this menu.
            end
        elseif Input.is("down", key) then
            if self:getItemIndex() % 6 == 0 and #self.menu_items % 6 == 1 and self.current_menu_y == menu_height - 1 then
                self.current_menu_x = self.current_menu_x - 1
            end
            self.current_menu_y = self.current_menu_y + 1
            if (self.current_menu_y > menu_height) or (not self:isValidMenuLocation()) then
                self.current_menu_y = menu_height -- No wrapping in this menu.
                if not self:isValidMenuLocation() then
                    self.current_menu_y = menu_height - 1
                end
            end
        end
    elseif self.state == "ENEMYSELECT" or self.state == "XACTENEMYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onEnemySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if #self.enemies_index == 0 then return end
            self.selected_enemy = self.current_menu_y
            if self.state == "XACTENEMYSELECT" then
                local xaction = Utils.copy(self.selected_xaction)
                if xaction.default then
                    xaction.name = self.enemies_index[self.selected_enemy]:getXAction(self.party[self.current_selecting])
                end
                self:pushAction("XACT", self.enemies_index[self.selected_enemy], xaction)
            elseif self.state_reason == "SPARE" then
                self:pushAction("SPARE", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "ACT" then
                self:clearMenuItems()
                local enemy = self.enemies_index[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local insert = not v.hidden
                    if v.character and self.party[self.current_selecting].chara.id ~= v.character then
                        insert = false
                    end
                    if v.party and (#v.party > 0) then
                        for _,party_id in ipairs(v.party) do
                            if not self:getPartyIndex(party_id) then
                                insert = false
                                break
                            end
                        end
                    end
                    if insert then
                        self:addMenuItem({
                            ["name"] = v.name,
                            ------------------------------------
                            ["resource"] = v.resource or "tension",
                            --["cost_statistic"] = v.cost_statistic or "none",
                            ["tp"] = v.tp or 0,
                            ["mp"] = v.mp or 0,
                            ["hp"] = v.hp or 0,
                            --------------------------------------
                            ["description"] = v.description,
                            ["party"] = v.party,
                            ["color"] = v.color or {1, 1, 1, 1},
                            ["highlight"] = v.highlight or enemy,
                            ["icons"] = v.icons,
                            ["callback"] = function(menu_item)
                                self:pushAction("ACT", enemy, menu_item)
                            end
                        })
                    end
                end
                self:setState("MENUSELECT", "ACT")
            elseif self.state_reason == "ATTACK" then
                self:pushAction("ATTACK", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.enemies_index[self.selected_enemy], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.enemies_index[self.selected_enemy], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onEnemyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y - 1
                if self.current_menu_y < 1 then
                    self.current_menu_y = #self.enemies_index
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        elseif Input.is("down", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y + 1
                if self.current_menu_y > #self.enemies_index then
                    self.current_menu_y = 1
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onPartySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.party[self.current_menu_y], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.party[self.current_menu_y], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onPartyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.party
            end
        elseif Input.is("down", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.party then
                self.current_menu_y = 1
            end
        end
    elseif self.state == "BATTLETEXT" then
        -- Nothing here
    elseif self.state == "SHORTACTTEXT" then
        -- Nothing here
    elseif self.state == "ENEMYDIALOGUE" then
        -- Nothing here
    elseif self.state == "ACTIONSELECT" then
        self:handleActionSelectInput(key)
    elseif self.state == "ATTACKING" then
        self:handleAttackingInput(key)
    end
end

function Battle:addMenuItem(tbl)
    -- Item colors in Ch3+ can be dynamic (e.g. pacify) so we should use functions for item color.
    -- Table colors can still be used, but we'll wrap them into functions.
    local color = tbl.color or {1, 1, 1, 1}
    local fcolor
    if type(color) == "table" then
        fcolor = function () return color end
    else
        fcolor = color
    end
    tbl = {
        ["name"] = tbl.name or "",
        ["resource"] = tbl.resource or "tension",
        ["tp"] = tbl.tp or 0,
        ["mp"] = tbl.mp or 0,
        ["hp"] = tbl.hp or 0,
        ["unusable"] = tbl.unusable or false,
        ["description"] = tbl.description or "",
        ["party"] = tbl.party or {},
        ["color"] = fcolor,
        ["data"] = tbl.data or nil,
        ["callback"] = tbl.callback or function() end,
        ["highlight"] = tbl.highlight or nil,
        ["icons"] = tbl.icons or nil
    }
    table.insert(self.menu_items, tbl)
    return tbl
end

function Battle:commitAction(battler, action_type, target, data, extra)
    data = data or {}
    extra = extra or {}

    local is_xact = action_type:upper() == "XACT"
    if is_xact then
        action_type = "ACT"
    end

    local tp_diff = 0

    if data.tp then
        tp_diff = MathUtils.clamp(-data.tp, -Game:getTension(), Game:getMaxTension() - Game:getTension())
    end

    local party_id = self:getPartyIndex(battler.chara.id)

    -- Dont commit action for an inactive party member
    if not battler:isActive() then return end

    -- Make sure this action doesn't cancel any uncancellable actions
    if data.party then
        for _,v in ipairs(data.party) do

            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.cancellable == false then
                        return
                    end
                    if action.act_parent then
                        local parent_action = self.character_actions[action.act_parent]
                        if parent_action.cancellable == false then
                            return
                        end
                    end
                end
            end
        end
    end

    self:commitSingleAction(Utils.merge({
        ["character_id"] = party_id,
        ["action"] = action_type:upper(),
        ["party"] = data.party,
        ["name"] = data.name,
        ["resource"] = data.resource,
        ["target"] = target,
        ["data"] = data.data,
        ["tp"] = tp_diff,
        ["mp"] = data.mp,
        ["hp"] = data.hp,
        ["cancellable"] = data.cancellable,
    }, extra))

end

function Battle:canSelectMenuItem(menu_item)
    --print(menu_item.resource)
    if menu_item.unusable then
        return false
    end
    if menu_item.tp and menu_item.resource == "tension" and (menu_item.tp > Game:getTension()) then     --let me know if something becomes unsuable from this.
        return false
    end
    if menu_item.resource == "health" then
        if (menu_item.hp >= self.party[self.current_selecting].chara:getHealth()) then
            return false
        end
    end
    if menu_item.resource == "mana" then
        if Game.battle.state_reason == "SPELL" and (menu_item.mp > self.party[self.current_selecting].chara:getMana()) then
            return false
        end
    end
    if menu_item.party then
        for _,party_id in ipairs(menu_item.party) do
            local party_index = self:getPartyIndex(party_id)
            local battler = self.party[party_index]
            local action = self.character_actions[party_index]
            if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end
    return true
end

function Battle:commitSingleAction(action)

    local battler = self.party[action.character_id]

    battler.action = action
    self.character_actions[action.character_id] = action

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionCommit, action, action.action, battler, action.target) then
        return
    end

    if action.action == "ITEM" and action.data then
        local result = action.data:onBattleSelect(battler, action.target)
        if result ~= false then
            local storage, index = Game.inventory:getItemIndex(action.data)
            action.item_storage = storage
            action.item_index = index
            if action.data:hasResultItem() then
                local result_item = action.data:createResultItem()
                Game.inventory:setItem(storage, index, result_item)
                action.result_item = result_item
            else
                Game.inventory:removeItem(action.data)
            end
            action.consumed = true
        else
            action.consumed = false
        end
    end

    local anim = action.action:lower()

    if action.action == "SPELL" and action.data --[[and not action.spenders]] then
        --print(action.mp)
        local result = action.data:onSelect(battler, action.target)
        if result ~= false then
            if action.tp and action.resource == "tension" then
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            elseif action.mp and action.resource == "mana" then
                ---print(action.mp)
                if action.mp > 0 then
                    battler.chara:setMana(battler.chara:getMana() - action.mp)
                elseif action.mp < 0 then
                    battler.chara:setMana(battler.chara:getMana() + action.mp)
                end
            elseif action.hp and action.resource == "health" then
                if action.hp > 0 then
                    self:hurt(action.hp, true, battler)
                elseif action.hp < 0 then
                    battler.chara:heal(-action.hp)
                end
            end
        battler:setAnimation("battle/"..anim.."_ready")
        action.icon = anim
        end
    else
        --if not action.spenders then
            if action.tp and (action.resource == "tension" or action.action == "DEFEND") then
                --print(action.tp)
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            end
            if action.mp and action.resource == "mana"and not action.spenders then
                if action.mp > 0 then
                    battler.chara:setMana(battler.chara:getMana() - action.mp)
                elseif action.mp < 0 then
                    battler.chara:setMana(battler.chara:getMana() + action.mp)
                end
            end
            if action.stock and action.resource == "stock" then
                battler.chara:removeStock(action.data, 1)
            end
            if action.hp and action.resource == "health" then
                if action.hp > 0 then
                    battler.chara:heal(-action.hp)
                elseif action.hp < 0 then
                    self:hurt(-action.hp, true, battler)
                end
            end
        --end

        if action.action == "SKIP" and action.reason then
            anim = action.reason:lower()
        end

        if (action.action == "ITEM" and action.data and (not action.data.instant)) or (action.action ~= "ITEM") then
            battler:setAnimation("battle/"..anim.."_ready")
            action.icon = anim
        end
    end
end

function Battle:removeSingleAction(action)
    local battler = self.party[action.character_id]

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionUndo, action, action.action, battler, action.target) then
        battler.action = nil
        self.character_actions[action.character_id] = nil
        return
    end

    battler:resetSprite()


    if action.tp --[[or (action.tp and action.action == "SPELL" and]] and (action.resource == "tension" or action.action == "DEFEND") then
        if action.tp < 0 then
            Game:giveTension(-action.tp)
        elseif action.tp > 0 then
            Game:removeTension(action.tp)
        end
    end

    if action.mp and action.resource == "mana" then
        if action.mp < 0 then
            battler.chara:setMana(battler.chara:getMana() - action.mp)
        elseif action.mp > 0 then
            battler.chara:setMana(battler.chara:getMana() + action.mp)
        end
    end

    if action.hp and action.resource == "health" then
        if action.hp < 0 then
            self:hurt(action.hp, true, battler)
        elseif action.hp > 0 then
            battler.chara:heal(action.hp)
        end
    end

    if action.action == "ITEM" and action.data then
        if action.item_index and action.consumed then
            if action.result_item then
                Game.inventory:setItem(action.item_storage, action.item_index, action.data)
            else
                Game.inventory:addItemTo(action.item_storage, action.item_index, action.data)
            end
        end
        action.data:onBattleDeselect(battler, action.target)
    elseif action.action == "SPELL" and action.data then
        action.data:onDeselect(battler, action.target)
    end

    battler.action = nil
    self.character_actions[action.character_id] = nil
end

function Battle:nextTurn()

    super.nextTurn(self)

    for _,battler in ipairs(self.party) do
        if battler.chara:getManaMode() == "gotr" and self.turn_count == 1 then
            battler.chara:setMana(0)
        end
        battler.hit_count = 0
        if (battler.chara:getHealth() > 0) and (battler.chara:canAutoRegenMana() or (battler.chara:canAutoRegenMana() and battler.chara:getManaMode() == "gotr")) and self.turn_count > 1 and battler.chara:usesMana() and not battler.revived_this_turn then
            battler:regenMana(battler.chara:autoRegenManaAmount())
        end
        battler.action = nil
        battler.chara:setResourceUsed(battler.chara:getMainSpellResourceType())       --Resets the resource_used variable to the character's default just to be safe.
        battler.revived_this_turn = false
    end
end

function Battle:updateTransitionOut()

    super.updateTransitionOut(self)

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = MathUtils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = MathUtils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
-------------------------------------------------------------------
        if battler.chara:getManaMode() == "gotr" then
            battler.chara:setMana(0)
        end
-------------------------------------------------------------------
    end
end

--- Returns the equipment-modified mana regeneration amount from a man regen action performed by the specified party member
---@param base_regen number      The regen amount to modify
---@param regener PartyMember    The character performing the heal action
function Battle:applyManaRegenBonuses(base_regen, regener)
    local current_regen = base_regen
    for _,battler in ipairs(self.party) do
        for _,item in ipairs(battler.chara:getEquipment()) do
            current_regen = item:applyHealBonus(current_regen, base_regen,regener)
        end
    end
    return current_regen
end

return Battle