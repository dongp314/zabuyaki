local class = require "lib/middleclass"
local Chai = class('Chai', Player)

local function nop() end

function Chai:initialize(name, sprite, input, x, y, f)
    Player.initialize(self, name, sprite, input, x, y, f)
end

function Chai:initAttributes()
    self.moves = { -- list of allowed moves
        run = true, sideStep = true, pickUp = true,
        jump = true, jumpAttackForward = true, jumpAttackLight = true, jumpAttackRun = true, jumpAttackStraight = true,
        grab = true, grabSwap = true, grabFrontAttack = true, chargeAttack = true, chargeDash = true,
        grabFrontAttackDown = true, grabFrontAttackBack = true, grabFrontAttackForward = true,
        dashAttack = true, specialDash = true, specialOffensive = true, specialDefensive = true,
        -- technically present for all
        stand = true, walk = true, combo = true, slide = true, fall = true, getUp = true, duck = true,
    }
    self.walkSpeed_x = 100
    self.walkSpeed_y = 50
    self.chargeWalkSpeed_x = 80
    self.chargeWalkSpeed_y = 40
    self.runSpeed_x = 156
    self.runSpeed_y = 26
    self.dashSpeed_x = 200 --speed of the character
    self.dashFallSpeed = 180 --speed caused by dash to others fall
    self.chargeDashAttackSpeed_z = 90
    --self.repelFriction = 1650 * 1.5

    self.comboSlideSpeed1_x = 120 --horizontal speed of combo1Forward attacks
    self.comboSlideDiagonalSpeed1_x = 90 --diagonal horizontal speed of combo1Forward attacks
    self.comboSlideDiagonalSpeed1_y = 50 --diagonal vertical speed of combo1Forward attacks

    self.comboSlideSpeed2_x = 200 --horizontal speed of combo2Forward attacks
    self.comboSlideDiagonalSpeed2_x = 170 --diagonal horizontal speed of combo2Forward attacks
    self.comboSlideDiagonalSpeed2_y = 50 --diagonal vertical speed of combo2Forward attacks
    self.comboSlideRepel2 = self.comboSlideSpeed2_x --how much combo2Forward pushes units back

    self.comboSlideSpeed3_x = 220 --horizontal speed of combo3Forward attacks
    self.comboSlideDiagonalSpeed3_x = 190 --diagonal horizontal speed of combo3Forward attacks
    self.comboSlideDiagonalSpeed3_y = 50 --diagonal vertical speed of combo3Forward attacks
    self.comboSlideRepel3 = self.comboSlideSpeed3_x --how much combo3Forward pushes units back

    self.comboSlideSpeed4_x = 280 --horizontal speed of combo4Forward attacks
    self.comboSlideDiagonalSpeed4_x = 250 --diagonal horizontal speed of combo4Forward attacks
    self.comboSlideDiagonalSpeed4_y = 50 --diagonal vertical speed of combo4Forward attacks
    self.comboSlideRepel4 = self.comboSlideSpeed4_x --how much combo4Forward pushes units back

    --    self.throwSpeed_x = 220 --my throwing speed
    --    self.throwSpeed_z = 200 --my throwing speed
    --    self.throwSpeedHorizontalMutliplier = 1.3 -- +30% for horizontal throws
    self.myThrownBodyDamage = 10  --DMG (weight) of my thrown body that makes DMG to others
    self.thrownFallDamage = 20  --dmg I suffer on landing from the thrown-fall
    -- default sfx
    self.sfx.jump = "chaiJump"
    self.sfx.throw = "chaiThrow"
    self.sfx.jumpAttack = "chaiAttack"
    self.sfx.dashAttack = "chaiAttack"
    self.sfx.step = "chaiStep"
    self.sfx.dead = "chaiDeath"
    self.specialOverlaySprite = getSpriteInstance("src/def/char/chai_sp.lua")
end

function Chai:dashAttackStart()
    self.isHittable = true
    self.horizontal = self.face
    dpo(self, self.state)
    --	dp(self.name.." - dashAttack start")
    self:setSprite("dashAttack")
    self.speed_x = self.dashSpeed_x * self.jumpSpeedMultiplier
    self.speed_z = self.jumpSpeed_z * self.jumpSpeedMultiplier
    self.z = self:getMinZ() + 0.1
    self:playSfx(self.sfx.dashAttack)
    self:showEffect("jumpStart")
    self.bounced = 0 -- Chai's dashAttack state uses fall state. The bounced vars have to be initialized here
