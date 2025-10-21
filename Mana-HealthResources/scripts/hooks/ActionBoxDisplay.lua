local ActionBoxDisplay, super = Class(ActionBoxDisplay)

function ActionBoxDisplay:init(actbox, x, y)
    super.init(self, x, y)

    self.font = Assets.getFont("smallnumbers")

    self.actbox = actbox

end


function ActionBoxDisplay:draw()

    if self.actbox.battler.chara:usesMana() then
        if Game.battle.current_selecting == self.actbox.index then
            Draw.setColor(self.actbox.battler.chara:getColor())
        else
            Draw.setColor(PALETTE["action_strip"], 1)
        end

        love.graphics.setLineWidth(2)
        love.graphics.line(0  , Game:getConfig("oldUIPositions") and 2 or 1, 213, Game:getConfig("oldUIPositions") and 2 or 1)

        love.graphics.setLineWidth(2)
        if Game.battle.current_selecting == self.actbox.index then
            love.graphics.line(1  , 2, 1,   36)
            love.graphics.line(212, 2, 212, 36)
        end

        Draw.setColor(PALETTE["action_fill"])
        love.graphics.rectangle("fill", 2, Game:getConfig("oldUIPositions") and 3 or 2, 209, Game:getConfig("oldUIPositions") and 34 or 35)

        Draw.setColor(PALETTE["action_health_bg"])
        love.graphics.rectangle("fill", 125, 6 - self.actbox.data_offset, 81, 12)

        local health = (self.actbox.battler.chara:getHealth() / self.actbox.battler.chara:getStat("health")) * 82

        if health > 0 then
            Draw.setColor(self.actbox.battler.chara:getColor())
            love.graphics.rectangle("fill", 125, 6 - self.actbox.data_offset, math.ceil(health), 12)
        end

        ----------------- Draw mana bar -----------------------------
        Draw.setColor(COLORS["dkgray"])
        love.graphics.rectangle("fill", 125, 22 - self.actbox.data_offset, 81, 12)

        local mana = (self.actbox.battler.chara:getMana() / self.actbox.battler.chara:getStat("mana")) * 82

        if mana > 0 then

            Draw.setColor(30/255, 144/255, 1)
            love.graphics.rectangle("fill", 125, 22 - self.actbox.data_offset, math.ceil(mana), 12)
            --Draw.setColor(COLORS["navy"])
            --love.graphics.rectangle("fill", 125, 26 - self.actbox.data_offset, math.ceil(mana), 4)
        end
        --------------------------------------------------------------

        local color = PALETTE["action_health_text"]
        if health <= 0 then
            color = PALETTE["action_health_text_down"]
        elseif (self.actbox.battler.chara:getHealth() <= (self.actbox.battler.chara:getStat("health") / 4)) then
            color = PALETTE["action_health_text_low"]
        else
            color = PALETTE["action_health_text"]
        end

        local health_offset = 0
        local mana_offset = 0
        health_offset = (#tostring(self.actbox.battler.chara:getHealth()) - 1) * 8
        mana_offset = (#tostring(self.actbox.battler.chara:getMana()) - 1) * 8

        local string_width_health = self.font:getWidth(tostring(self.actbox.battler.chara:getStat("health")))
        local string_width_mana = self.font:getWidth(tostring(self.actbox.battler.chara:getStat("mana")))

        love.graphics.setFont(self.font)

        --Draw the black translucent outlines
        local outline_canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_WIDTH)

            Draw.getOutlineDraft(self.actbox.battler.chara:getHealth(), 183 - health_offset - string_width_health, 7 - self.actbox.data_offset)
            Draw.getOutlineDraft("/", 192 - string_width_health, 7 - self.actbox.data_offset)
            Draw.getOutlineDraft(self.actbox.battler.chara:getStat("health"), 207 - string_width_health, 7 - self.actbox.data_offset)

            Draw.getOutlineDraft(self.actbox.battler.chara:getMana(), 183 - mana_offset - string_width_mana, 23 - self.actbox.data_offset)
            Draw.getOutlineDraft("/", 192 - string_width_mana, 23 - self.actbox.data_offset)
            Draw.getOutlineDraft(self.actbox.battler.chara:getStat("mana"), 207 - string_width_mana, 23 - self.actbox.data_offset)

            Draw.setColor(COLORS["black"], 0.5)
            Draw.popCanvas()

        Draw.drawCanvas(outline_canvas)

        Draw.setColor(color)
        love.graphics.print(self.actbox.battler.chara:getHealth(), 183 - health_offset - string_width_health, 7 - self.actbox.data_offset)
        Draw.setColor(PALETTE["action_health_text"])
        love.graphics.print("/", 192 - string_width_health, 7 - self.actbox.data_offset)
        Draw.setColor(color)
        love.graphics.print(self.actbox.battler.chara:getStat("health"), 207 - string_width_health, 7 - self.actbox.data_offset)


        Draw.setColor(COLORS["white"])
        love.graphics.print(self.actbox.battler.chara:getMana(), 183 - mana_offset - string_width_mana, 23 - self.actbox.data_offset)
        Draw.setColor(COLORS["white"])
        love.graphics.print("/", 192 - string_width_mana, 23 - self.actbox.data_offset)
        Draw.setColor(COLORS["white"])
        love.graphics.print(self.actbox.battler.chara:getStat("mana"), 207 - string_width_mana, 23 - self.actbox.data_offset)

        super.super.draw(self)
    else super.draw(self)
    end

end

return ActionBoxDisplay