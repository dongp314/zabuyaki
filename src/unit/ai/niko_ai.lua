local class = require "lib/middleclass"
local eAI = class('eAI', AI)

local _settings = {
    thinkIntervalMin = 0.02,
    thinkIntervalMax = 0.25,
    hesitateMin = 0.1,
    hesitateMax = 0.3,
    waitChance = 0.5,
    jumpAttackChance = 0.5,
    grabChance = 0.5 -- 1 == 100%, 0 == 0%
}

function eAI:initialize(unit, settings)
    AI.initialize(self, unit, settings or _settings)
    -- new or overridden AI schedules
    self.SCHEDULE_JUMP_ATTACK = Schedule:new(
        { self.emulateJumpPressToTarget,
          self.emulateWaitStart,
          self.emulateWait,
          self.emulateAttackPress,
          self.emulateReleaseButtons },
        { }
    )
end

function eAI:_update(dt)
    --    if self.thinkInterval - dt <= 0 then
    --print(inspect(self.conditions, {depth = 1, newline ="", ident=""}))
    --    end
    AI.update(self, dt)
end

function eAI:selectNewSchedule(conditions)
    if not self.currentSchedule or conditions.init then
        --        print("NIKO INTRO", self.unit.name, self.unit.id )
        self:setSchedule( self.SCHEDULE_INTRO )
        return
    end
    if conditions.noPlayers then
        self:setSchedule( self.SCHEDULE_WALK_OFF_THE_SCREEN )
        return
    end
    if not conditions.cannotAct then
        if conditions.faceNotToPlayer then
            self:setSchedule( self.SCHEDULE_FACE_TO_PLAYER )
            return
        end
        if self.currentSchedule ~= self.SCHEDULE_WAIT_MEDIUM and love.math.random() < self.waitChance then
            self:setSchedule( self.SCHEDULE_WAIT_MEDIUM )
            return
        end
        if conditions.canJumpAttack and love.math.random() < self.jumpAttackChance then
            self:setSchedule( self.SCHEDULE_JUMP_ATTACK )
            return
        end
        if conditions.canCombo then
            if conditions.canMove and conditions.tooCloseToPlayer then --and love.math.random() < 0.5
                self:setSchedule( self.SCHEDULE_ESCAPE_BACK )
                return
            end
            self:setSchedule( self.SCHEDULE_COMBO )
            return
        end
        if conditions.canMove and conditions.canGrab then
            if love.math.random() < self.grabChance then
                self:setSchedule( self.SCHEDULE_GRAB )
            else
                self:setSchedule( self.SCHEDULE_ESCAPE_BACK )
            end
            return
        end
        if conditions.canMove and conditions.tooCloseToPlayer then --and love.math.random() < 0.5
            self:setSchedule( self.SCHEDULE_ESCAPE_BACK )
            return
        end
        if conditions.canMove and conditions.wokeUp or not conditions.noTarget then
            --if love.math.random() < self.grabChance then
            --    self:setSchedule( self.SCHEDULE_WALK_TO_GRAB )
            --else
                if love.math.random() < 0.5 then
                    self:setSchedule( self.SCHEDULE_WALK_CLOSE_TO_ATTACK )
                else
                    self:setSchedule( self.SCHEDULE_WALK_AROUND )
                end
            --end
            return
        end
        if not conditions.dead and not conditions.cannotAct and conditions.wokeUp then
            if self.currentSchedule ~= self.SCHEDULE_STAND then
                self:setSchedule( self.SCHEDULE_STAND )
            else
                self:setSchedule( self.SCHEDULE_WAIT_MEDIUM )
            end
            return
        end
    else
        -- cannot control body
        self:setSchedule( self.SCHEDULE_RECOVER )
        return
    end
    self:setSchedule( self.SCHEDULE_STAND )
end

return eAI
