local class = require "lib/middleclass"
local AI = class('AI')

local dist = dist

function AI:initialize(unit, settings)
    self.unit = unit
    if not settings then
        settings = {}
    end
    self.thinkIntervalMin = settings.thinkIntervalMin or 0.01
    self.thinkIntervalMax = settings.thinkIntervalMax or 0.25
    self.hesitateMin = settings.hesitateMin or 0.1 -- hesitation delay before combo
    self.hesitateMax = settings.hesitateMax or 0.3

    self.reactCloseDistanceMin = settings.reactCloseDistanceMin or 0
    self.reactCloseDistanceMax = settings.reactCloseDistanceMax or 49
    self.reactMiddleDistanceMin = settings.reactMiddleDistanceMin or 50
    self.reactMiddleDistanceMax = settings.reactMiddleDistanceMax or 69
    self.reactFarDistanceMin = settings.reactFarDistanceMin or 70
    self.reactFarDistanceMax = settings.reactFarDistanceMax or 240  -- should be more?

    self.waitChance = settings.waitChance or 0.2 -- 1 == 100%, 0 == 0%
    self.waitMin = settings.waitMin or 1 -- minimal delay for the waiting ai pattern
    self.waitMax = settings.waitMax or 3
    self.jumpAttackChance = settings.jumpAttackChance or 0.2 -- 1 == 100%, 0 == 0%
    self.grabChance = settings.grabChance or 0.5 -- 1 == 100%, 0 == 0%
    self.switchTargetToAttackerChance = settings.switchTargetToAttackerChance or 0.25 -- 1 == 100%, 0 == 0%

    self.canDashMin = settings.canDashMin or 30 -- min horizontal dist in px to Dash
    self.canDashMax = settings.canDashMax or 100 -- max horizontal dist in px to Dash
    self.canJumpAttackMin = settings.canJumpAttackMin or 60 -- min horizontal dist in px to JumpAttack
    self.canJumpAttackMax = settings.canJumpAttackMax or 100 -- max horizontal dist in px to JumpAttack
    self.tooFarToTarget = settings.tooFarToTarget or 150 -- min dist to generate "tooFarToTarget" condition

    self.conditions = {}
    self.thinkInterval = 0
    self.hesitate = 0
    self.currentSchedule = nil

    self.SCHEDULE_INTRO = Schedule:new({ self.initIntro, self.onIntro },
        { "seePlayer", "wokeUp", "tooCloseToPlayer" }, unit.name)
    self.SCHEDULE_STAND = Schedule:new({ self.initStand, self.onStand },
        { "cannotAct", "seePlayer", "wokeUp", "noTarget", "canCombo", "canGrab", "canDash", "inAir",
            "faceNotToPlayer", "tooCloseToPlayer" }, unit.name)
    self.SCHEDULE_WAIT = Schedule:new({ self.initWait, self.onWait },
        { "noTarget", "tooCloseToPlayer", "tooFarToTarget" }, unit.name)
    -- deprecated
    --self.__SCHEDULE_WALK_TO_ATTACK = Schedule:new({ self.calcWalkToAttackXY, self.initWalkToXY, self.onMove, self.initCombo, self.onCombo },
    --    { "cannotAct", "inAir", "grabbed", "noTarget", "tooCloseToPlayer" }, unit.name)
    -- outdated
    --self.SCHEDULE_WALK = Schedule:new({ self.calcWalkToAttackXY, self.initWalkToXY, self.onMove },
    --    { "cannotAct", "inAir", "noTarget", "tooCloseToPlayer" }, unit.name)
    self.SCHEDULE_WALK_OFF_THE_SCREEN = Schedule:new({ self.calcWalkOffTheScreenXY, self.initWalkToXY, self.onMove, self.onStop },
        {}, unit.name)
    self.SCHEDULE_WALK_CLOSE_TO_ATTACK = Schedule:new({ self.initWalkCloser, self.onWalkToAttackRange, self.initCombo, self.onCombo },
        { "cannotAct", "inAir", "grabbed", "noTarget" }, unit.name)
    self.SCHEDULE_ATTACK_FROM_BACK = Schedule:new({ self.initGetToBack, self.onGetToBack, self.initCombo, self.onCombo  },
        { "cannotAct", "inAir", "grabbed", "noTarget" }, unit.name)
    self.SCHEDULE_WALK_AROUND = Schedule:new({ self.initWalkAround, self.onWalkAround },
        { "cannotAct", "inAir", "grabbed", "noTarget" }, unit.name)
    self.SCHEDULE_GET_TO_BACK = Schedule:new({ self.initGetToBack, self.onGetToBack },
        { "cannotAct", "inAir", "grabbed", "noTarget" }, unit.name)
    self.SCHEDULE_STEP_BACK = Schedule:new({ self.calcWalkToBackOffXY, self.initWalkToXY, self.onMove },
        { "cannotAct", "inAir", "noTarget" }, unit.name)
    self.SCHEDULE_RUN = Schedule:new({ self.calcRunToXY, self.initRunToXY, self.onMove },
        { "cannotAct", "noTarget", "cannotAct", "inAir" }, unit.name)
    self.SCHEDULE_DASH = Schedule:new({ self.initDash, self.waitUntilStand, self.initWait, self.onWait },
        { }, unit.name)
    self.SCHEDULE_RUN_DASH = Schedule:new({ self.calcRunToXY, self.initRunToXY, self.onMove, self.initDash },
        { }, unit.name)
    self.SCHEDULE_FACE_TO_PLAYER = Schedule:new({ self.initFaceToPlayer },
        { "cannotAct", "noTarget", "noPlayers" }, unit.name)
    self.SCHEDULE_COMBO = Schedule:new({ self.initCombo, self.onCombo },
        { "cannotAct", "grabbed", "inAir", "noTarget", "tooFarToTarget", "tooCloseToPlayer" }, unit.name)
    self.SCHEDULE_GRAB = Schedule:new({ self.initGrab, self.onGrab },
        { "cannotAct", "grabbed", "inAir", "noTarget", "noPlayers" }, unit.name)
    self.SCHEDULE_WALK_TO_GRAB = Schedule:new({ self.calcWalkToGrabXY, self.initWalkToXY, self.onMove, self.initGrab, self.onGrab },
        { "cannotAct", "grabbed", "inAir", "noTarget", "noPlayers" }, unit.name)
    self.SCHEDULE_RECOVER = Schedule:new({ self.waitUntilStand },
        { "noPlayers" }, unit.name)
