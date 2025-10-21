local ActionBox, super = Class(ActionBox)

function ActionBox:init(x, y, index, battler)
    super.init(self, x, y, index, battler)

    self.mp_sprite = Sprite("ui/mp", 107, 7)
    self.box:addChild(self.mp_sprite)

    self.mp_sprite.visible = false

end

function ActionBox:update()
    if self.battler.chara:usesMana() then

        self.selection_siner = self.selection_siner + 2 * DTMULT

        if Game.battle.current_selecting == self.index then
            if self.box.y > -32 then self.box.y = self.box.y - 2 * DTMULT end
            if self.box.y > -24 then self.box.y = self.box.y - 4 * DTMULT end
            if self.box.y > -16 then self.box.y = self.box.y - 6 * DTMULT end
            if self.box.y > -8  then self.box.y = self.box.y - 8 * DTMULT end
            -- originally '= -64' but that was an oversight by toby
            if self.box.y < -32 then self.box.y = -32 end
        elseif self.box.y < -14 then
            self.box.y = self.box.y + 15 * DTMULT
        else
            self.box.y = 0
        end

        self.head_sprite.y = 11 - self.data_offset + self.head_offset_y
        if self.name_sprite then
            self.name_sprite.y = 14 - self.data_offset
        end
        self.hp_sprite.x = 107
        self.hp_sprite.y = 8 - self.data_offset

        self.mp_sprite.visible = true
        self.mp_sprite.y = 24 - self.data_offset

        if not self.force_head_sprite then
            local current_head = self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon()
            if not self.head_sprite:hasSprite(current_head) then
                current_head = self.battler.chara:getHeadIcons().."/head"
            end

            if not self.head_sprite:isSprite(current_head) then
                self.head_sprite:setSprite(current_head)
            end
        end

        for i,button in ipairs(self.buttons) do
            if (Game.battle.current_selecting == self.index) then
                button.selectable = true
                button.hovered = (self.selected_button == i)
            else
                button.selectable = false
                button.hovered = false
            end
        end

    super.super.update(self)

else
    super.update(self) end
end

return ActionBox