local class = require "lib/middleclass"
local eAI = class('eAI', AI)

local _settings = {
    maxSwitchingSchedulesCounter = 4,
    thinkIntervalMin = 0.2,
    thinkIntervalMax = 0.35,
    hesitateMin = 0.2,
    hesitateMax = 0.5,
    waitChance = 0.34
}

function eAI:initialize(unit, settings)
    AI.initialize(self, unit, settings or _settings)
    -- new or overridden AI schedules
    self.tacticsWalkAround = {
        --self.SCHEDULE_ATTACK_FROM_BACK,
        --self.SCHEDULE_WALK_CLOSE_TO_ATTACK,
        self.SCHEDULE_WALK_RANDOM,
        self.SCHEDULE_WALK_AROUND,
        self.SCHEDULE_GET_TO_BACK,
        self.SCHEDULE_WALK_BY_TARGET_V,
        self.SCHEDULE_WALK_BY_TARGET_H,
        self.SCHEDULE_WAIT_SHORT,
        --self.SCHEDULE_ESCAPE_BACK,    --
        self.SCHEDULE_WALK_TO_MEDIUM_DISTANCE,
        self.SCHEDULE_WALK_TO_SHORT_DISTANCE,
        self.SCHEDULE_WALKING_SPEED_UP,
        self.SCHEDULE_WALKING_SPEED_DOWN,
        --self.SCHEDULE_WALK_OVER_TO_MEDIUM_DISTANCE,   --
        --self.SCHEDULE_WALK_OVER_TO_LONG_DISTANCE,  ---
    }
    self.tacticsWalkToAttack = {
        self.SCHEDULE_ATTACK_FROM_BACK,
        self.SCHEDULE_WALK_CLOSE_TO_ATTACK,
        self.SCHEDULE_WALKING_SPEED_UP,
    }
end

function eAI:selectNewSchedule(conditions)
    self.unit.b.reset()
    if not self.currentSchedule or conditions.init then
        self:setSchedule( self.SCHEDULE_INTRO )
        return
    end
    if not conditions.cannotAct then
        if self.currentSchedule ~= self.SCHEDULE_RUN_DASH_ATTACK
            and conditions.canMove and conditions.tooFarToTarget
            and love.math.random() < 0.25
        then
            self:setSchedule( self.SCHEDULE_RUN_DASH_ATTACK )
            return
        end
        if conditions.faceNotToPlayer then
            self:setSchedule( self.SCHEDULE_FACE_TO_PLAYER )
            return
        end
        if conditions.canMove and conditions.wokeUp or not conditions.noTarget then
            self.switchingSchedulesCounter = self.switchingSchedulesCounter + 1
            if self.switchingSchedulesCounter < self.maxSwitchingSchedulesCounter then
                self:setSchedule( self.tacticsWalkAround[ love.math.random(1, #self.tacticsWalkAround ) ])
                return
            else
                self.switchingSchedulesCounter = love.math.random( math.floor(0, self.maxSwitchingSchedulesCounter / 3) )
                self:setSchedule( self.tacticsWalkToAttack[ love.math.random(1, #self.tacticsWalkToAttack ) ])
                return
            end

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

    if not self.currentSchedule then
        self:setSchedule( self.SCHEDULE_STAND )
    end
end

return eAI