end
function Chai:dashAttackUpdate(dt)
    if self.sprite.isFinished then
        self:setState(self.fall)
        return
    end
    if self:canFall() then
        self:calcFreeFall(dt)
        if self.speed_z > 0 then
            if self.speed_x > 0 then
                self.speed_x = self.speed_x - (self.dashSpeed_x * dt * 2.3)
            else
                self.speed_x = 0
            end
        end
    else
        self.speed_z = 0
        self.z = self:getMinZ()
        self:playSfx(self.sfx.step)
        self:setState(self.duck)
        return
    end
end
Chai.dashAttack = {name = "dashAttack", start = Chai.dashAttackStart, exit = nop, update = Chai.dashAttackUpdate, draw = Character.defaultDraw }

function Chai:grabFrontAttackForwardStart()
    local g = self.grabContext
    local t = g.target
    self:moveStatesInit()
    self:setSprite("grabFrontAttackForward")
    self.isHittable = not self.sprite.isThrow
    t.isHittable = not self.sprite.isThrow --cannot damage both if on the throw attack type
    dp(self.name.." grabFrontAttackForward someone.")
end
function Chai:grabFrontAttackForwardUpdate(dt)
    self:moveStatesApply()
    if self.sprite.isFinished then
        self:setState(self.stand)
        return
    end
end
Chai.grabFrontAttackForward = {name = "grabFrontAttackForward", start = Chai.grabFrontAttackForwardStart, exit = nop, update = Chai.grabFrontAttackForwardUpdate, draw = Character.defaultDraw}

function Chai:grabFrontAttackBackStart()
    local g = self.grabContext
    local t = g.target
    self:moveStatesInit()
    self:setSprite("grabFrontAttackBack")
    self.isHittable = not self.sprite.isThrow
    t.isHittable = not self.sprite.isThrow --cannot damage both if on the throw attack type
    dp(self.name.." grabFrontAttackBack someone.")
end
function Chai:grabFrontAttackBackUpdate(dt)
    self:moveStatesApply()
    if self.sprite.isFinished then
        self:setState(self.stand)
        return
    end
end
Chai.grabFrontAttackBack = {name = "grabFrontAttackBack", start = Chai.grabFrontAttackBackStart, exit = nop, update = Chai.grabFrontAttackBackUpdate, draw = Character.defaultDraw}

function Chai:specialDefensiveStart()
    self.isHittable = false
    self.z = self:getMinZ()
    self.speed_x = 0
    self.speed_y = 0
    self.jumpType = 0
    self:setSprite("specialDefensive")
    self:enableGhostTrails()
    self:setSpriteOverlay(self.specialOverlaySprite, self.state, true)
    self:playSfx(self.sfx.dashAttack)
end
function Chai:specialDefensiveUpdate(dt)
    if self.jumpType == 1 then
        self.speed_z = self.jumpSpeed_z * self.jumpSpeedMultiplier
        self.z = self:getMinZ() + 0.1
        self.jumpType = 0
    elseif self.jumpType == 2 then
        self.speed_z = -self.jumpSpeed_z * self.jumpSpeedMultiplier / 2
        self.jumpType = 0
    end
    if self.z > self:getMinZ() + 32 then
        self.z = self:getMinZ() + 32
    end
    if self:canFall() then
        self:calcFreeFall(dt)
        if not self:canFall() then
            self.z = self:getMinZ()
        end
    end
    if self.particles then
        self.particles.z = self.z + 2 -- because we show the effect 2px down the unit
    end
    if self.sprite.isFinished then
        self.particles = nil
        self:playSfx(self.sfx.step)
        self:setState(self.duck)
        return
    end
end
Chai.specialDefensive = {name = "specialDefensive", start = Chai.specialDefensiveStart, exit = Unit.clearTrailsAndOverlaySprite, update = Chai.specialDefensiveUpdate, draw = Character.defaultDraw }

function Chai:specialOffensiveStart()
    self.isHittable = true
    dpo(self, self.state)
    self:setSprite("specialOffensive")
    self:enableGhostTrails()
    self:setSpriteOverlay(self.specialOverlaySprite, self.state, true)
    self.horizontal = -self.face
    self.speed_x = self.jumpSpeedBoost.x
    self.speed_y = 0
    self.speed_z = self.jumpSpeed_z * self.jumpSpeedMultiplier
    self.z = self:getMinZ() + 0.1
    self.bounced = 0
    self:playSfx(self.sfx.jump)
    self:showEffect("jumpStart")
