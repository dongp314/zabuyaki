local class = require "lib/middleclass"
local Rick = class('Rick', Player)

local function nop() end
local sign = sign
local clamp = clamp
local dist = dist
local rand1 = rand1
local CheckCollision = CheckCollision
local moves_white_list = {
    run = true, sideStep = true, pickup = true,
    jump = true, jumpAttackForward = true, jumpAttackLight = true, jumpAttackRun = true, jumpAttackStraight = true,
    grab = true, grabSwap = true, grabAttack = true,
    shoveUp = true, shoveDown = true, shoveBack = true, shoveForward = true,
    dashAttack = true, offensiveSpecial = true, defensiveSpecial = true,
    --technically present for all
    stand = true, walk = true, combo = true, slide = true, fall = true, getup = true, duck = true,
}

function Rick:initialize(name, sprite, input, x, y, f)
    Player.initialize(self, name, sprite, input, x, y, f)
    self.moves = moves_white_list --list of allowed moves
    self.velocityWalk = 90
    self.velocityWalk_y = 45
    self.velocityWalkHold = 72
    self.velocityWalkHold_y = 36
    self.velocity_run = 140
    self.velocity_run_y = 23
    self.velocity_dash = 150 --speed of the character
    self.velocity_dash_fall = 180 --speed caused by dash to others fall
    self.friction_dash = self.velocity_dash
--    self.velocity_shove_x = 220 --my throwing speed
--    self.velocity_shove_z = 200 --my throwing speed
--    self.velocity_shove_horizontal = 1.3 -- +30% for horizontal throws
    self.my_thrown_body_damage = 10  --DMG (weight) of my thrown body that makes DMG to others
    self.thrown_land_damage = 20  --dmg I suffer on landing from the thrown-fall
    --Character default sfx
    self.sfx.jump = "rick_jump"
    self.sfx.throw = "rick_throw"
    self.sfx.jump_attack = "rick_attack"
    self.sfx.dash_attack = "rick_attack"
    self.sfx.step = "rick_step"
    self.sfx.dead = "rick_death"
end

function Rick:defensiveSpecialStart()
    self.isHittable = false
    self:setSprite("defensiveSpecial")
    sfx.play("voice"..self.id, self.sfx.dash_attack)
    self.coolDown = 0.2
end
function Rick:defensiveSpecialUpdate(dt)
    if self.z > 0 then
        self.z = self.z + dt * self.velz
        self.velz = self.velz - self.gravity * dt
        if self.z < 0 then
            self.z = 0
        end
    end
    if self.sprite.isFinished then
        self:setState(self.stand)
        return
    end
    self:calcMovement(dt, true)
end
Rick.defensiveSpecial = {name = "defensiveSpecial", start = Rick.defensiveSpecialStart, exit = nop, update = Rick.defensiveSpecialUpdate, draw = Character.defaultDraw }

function Rick:dashAttackStart()
    self.isHittable = true
    dpo(self, self.state)
    self:setSprite("dashAttack")
    self.velx = self.velocity_dash
    self.vely = 0
    self.velz = 0
    self.horizontal = self.face
    sfx.play("voice"..self.id, self.sfx.dash_attack)
    local particles = PA_DASH:clone()
    particles:setSpin(0, -3 * self.face)
    self.pa_dash = particles
    self.pa_dash_x = self.x
    self.pa_dash_y = self.y
    stage.objects:add(Effect:new(particles, self.x, self.y + 2))
end
function Rick:dashAttackUpdate(dt)
    if self.sprite.isFinished then
        dpo(self, self.state)
        self:setState(self.stand)
        return
    end
    if math.random() < 0.3 and self.velx >= self.velocity_dash * 0.5 then
        self.pa_dash:moveTo( self.x - self.pa_dash_x - self.face * 10, self.y - self.pa_dash_y - 5 )
        self.pa_dash:emit(1)
    end
    self:calcMovement(dt, true, self.friction_dash)
end
Rick.dashAttack = {name = "dashAttack", start = Rick.dashAttackStart, exit = nop, update = Rick.dashAttackUpdate, draw = Character.defaultDraw}

function Rick:offensiveSpecialStart()
    self.isHittable = true
    self.horizontal = self.face
    dpo(self, self.state)
    self:setSprite("offensiveSpecial")
    self.velx = self.velocity_dash
    self.vely = 0
    self.velz = 0
    sfx.play("voice"..self.id, self.sfx.dash_attack)

    local particles = PA_DASH:clone()
    particles:setSpin(0, -2 * self.face)
    particles:setLinearAcceleration(0, -110, 0, -250) -- Random movement in all directions.
    self.pa_dash = particles
    self.pa_dash_x = self.x
    self.pa_dash_y = self.y

    stage.objects:add(Effect:new(particles, self.x, self.y + 2))
end
function Rick:offensiveSpecialUpdate(dt)
    if self.sprite.isFinished then
        dpo(self, self.state)
        self:setState(self.stand)
        return
    end
    if math.random() < 0.5 and self.velx >= self.velocity_dash * 0.5 then
        self.pa_dash:moveTo( self.x - self.pa_dash_x - self.face * 10, self.y - self.pa_dash_y - 5 )
        self.pa_dash:emit(1)
    end
    self:calcMovement(dt, true, self.velocity_dash)
end
Rick.offensiveSpecial = {name = "offensiveSpecial", start = Rick.offensiveSpecialStart, exit = nop, update = Rick.offensiveSpecialUpdate, draw = Character.defaultDraw}

function Rick:holdAttackStart()
    self.isHittable = true
    self:setSprite("holdAttack")
    self.coolDown = 0.2
end
function Rick:holdAttackUpdate(dt)
    if self.sprite.isFinished then
        self:setState(self.stand)
        return
    end
    self:calcMovement(dt, true)
end
Rick.holdAttack = {name = "holdAttack", start = Rick.holdAttackStart, exit = nop, update = Rick.holdAttackUpdate, draw = Character.defaultDraw}

return Rick