end

function AI:update(dt)
    if self.unit.isDisabled or self.unit.hp <= 0 then
        return
    end
    self.thinkInterval = self.thinkInterval - dt
    if self.thinkInterval <= 0 then
        self.conditions = self:getConditions()
        if not self.conditions.cannotAct then
            if not self.currentSchedule or self.currentSchedule:isDone(self.conditions) then
                self:selectNewSchedule(self.conditions)
            end
        end
        self.thinkInterval = self.thinkIntervalMin + love.math.random() * (self.thinkIntervalMax - self.thinkIntervalMin)
    end
    -- run current schedule
    if self.currentSchedule then
        self.currentSchedule:update(self, dt)
    end
    if isDebug() and self.unit.ttx then
        attackHitBoxes[#attackHitBoxes+1] = {x = self.unit.ttx, sx = 0, y = self.unit.tty, w = 31, h = 0.1, z = 0 }
    end
end

-- should be overridden by every enemy AI class
function AI:selectNewSchedule(conditions)
    if not self.currentSchedule then
        self.currentSchedule = self.SCHEDULE_INTRO
        return
    end
    self.currentSchedule = self.SCHEDULE_STAND
end

function AI:getConditions()
    local u = self.unit
    local conditions = {}
    if u.isDisabled or u.state == "fall" then
        conditions["dead"] = true
        conditions["cannotAct"] = true
    else
        if u.target and u.target.isDisabled then
            conditions["targetDead"] = true
        end
        if u.isGrabbed then
            conditions["grabbed"] = true
        end
        if u.z > 0 then  --TODO on a panel?
            conditions["inAir"] = true
        end
        conditions = self:getVisualConditions(conditions)
    end
    if countAlivePlayers() < 1 then
        conditions["noPlayers"] = true
    end
    return conditions
end

local canAct = { stand = true, walk = true, run = true, intro = true }
function AI:getVisualConditions(conditions)
    -- check attack range, players, units etc
    local u = self.unit
    local t
    if not canAct[u.state] then
        conditions["cannotAct"] = true
    elseif u:canMove() then
        conditions["canMove"] = true
    end
    if canAct[u.state] then
        if not u.target then
            conditions["noTarget"] = true
        else
            local x, y = u.target.x, u.target.y
            -- facing to the player
            if x < u.x - u.width / 2 then
                if u.face < 0 then
                    conditions["faceToPlayer"] = true
                else
                    conditions["faceNotToPlayer"] = true
                end
                if u.target.face < 0 then
                    conditions["playerBack"] = true
                else
                    conditions["playerSeeYou"] = true
                end
            elseif x > u.x + u.width / 2 then
                if u.face > 0 then
                    conditions["faceToPlayer"] = true
                else
                    conditions["faceNotToPlayer"] = true
                end
                if u.target.face > 0 then
                    conditions["playerBack"] = true
                else
                    conditions["playerSeeYou"] = true
                end
            end
            t = dist(x, y, u.x, u.y)
            if t >= self.reactCloseDistanceMin and t <= self.reactCloseDistanceMax then
                conditions["reactCloseTarget"] = true
            end
            if t >= self.reactMiddleDistanceMin and t <= self.reactMiddleDistanceMax then
                conditions["reactMiddleTarget"] = true
            end
            if t >= self.reactFarDistanceMin and t <= self.reactFarDistanceMax then
                conditions["reactFarTarget"] = true
            end
            if t < self.canDashMax and t >= self.canDashMin
                and math.floor(u.y / 4) == math.floor(y / 4) then
                conditions["canDash"] = true
            end
            local attackRange = self:getAttackRange(u, u.target)
            if math.abs(u.x - x) <= attackRange
                and math.abs(u.y - y) <= 6
                and ((u.x - u.width / 2 > x and u.face == -1) or (u.x + u.width / 2 < x and u.face == 1))
                and u.target.hp > 0 then
                conditions["canCombo"] = true
            end
            if t < self.canJumpAttackMax and t >= self.canJumpAttackMin
                and math.abs(u.y - y ) <= u.width * 4 then
                conditions["canJumpAttack"] = true
            end
            if math.abs(u.x - x) <= u.width
                and math.abs(u.y - y) <= 6
                and not u.target:isInvincible()
            then
                conditions["canGrab"] = true
            end
            if t > self.tooFarToTarget then
                conditions["tooFarToTarget"] = true
            end
        end
        t = u:getDistanceToClosestPlayer()
        if t < u.width then
            -- too close to the closest player
            conditions["tooCloseToPlayer"] = true
        end
        if t < u.wakeRange then
            -- see near players?
            conditions["seePlayer"] = true
        end
        if t < u.delayedWakeRange and u.time > u.wakeDelay then
            -- ready to act
            conditions["wokeUp"] = true
        end

        if t >= self.reactCloseDistanceMin and t <= self.reactCloseDistanceMax then
            conditions["reactClosePlayer"] = true
        end
        if t >= self.reactMiddleDistanceMin and t <= self.reactMiddleDistanceMax then
            conditions["reactMiddlePlayer"] = true
        end
        if t >= self.reactFarDistanceMin and t <= self.reactFarDistanceMax then
            conditions["reactFarPlayer"] = true
        end
    end
    return conditions
end

function AI:getAttackRange(unit, target)
    return unit.width / 2 + target.width / 2 + 12
end

function AI:getSafeWalkingRadius(unit, target) -- radius bigger than an attack range
    return self:getAttackRange(unit, target) * ( 1.2 + love.math.random() )
end

function AI:canAct()
    return not self.conditions.inAir and not self.conditions.cannotAct
end

function AI:canActAndMove()
    return self.conditions.canMove and self:canAct()
end

function AI:initIntro()
    local u = self.unit
    u.b.reset()
    if self:canAct() then
        if u.state == "stand" or u.state == "intro" then
            return true
        end
    end
    return false
end

function AI:onIntro()
    local u = self.unit
    if not u.target then
        u:pickAttackTarget("random")
    elseif u.target.isDisabled or u.target.hp < 1 then
        u:pickAttackTarget("close")
    end
    return false
end

function AI:initStand()
    local u = self.unit
    u.b.reset()
    if self:canActAndMove() then
        assert(not u.isDisabled and u.hp > 0)
        return true
    end
    return false
end

function AI:onStand()
    local u = self.unit
    if not u.target then
        u:pickAttackTarget("close")
    elseif u.target.isDisabled or u.target.hp < 1 then
        u:pickAttackTarget("random")
    end
    u.speed_x = u.runSpeed
    u.speed_y = 0
    return false
end

function AI:initWait()
    local u = self.unit
    u.b.reset()
    if self:canActAndMove() then
        assert(not u.isDisabled and u.hp > 0)
        self.waitingCounter = love.math.random() * (self.waitMax - self.waitMin) + self.waitMin
        u.speed_x = u.runSpeed
        u.speed_y = 0
        return true
    end
    return false
end

function AI:onWait(dt)
    local u = self.unit
    self.waitingCounter = self.waitingCounter - dt
    if self.waitingCounter < 0 then
--        print(" -> DONE Wait> : " .. self.waitingCounter, u.name)
        if love.math.random() < 0.20 then
            u:pickAttackTarget("random")
        end
        return true
    end
    return false
end

function AI:calcWalkToBackOffXY()
    local u = self.unit
    if not self.conditions.canMove or u.state ~= "stand" then
        return false
    end
    if not u.target or u.target.hp < 1 then
        u:pickAttackTarget("close")
    end
    assert(not u.isDisabled and u.hp > 0)
    local shift_x, shift_y = love.math.random(0, 6), love.math.random(0, 6)
    if u.target.hp < u.target.maxHp / 2 then
        shift_x = shift_x + u.width
    end
    u.horizontal = u.x < u.target.x and 1 or -1
    u.ttx = u.target.x + (u.width * 5 + shift_x) * -u.horizontal
    u.tty = u.target.y + love.math.random(-1, 1) * shift_y
    return true
end

function AI:initWalkToXY()
    local u = self.unit
    u.b.reset()
    if self:canActAndMove() then
        assert(not u.isDisabled and u.hp > 0)
        u.speed_x = u.walkSpeed
        u.old_x = 0
        u.old_y = 0
        return true
    end
    return false
end

function AI:initRunToXY()
    local u = self.unit
    u.b.reset()
    if self:canActAndMove() then
        assert(not u.isDisabled and u.hp > 0)
        u.b.doHorizontalDoubleTap()
        u.speed_x = u.runSpeed
        u.old_x = 0
        u.old_y = 0
        return true
    end
    return false
end

function AI:calcWalkToAttackXY()
    local u = self.unit
    if not u.target or u.target.hp < 1 then
        u:pickAttackTarget("close")
        if not u.target then
            return false
        end
    end
    assert(not u.isDisabled and u.hp > 0)
    local tx, ty
    if love.math.random() < 0.25 then
        --get above / below the player
        tx = u.target.x
        if love.math.random() < 0.5 then
            ty = u.target.y + 16
        else
            ty = u.target.y - 16
        end
    else
        --get to the player attack range
        if u.x < u.target.x and love.math.random() < 0.8 then
            tx = u.target.x - love.math.random(30, 34)
            ty = u.target.y + 1
        else
            tx = u.target.x + love.math.random(30, 34)
            ty = u.target.y + 1
        end
    end
    u.ttx, u.tty = tx, ty
    u.old_x = 0
    u.old_y = 0
    return true
end

function AI:calcWalkOffTheScreenXY()
    local u = self.unit
    assert(not u.isDisabled and u.hp > 0)
    local tx, ty
    local walkPixels = 400
    ty = u.y + love.math.random(-1, 1) * 16
    u.horizontal = love.math.random() < 0.5 and 1 or -1
    tx = u.x + u.horizontal * walkPixels
    u.face = u.horizontal
    u.ttx, u.tty = tx, ty
    return true
end

function AI:initWalkCloser()
    local u = self.unit
    u.b.reset()
    if not u.target or u.target.hp < 1 then
        u:pickAttackTarget("close")
        if not u.target then
            return false
        end
    end
    assert(not u.isDisabled and u.hp > 0)
    return true
end

function AI:onWalkToAttackRange()
    local horizontalToleranceGap = 4
    local verticalToleranceGap = 3
    local u = self.unit
    local attackRange = self:getAttackRange(u, u.target) - horizontalToleranceGap
    local v, h
    --get to the player attack range
    if u.x < u.target.x then
        h, v = signDeadzone( (u.target.x - attackRange)- u.x, horizontalToleranceGap ), signDeadzone( u.target.y - u.y, verticalToleranceGap )
    else
        h, v = signDeadzone( (u.target.x + attackRange) - u.x, horizontalToleranceGap), signDeadzone( u.target.y - u.y, verticalToleranceGap )
    end
    u.b.setHorizontalAndVertical( h, v )
    if u.x < u.target.x - horizontalToleranceGap then
        u.face = 1
    elseif u.x > u.target.x + horizontalToleranceGap then
        u.face = -1
    end
    if h == 0 and v == 0 then
        u.b.reset()
        return true
    end
    return false
end

local function getPosByAngleR(x, y, angle, r)
    return x + math.cos( angle ) * r,
        y + math.sin( angle ) * r / 2
end

function AI:initWalkAround()
    local u = self.unit
    --    dp("AI:initWalkAround() " .. u.name)
    if not u.target or u.target.hp < 1 then
        u:pickAttackTarget("close")
        if not u.target then
            return false
        end
    end
    u.chaseTime = 3 + love.math.random( 5 )
    u.chaseRadius = self:getSafeWalkingRadius(u, u.target)
    if love.math.random() < 0.3 then    -- go to front
        u.chaseAngle = love.math.random() * math.pi / 4 - math.pi / 8
    else    -- go from back
        u.chaseAngle = math.pi - love.math.random() * math.pi / 4 - math.pi / 8
    end
    u.chaseAngleStep = (math.pi / 9) * ( love.math.random() <= 0.5 and 1 or -1 )
    u.chaseAngleLockTime = 0
    u.old_x = 0
    u.old_y = 0
    u.ttx, u.tty = getPosByAngleR( u.target.x, u.target.y, u.chaseAngle, u.chaseRadius)
    assert(not u.isDisabled and u.hp > 0)
    return true
end

function AI:onWalkAround(dt)
    local u = self.unit
    --    dp("AI:onWalkAround() ".. u.name)
    local attackRange = self:getAttackRange(u, u.target)
    local v, h
    if u.x == u.old_x and u.y == u.old_y and u.chaseAngleLockTime > 0.2 then
        --print(getDebugFrame(), "step STOP STUCK", u.chaseAngle)
        u.b.setHorizontalAndVertical( 0, 0 )
        u.b.reset()
        return true
    end
    h, v = signDeadzone( u.ttx - u.x, 4 ), signDeadzone( u.tty - u.y, 2 )
    if v == 0 and h == 0 and u.chaseAngleLockTime > 0.1 then
        -- got to the point, rotate to the next
        u.chaseAngle = u.chaseAngle + u.chaseAngleStep
        u.ttx, u.tty = getPosByAngleR( u.target.x, u.target.y, u.chaseAngle, u.chaseRadius)
        h, v = signDeadzone( u.ttx - u.x, 4 ), signDeadzone( u.tty - u.y, 2 )
        u.chaseAngleLockTime = 0
        --print(getDebugFrame(),v,h,u.x,u.old_x,u.y,u.old_y, u.target.x, u.target.y)
    end
    u.b.setHorizontalAndVertical( h, v )
    u.b.setStrafe( true )
    if u.chaseAngleLockTime > 0.5 then  -- face to the target
        if u.x < u.target.x - 4 then
            u.face = 1
        elseif u.x > u.target.x + 4 then
            u.face = -1
        end
    end
    u.chaseTime = u.chaseTime - dt
    u.chaseAngleLockTime = u.chaseAngleLockTime + dt
    u.chaseRadius = u.chaseRadius - dt
    u.old_x = u.x
    u.old_y = u.y
    if u.chaseTime < 0 or u.chaseRadius < attackRange then
        u.b.reset()
        --print(getDebugFrame(), "end TIME or < RADIUS", u.chaseAngle)
        return true
    end
    return false
end

function AI:initGetToBack()
    local u = self.unit
    --    dp("AI:initGetToBack() " .. u.name)
    if not u.target or u.target.hp < 1 then
        u:pickAttackTarget("close")
        if not u.target then
            return false
        end
    end
    u.chaseTime = 2 + love.math.random( 2 )
    u.chaseRadius = u.target.width * 2 + u.width * 2 - 2

    if u.target.x < u.x then
        --go to left?
        if u.target.face == -u.face then
            --go to left around the target unit
            if u.target.y < u.y then
                -- go from below
                u.chaseAngle = math.pi / 2
                u.chaseAngleStep = math.pi / 6
            else    -- go above
                u.chaseAngle = -math.pi / 2
                u.chaseAngleStep = -math.pi / 6
            end
            u.chaseAngleFinal = u.chaseAngle + u.chaseAngleStep * 3
        else
            --u r already see its back
            u.chaseAngleStep = math.pi / 9
            u.chaseAngle = 0
            u.chaseAngleFinal = u.chaseAngle
        end
    else
        --go to right?
        if u.target.face == -u.face then
            --go to right around the target unit
            if u.target.y < u.y then
                -- go from below
                u.chaseAngle = math.pi / 2
                u.chaseAngleStep = -math.pi / 6
            else    -- go above
                u.chaseAngle = -math.pi / 2
                u.chaseAngleStep = math.pi / 6
            end
            u.chaseAngleFinal = u.chaseAngle + u.chaseAngleStep * 3
        else
            --u r already see its back
            u.chaseAngleStep = math.pi / 9
            u.chaseAngle = -math.pi
            u.chaseAngleFinal = u.chaseAngle
        end
    end
    u.chaseAngleLockTime = 0
    u.old_x = 0
    u.old_y = 0
    u.ttx, u.tty = getPosByAngleR( u.target.x, u.target.y, u.chaseAngle, u.chaseRadius)
    assert(not u.isDisabled and u.hp > 0)
    return true
end

function AI:onGetToBack(dt)
    local u = self.unit
    --    dp("AI:onGetToBack() ".. u.name)
    local attackRange = self:getAttackRange(u, u.target)
    local v, h
    if u.x == u.old_x and u.y == u.old_y and u.chaseAngleLockTime > 0.2 then
        --print(getDebugFrame(), "step STOP STUCK", u.chaseAngle)
        u.b.setHorizontalAndVertical( 0, 0 )
        u.b.reset()
        return true
    end
    h, v = signDeadzone( u.ttx - u.x, 4 ), signDeadzone( u.tty - u.y, 2 )
    if v == 0 and h == 0 and u.chaseAngleLockTime > 0.1 then
        -- got to the point, rotate to the next
        if math.abs(u.chaseAngleFinal - u.chaseAngle) < 0.01 then
            u.b.reset()
            return true
        end
        u.chaseAngle = u.chaseAngle + u.chaseAngleStep
        u.ttx, u.tty = getPosByAngleR( u.target.x, u.target.y, u.chaseAngle, u.chaseRadius)
        h, v = signDeadzone( u.ttx - u.x, 4 ), signDeadzone( u.tty - u.y, 2 )
        u.chaseAngleLockTime = 0
    end
    u.b.setHorizontalAndVertical( h, v )
    u.b.setStrafe( true )
    if u.chaseAngleLockTime > 0.5 then  -- face to the target
        if u.x < u.target.x - 4 then
            u.face = 1
        elseif u.x > u.target.x + 4 then
            u.face = -1
        end
    end
    u.chaseTime = u.chaseTime - dt
    u.chaseAngleLockTime = u.chaseAngleLockTime + dt
    u.chaseRadius = u.chaseRadius - dt
    u.old_x = u.x
    u.old_y = u.y
    if u.chaseTime < 0 or u.chaseRadius < attackRange then
        u.b.reset()
        --print(getDebugFrame(), "end TIME or < RADIUS", u.chaseAngle)
        return true
    end
    return false
end

function AI:onMove()
    local u = self.unit
    --    dp("AI:onMove() ".. u.name)
    if u.move then
        return u.move:update(0)
    else
        if u.old_x == u.x and  u.old_y == u.y then
            u.b.reset()
            return true
        else
            u.b.setHorizontalAndVertical( signDeadzone( u.ttx - u.x, 4 ), signDeadzone( u.tty - u.y, 2 ) )
        end
        u.old_x = u.x
        u.old_y = u.y
    end
    return false
end

function AI:calcRunToXY()
    local u = self.unit
    u.b.reset()
--    dp("AI:calcRunToXY() " .. u.name)
    if self:canActAndMove() then
        if not u.target or u.target.hp < 1 then
            u:pickAttackTarget() -- ???
        end
        assert(not u.isDisabled and u.hp > 0)
        --u:setState(u.run)
        local tx, ty
        if u.x < u.target.x then
            tx = u.target.x - love.math.random(25, 35)
            ty = u.y + 1 + love.math.random(-1, 1) * love.math.random(6, 8)
            u.face = 1
        else
            tx = u.target.x + love.math.random(25, 35)
            ty = u.y + 1 + love.math.random(-1, 1) * love.math.random(6, 8)
            u.face = -1
        end
        u.horizontal = u.face
        u.ttx, u.tty = tx, ty
        return true
    end
    return false
end

function AI:initFaceToPlayer()
    local u = self.unit
--    dp("AI:initFaceToPlayer() " .. u.name)
    if u.isHittable and self:canAct() then
        if not u.target or u.target.hp < 1 then
            u:pickAttackTarget() -- ???
        end
        if u.x < u.target.x then
            u.face = 1
        else
            u.face = -1
        end
        u.horizontal = u.face
        return true
    end
    return false
end

function AI:initCombo()
    self.hesitate = love.math.random() * (self.hesitateMax - self.hesitateMin) + self.hesitateMin
    --    dp("AI:initCombo() " .. u.name)
    self.unit.b.reset()
    return true
end

function AI:onCombo(dt)
    local u = self.unit
    self.hesitate = self.hesitate - dt
    --    dp("AI:onCombo() ".. u.name)
    if self.hesitate <= 0 then
        if not self:canAct() then
            return true
        end
        if self.conditions.canCombo and not self.conditions.inAir then
            u.b.setAttack( true )
        end
        return true
    end
    return false
end

function AI:initDash(dt)
    local u = self.unit
    u.b.reset()
    --    dp("AI:onDash() ".. u.name)
    --    if not self.conditions.cannotAct then
    if self:canActAndMove() then
        u:setState(u.dashAttack)
        return true
    end
    return false
end

function AI:waitUntilStand(dt)
--    dp("AI:waitUntilStand() ".. u.name)
    if self:canActAndMove() then
        return true
    end
    return false
end

function AI:initGrab()
    self.chanceToGrabAttack = 0
    local u = self.unit
--    dp("AI: INIT GRAB " .. u.name)
    if self:canActAndMove() then
        local grabbed = u:checkForGrab()
        if grabbed then
            if grabbed.type ~= "player" then
                --                print("AI: GRABBED NOT PLAYER" .. u.name)
                return true
            end
            if grabbed.face == -u.face and grabbed.sprite.curAnim == "chargeWalk" then
                --back off 2 simultaneous grabbers
                if u.x < grabbed.x then
                    u.horizontal = -1
                else
                    u.horizontal = 1
                end
                grabbed.horizontal = -u.horizontal
                u:showHitMarks(22, 25, 5) --big hitmark
                u.speed_x = u.backoffSpeed_x --move from source
                u:setSprite("hurtHighWeak")
                u:setState(u.slide)
                grabbed.speed_x = grabbed.backoffSpeed_x --move from source
                grabbed:setSprite("hurtHighWeak")
                grabbed:setState(grabbed.slide)
                u:playSfx(u.sfx.grabClash)
                --                print(" bad SLIDEOff")
                return true
            end
            if u.moves.grab and u:doGrab(grabbed) then
                local g = u.grabContext
                u.victimLifeBar = g.target.lifeBar:setAttacker(u)
                --                print(" GOOD DOGRAB")
                return true
            else
                --                print("FAIL DOGRAB")
            end
        end
    else
        --        print("ai.lua GRAB no STAND or WALK" )
    end
    return true
end

function AI:onGrab(dt)
    self.chanceToGrabAttack = self.chanceToGrabAttack + dt / 20
    local u = self.unit
    local g = u.grabContext
    --    dp("AI: ON GRAB ".. u.name)
    if not g.target or u.state == "stand" then
        -- initGrab action failed.
        return true
    end
    if u.moves.grabFrontAttack and g.target and g.target.isGrabbed
            and self.chanceToGrabAttack > love.math.random() then
        u:setState(u.grabFrontAttack)
        return true
    end
    return false
end

function AI:calcWalkToGrabXY()
    local u = self.unit
--    dp("AI:calcWalkToGrabXY() " .. u.name)
    if self:canActAndMove() then
        if not u.target or u.target.hp < 1 then
            u:pickAttackTarget("close")
            if not u.target then
                return false
            end
        end
        assert(not u.isDisabled and u.hp > 0)
        --get to the player grab range
        u.ttx, u.tty = u.target.x + love.math.random(9, 10) * ( u.x < u.target.x and -1 or 1), u.target.y + 1
        return true
    end
    return false
end

function AI:onStop()
    return false
end

function AI:onHurt(attacker)
    local u = self.unit
    if attacker and love.math.random() < self.switchTargetToAttackerChance then
        return u:pickAttackTarget(attacker)
    end
end

function AI:emulateWaitStart()
    local u = self.unit
    dp("AI:emulateWaitStart() ".. u.name)
    self.hesitate = 0.1
    return true
end

function AI:emulateWait(dt)
    local u = self.unit
    self.hesitate = self.hesitate - dt
    dp("AI:emulateWait() ".. u.name)
    if self.hesitate <= 0 then
        return true
    end
    return false
end

function AI:emulateAttackPress()
    local u = self.unit
    dp("AI:emulateAttackPress() ".. u.name)
    u.b.setAttack( true )
    return true
end

function AI:emulateJumpPress()
    local u = self.unit
    dp("AI:emulateJumpPress() ".. u.name)
    u.b.setJump( true )
    return true
end

function AI:emulateArrowsToTarget()
    local u = self.unit
    dp("AI:emulateArrowsToTarget() ".. u.name)
    h, v = signDeadzone( u.target.x - u.x, 4 ), signDeadzone( u.target.y - u.y, 4 )
    u.b.setHorizontalAndVertical( h, v )
    return true
end

function AI:emulateJumpPressToTarget()
    local u = self.unit
    dp("AI:emulateJumpPressToTarget() ".. u.name)
    u.b.setJump( true )
    h, v = signDeadzone( u.target.x - u.x, 4 ), signDeadzone( u.target.y - u.y, 4 )
    u.b.setHorizontalAndVertical( h, v )
    return true
end

function AI:emulateReleaseJump()
    dp("AI:emulateReleaseJump() " .. self.unit.name)
    self.unit.b.setJump(false)
    return true
end

function AI:emulateReleaseButtons()
    dp("AI:emulateReleaseButtons() " .. self.unit.name)
    self.unit.b.reset()
    return true
end

return AI
