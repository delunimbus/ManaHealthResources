---@class Battle : Class
---@overload fun(...) : Battle
local Battle, super = HookSystem.hookScript(Battle)

function Battle:addMenuItem(tbl)

    -- Item colors in Ch3+ can be dynamic (e.g. pacify) so we should use functions for item color.
    -- Table colors can still be used, but we'll wrap them into functions.
    local color = tbl.color or { 1, 1, 1, 1 }
    local fcolor
    if type(color) == "table" then
        fcolor = function() return color end
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
    --print(tbl.resource)
    table.insert(self.menu_items, tbl)
    return tbl
end

function Battle:canSelectMenuItem(menu_item)
    if menu_item.unusable then
        print("ewhbdw")
        return false
    end
    --print("menu_item resource: "..tostring(menu_item.resource))
    if menu_item.resource == "tension" and menu_item.tp and (menu_item.tp > Game:getTension()) then
        print("dsy")
        return false
    end
    if menu_item.resource == "mana" and menu_item.mp and ((menu_item.mp > self.party[self.current_selecting].chara:getMana()) or not self.party[self.current_selecting].chara:usesMana()) then
        print("rbe")
        return false
    end
    if menu_item.resource == "health" and menu_item.hp and (menu_item.hp >= self.party[self.current_selecting].chara:getHealth()) then
        print("unq")
        return false
    end
    if menu_item.party then
        for _, party_id in ipairs(menu_item.party) do
            local party_index = self:getPartyIndex(party_id)
            local battler = self.party[party_index]
            local action = self.character_actions[party_index]
            if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                print("yedbh")
                return false
            end
        end
    end
    --print("dewrs")
    return true
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
        for _, v in ipairs(data.party) do
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

    self:commitSingleAction(
        TableUtils.merge(
            {
                ["character_id"] = party_id,
                ["action"] = action_type:upper(),
                ["party"] = data.party,
                ["name"] = data.name,
                ["target"] = target,
                ["data"] = data.data,
                ["resource"] = data.resource,
                ["tp"] = tp_diff,
                ["mp"] = data.mp,
                ["hp"] = data.hp,
                ["cancellable"] = data.cancellable,
            },
            extra
        )
    )

    if data.party then
        for _, v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.act_parent then
                        self:removeAction(action.act_parent)
                    else
                        self:removeAction(index)
                    end
                end

                self:commitSingleAction(
                    TableUtils.merge(
                        {
                            ["character_id"] = index,
                            ["action"] = "SKIP",
                            ["reason"] = action_type:upper(),
                            ["name"] = data.name,
                            ["target"] = target,
                            ["data"] = data.data,
                            ["act_parent"] = party_id,
                            ["cancellable"] = data.cancellable,
                        },
                        extra
                    )
                )
            end
        end
    end
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

    if action.action == "SPELL" and action.data then
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
                print(action.mp)
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
            if action.mp and action.resource == "mana" then
                if action.mp > 0 then
                    battler.chara:setMana(battler.chara:getMana() - action.mp)
                elseif action.mp < 0 then
                    battler.chara:setMana(battler.chara:getMana() + action.mp)
                end
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

    if action.tp and (action.resource == "tension" or action.action == "DEFEND") then
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

--- Returns the equipment-modified mana regeneration amount from a man regen action performed by the specified party member
---@param base_regen number      The regen amount to modify
---@param regener PartyMember    The character performing the heal action
function Battle:applyManaRegenBonuses(base_regen, regener)
    local current_regen = base_regen
    for _,battler in ipairs(self.party) do
        for _,item in ipairs(battler.chara:getEquipment()) do
            current_regen = item:applyHealBonus(current_regen, base_regen, regener)
        end
    end
    return current_regen
end

return Battle