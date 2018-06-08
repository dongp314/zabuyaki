local class = require "lib/middleclass"
local Rick = class('Rick', Player)

local function nop() end
local sign = sign
local clamp = clamp
local dist = dist
local rand1 = rand1
local CheckCollision = CheckCollision

function Rick:initialize(name, sprite, input, x, y, f)
    Player.initialize(self, name, sprite, input, x, y, f)
end

function Rick:initAttributes()
    self.moves = { -- list of allowed moves
        run = true, sideStep = true, pickup = true,
        jump = true, jumpAttackForward = true, jumpAttackLight = true, jumpAttackRun = true, jumpAttackStraight = true,
        grab = true, grabSwap = true, frontGrabAttack = true, chargeAttack = true, chargeDash = true,
        frontGrabAttackUp = true, frontGrabAttackDown = true, frontGrabAttackBack = true, frontGrabAttackForward = true, backGrabAttack = true,
        dashAttack = true, specialOffensive = true, specialDefensive = true,
        --technically present for all
        stand = true, walk = true, combo = true, slide = true, fall = true, getup = true, duck = true,
    }
    self.walkSpeed_x = 90
    self.walkSpeed_y = 45
    self.chargeWalkSpeed_x = 72
    self.chargeWalkSpeed_y = 36
    self.runSpeed_x = 140
    self.runSpeed_y = 23
    self.dashSpeed_x = 125 --speed of the character
    self.dashFallSpeed = 180 --speed caused by dash to others fall
    self.dashFriction = 400
    self.chargeDashAttackSpeed_z = 65

    self.comboSlideSpeed2_x = 180 --horizontal speed of combo2Forward attacks
    self.comboSlideDiagonalSpeed2_x = 150 --diagonal horizontal speed of combo2Forward attacks
    self.comboSlideDiagonalSpeed2_y = 30 --diagonal vertical speed of combo2Forward attacks
    self.comboSlideRepel2 = self.comboSlideSpeed2_x --how much combo2Forward pushes units back

    self.comboSlideSpeed3_x = 130 --horizontal speed of combo3Forward attacks
    self.comboSlideDiagonalSpeed3_x = 100 --diagonal horizontal speed of combo3Forward attacks
    self.comboSlideDiagonalSpeed3_y = 30 --diagonal vertical speed of combo3Forward attacks
    self.comboSlideRepel3 = self.comboSlideSpeed3_x --how much combo3Forward pushes units back

    self.comboSlideSpeed4_x = 180 --horizontal speed of combo4Forward attacks
    self.comboSlideDiagonalSpeed4_x = 150 --diagonal horizontal speed of combo4Forward attacks
    self.comboSlideDiagonalSpeed4_y = 30 --diagonal vertical speed of combo4Forward attacks

    --    self.throwSpeed_x = 220 --my throwing speed
    --    self.throwSpeed_z = 200 --my throwing speed
    --    self.throwSpeedHorizontalMutliplier = 1.3 -- +30% for horizontal throws
    self.myThrownBodyDamage = 10  --DMG (weight) of my thrown body that makes DMG to others
    self.thrownFallDamage = 20  --dmg I suffer on landing from the thrown-fall
    -- default sfx
    self.sfx.jump = "rickJump"
    self.sfx.throw = "rickThrow"
    self.sfx.jumpAttack = "rickAttack"
    self.sfx.dashAttack = "rickAttack"
    self.sfx.step = "rickStep"
    self.sfx.dead = "rickDeath"
end

function Rick:dashAttackStart()
    self.isHittable = true
    self.customFriction = self.dashFriction
    dpo(self, self.state)
    self:setSprite("dashAttack")
    self.speed_x = self.dashSpeed_x
    self.speed_y = 0
    self.speed_z = 0
    self.horizontal = self.face
    self:playSfx(self.sfx.dashAttack)
    self:showEffect("dash") -- adds vars: self.paDash, paDash_x, self.paDash_y
end
function Rick:dashAttackUpdate(dt)
    if self.sprite.isFinished then
        dpo(self, self.state)
        self:setState(self.stand)
        return
    end
    if self:canFall() then
        self:calcFreeFall(dt)
    end
    self:moveEffectAndEmit("dash", 0.3)
end
Rick.dashAttack = {name = "dashAttack", start = Rick.dashAttackStart, exit = nop, update = Rick.dashAttackUpdate, draw = Character.defaultDraw}

function Rick:specialOffensiveStart()
    self.isHittable = true
    self.customFriction = self.dashSpeed_x
    self.horizontal = self.face
    dpo(self, self.state)
    self:setSprite("specialOffensive")
    self:enableGhostTrace()
    self.speed_x = self.dashSpeed_x
    self.speed_y = 0
    self.speed_z = 0
    self:playSfx(self.sfx.dashAttack)
    self:showEffect("dash") -- adds vars: self.paDash, paDash_x, self.paDash_y
end
function Rick:specialOffensiveUpdate(dt)
    if self.sprite.isFinished then
        dpo(self, self.state)
        self:setState(self.stand)
        return
    end
    self:moveEffectAndEmit("dash", 0.5)
end
Rick.specialOffensive = {name = "specialOffensive", start = Rick.specialOffensiveStart, exit = Unit.fadeOutGhostTrace, update = Rick.specialOffensiveUpdate, draw = Character.defaultDraw}

function Rick:backGrabAttackStart()
    local g = self.grabContext
    local t = g.target
    self:initGrabTimer()
    self:moveStatesInit()
    self:setSprite("backGrabAttack")
    self.isHittable = not self.sprite.isThrow
    t.isHittable = not self.sprite.isThrow --cannot damage both if on the throw attack type
    self:playSfx(self.sfx.throw)
    dp(self.name.." backGrabAttack someone.")
end
function Rick:backGrabAttackUpdate(dt)
    local g = self.grabContext
    local t = g.target
    if t.state ~= "bounce" then
        self:moveStatesApply()
    end
    if self.sprite.isFinished then
        self:setState(self.stand)
        return
    end
end
Rick.backGrabAttack = {name = "backGrabAttack", start = Rick.backGrabAttackStart, exit = nop, update = Rick.backGrabAttackUpdate, draw = Character.defaultDraw}

return Rick