end
function Chai:specialOffensiveUpdate(dt)
    if self.sprite.curAnim == "specialOffensive" then
        if self.speed_z < 0 and self.speed_x < self.dashSpeed_x then
            -- check speed_x to add no extra var here. it should trigger once
            self.speed_x = self.dashSpeed_x * 2
            self.horizontal = self.face
        end
    end
    if self:canFall() then
        if self.sprite.curFrame <= 6 and self.sprite.curAnim == "specialOffensive2" then
            self:calcFreeFall(dt, 0.1) -- slow down the falling speed. Restore it on the 5th frame from the end
        else
            self:calcFreeFall(dt)
        end
    else
        self:playSfx(self.sfx.step)
        self:setState(self.duck)
        return
    end
    if self.particles then
        self.particles.z = self.z + 2 -- because we show the effect 2px down the unit
        self.particles.x = self.x
        self.particles.y = self.y
    end
    -- TODO read vectors not the flag successfullyMoved
    if not self.successfullyMoved then
        self.speed_x = 0
        self.speed_y = 0
    end
end
Chai.specialOffensive = {name = "specialOffensive", start = Chai.specialOffensiveStart, exit = Unit.clearTrailsAndOverlaySprite, update = Chai.specialOffensiveUpdate, draw = Character.defaultDraw}

function Chai:specialDashStart()
    self.isHittable = true
    dpo(self, self.state)
    self:setSprite("specialDash")
    self:enableGhostTrails()
    self:setSpriteOverlay(self.specialOverlaySprite, self.state, true)
    self.horizontal = -self.face
    self.speed_x = self.jumpSpeedBoost.x
    self.speed_y = 0
    self.speed_z = self.jumpSpeed_z * self.jumpSpeedMultiplier
    self.z = self:getMinZ() + 0.1
    self.bounced = 0
    self:playSfx(self.sfx.jump)
    self:showEffect("jumpStart")
end
function Chai:specialDashUpdate(dt)
    if self.sprite.curAnim == "specialDash" then
        if self.speed_z < 0 and self.speed_x < self.dashSpeed_x then
            -- check speed_x to add no extra var here. it should trigger once
            self.speed_x = self.dashSpeed_x * 2
            self.horizontal = self.face
        end
    end
    if self:canFall() then
        if self.sprite.curFrame <= 6 and self.sprite.curAnim == "specialDash2" then
            self:calcFreeFall(dt, 0.1) -- slow down the falling speed. Restore it on the 5th frame from the end
        else
            self:calcFreeFall(dt)
        end
    else
        self:playSfx(self.sfx.step)
        self:setState(self.duck)
        return
    end
    if self.particles then
        self.particles.z = self.z + 2 -- because we show the effect 2px down the unit
        self.particles.x = self.x
        self.particles.y = self.y
    end
    -- TODO read vectors not the flag successfullyMoved
    if not self.successfullyMoved then
        self.speed_x = 0
        self.speed_y = 0
    end
end
Chai.specialDash = {name = "specialDash", start = Chai.specialDashStart, exit = Unit.clearTrailsAndOverlaySprite, update = Chai.specialDashUpdate, draw = Character.defaultDraw}

function Chai:chargeDashAttackStart()
    self.isHittable = true
    dpo(self, self.state)
    self:setSprite("chargeDashAttack")
    self.speed_y = 0
    self.speed_z = self.jumpSpeed_z * 0.7
    self.speed_x = self.dashSpeed_x * 0.91
    self.bounced = 0 -- used in canFall()
    self:playSfx(self.sfx.dashAttack)
end
function Chai:chargeDashAttackUpdate(dt)
    if self:canFall() then
        self:calcFreeFall(dt, getSpriteFrame(self.sprite).hover and 0.01 or self.jumpSpeedMultiplier * 0.7 ) -- slow down the falling speed
    else
        self:playSfx(self.sfx.step)
        self:setState(self.duck)
        return
    end
    if not self.successfullyMoved then
        self.speed_x = 0
        self.speed_y = 0
    end
end
Chai.chargeDashAttack = {name = "chargeDashAttack", start = Chai.chargeDashAttackStart, exit = nop, update = Chai.chargeDashAttackUpdate, draw = Character.defaultDraw}

return Chai
