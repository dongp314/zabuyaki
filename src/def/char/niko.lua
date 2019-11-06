local spriteSheet = "res/img/char/niko.png"
local imageWidth,imageHeight = loadSpriteSheet(spriteSheet)

local function q(x,y,w,h)
    return love.graphics.newQuad(x, y, w, h, imageWidth, imageHeight)
end
local function f(n)
    return (n / 60) - ((n / 60) % 0.001) -- converts frames -> seconds. Usage: delay = f(4)
end
local jumpAttack = function(slf, cont)
    slf:checkAndAttack(
        { x = 15, y = 20, width = 22, height = 45, damage = 14, type = "knockDown" },
        cont
    )
end
local comboKick = function(slf, cont)
    slf:checkAndAttack(
        { x = 29, y = 22, width = 26, damage = 7, sfx = "air" },
        cont
    )
end
local comboPunch = function(slf, cont)
    slf:checkAndAttack(
        { x = 29, y = 31, width = 26, damage = 9, type = "knockDown", sfx = "air" },
        cont
    )
end
local grabShake = function(slf, cont)
    if slf.grabContext and slf.grabContext.target then
        slf.grabContext.target:onShake(0.5, 0, 0.01, 1)
    end
end

return {
    serializationVersion = 0.43, -- The version of this serialization process

    spriteSheet = spriteSheet, -- The path to the spritesheet
    spriteName = "niko", -- The name of the sprite

    delay = f(12), -- Default delay for all animations
    hurtBox = { width = 20, height = 50 }, -- Default hurtBox for all animations
    fallsOnRespawn = true, --alter respawn clouds

    animations = {
        icon = {
            { q = q(39, 14, 37, 17) },
            delay = math.huge
        },
        intro = {
            { q = q(114,73,38,58), ox = 21, oy = 57 }, --duck
            delay = math.huge
        },
        intro2 = {
            { q = q(2,397,39,65), ox = 23, oy = 64 }, --intro 1
            { q = q(43,398,39,64), ox = 23, oy = 63, delay = f(8) }, --intro 2
            { q = q(84,399,39,63), ox = 23, oy = 62 }, --intro 3
            { q = q(43,398,39,64), ox = 23, oy = 63, delay = f(3) }, --intro 2
            loop = true,
            delay = f(10)
        },
        stand = {
            { q = q(2,2,36,64), ox = 21, oy = 63 }, --stand 1
            { q = q(40,3,36,63), ox = 21, oy = 62 }, --stand 2
            { q = q(78,4,36,62), ox = 21, oy = 61 }, --stand 3
            { q = q(40,3,36,63), ox = 21, oy = 62 }, --stand 2
            loop = true,
            delay = f(10)
        },
        walk = {
            { q = q(116,2,36,64), ox = 21, oy = 63 }, --walk 1
            { q = q(2,2,36,64), ox = 21, oy = 63 }, --stand 1
            { q = q(154,3,38,63), ox = 21, oy = 62 }, --walk 2
            { q = q(2,2,36,64), ox = 21, oy = 63 }, --stand 1
            loop = true,
            delay = f(10)
        },
        duck = {
            { q = q(114,73,38,58), ox = 21, oy = 57 }, --duck
            delay = f(4)
        },
        jump = {
            { q = q(2,264,57,66), ox = 21, oy = 65 }, --jump
            delay = math.huge
        },
        jumpAttackStraight = {
            { q = q(61,265,56,63), ox = 31, oy = 64, delay = f(7) }, --jump attack forward 1
            { q = q(119,263,64,67), ox = 39, oy = 66, funcCont = jumpAttack }, --jump attack forward 2
            delay = math.huge
        },
        jumpAttackForward = {
            { q = q(61,265,56,63), ox = 31, oy = 64, delay = f(7) }, --jump attack forward 1
            { q = q(119,263,64,67), ox = 39, oy = 66, funcCont = jumpAttack }, --jump attack forward 2
            delay = math.huge
        },
        dropDown = {
            { q = q(2,264,57,66), ox = 21, oy = 65 }, --jump
            delay = math.huge
        },
        respawn = {
            { q = q(2,264,57,66), ox = 21, oy = 65, delay = math.huge }, --jump
            { q = q(54,222,75,39), ox = 46, oy = 31 }, --fallen
            { q = q(131,209,55,52), ox = 31, oy = 51 }, --get up
            { q = q(114,73,38,58), ox = 21, oy = 57 }, --duck
            delay = f(12)
        },
        pickUp = {
            { q = q(114,73,38,58), ox = 21, oy = 57 }, --duck
            delay = f(17)
        },
        combo1 = {
            { q = q(2,332,40,63), ox = 19, oy = 62 }, --kick 1
            { q = q(44,332,60,63), ox = 18, oy = 62, func = comboKick, delay = f(14) }, --kick 2
            { q = q(2,332,40,63), ox = 19, oy = 62, delay = f(3) }, --kick 1
            delay = f(1)
        },
        combo2 = {
            { q = q(2,332,40,63), ox = 19, oy = 62 }, --kick 1
            { q = q(44,332,60,63), ox = 18, oy = 62, func = comboKick, delay = f(14) }, --kick 2
            { q = q(2,332,40,63), ox = 19, oy = 62, delay = f(3) }, --kick 1
            delay = f(1)
        },
        combo3 = {
            { q = q(50,68,62,63), ox = 21, oy = 62, func = comboPunch, delay = f(14) }, --punch 2
            { q = q(2,68,46,63), ox = 21, oy = 62 }, --punch 1
            delay = f(1)
        },
        chargeStand = {
            { q = q(2,464,45,63), ox = 18, oy = 62 }, --charge stand 1
            { q = q(49,465,45,62), ox = 18, oy = 61 }, --charge stand 2
            { q = q(96,466,45,61), ox = 18, oy = 60 }, --charge stand 3
            { q = q(49,465,45,62), ox = 18, oy = 61 }, --charge stand 2
            loop = true,
            delay = f(10)
        },
        chargeWalk = {
            { q = q(125,399,45,63), ox = 18, oy = 62 }, --charge walk 1
            { q = q(49,465,45,62), ox = 18, oy = 61 }, --charge stand 2
            { q = q(143,466,45,61), ox = 18, oy = 60 }, --charge walk 2
            { q = q(49,465,45,62), ox = 18, oy = 61 }, --charge stand 2
            loop = true,
            delay = f(10)
        },
        grab = {
            { q = q(2,529,45,63), ox = 18, oy = 62 }, --grab
            delay = math.huge
        },
        grabFrontAttack1 = {
            { q = q(49,530,52,62), ox = 24, oy = 61, delay = f(3) }, --grab attack 1
            { q = q(2,594,60,60), ox = 32, oy = 59, delay = f(12), func = grabShake }, --grab attack 2
            { q = q(49,530,52,62), ox = 24, oy = 61, delay = f(12) }, --grab attack 1
            { q = q(2,594,60,60), ox = 32, oy = 59, delay = f(6) }, --grab attack 2
            { q = q(64,594,60,60), ox = 32, oy = 59, delay = f(6) }, --grab attack 2b
            { q = q(64,594,60,60), ox = 33, oy = 59 }, --grab attack 2b (shifted left by 1px)
            { q = q(64,594,60,60), ox = 32, oy = 59 }, --grab attack 2b
            { q = q(64,594,60,60), ox = 33, oy = 59 }, --grab attack 2b (shifted left by 1px)
            { q = q(126,594,60,60), ox = 32, oy = 59 }, --grab attack 2c
            { q = q(126,594,60,60), ox = 33, oy = 59 }, --grab attack 2c (shifted left by 1px)
            { q = q(126,594,60,60), ox = 32, oy = 59 }, --grab attack 2c
            { q = q(126,594,60,60), ox = 33, oy = 59 }, --grab attack 2c (shifted left by 1px)
            { q = q(64,594,60,60), ox = 32, oy = 59, delay = f(3) }, --grab attack 2b
            { q = q(2,594,60,60), ox = 32, oy = 59, delay = f(3) }, --grab attack 2
            { q = q(49,530,52,62), ox = 24, oy = 61, delay = f(4) }, --grab attack 1
            { q = q(49,530,52,62), ox = 24, oy = 61, func = function(slf) slf:releaseGrabbed() end, delay = f(1) }, --grab attack 1
            delay = f(2)
        },
        hurtHighWeak = {
            { q = q(2,133,41,64), ox = 26, oy = 63 }, --hurt high 1
            { q = q(45,133,46,64), ox = 31, oy = 63, delay = f(12) }, --hurt high 2
            { q = q(2,133,41,64), ox = 26, oy = 63, delay = f(3) }, --hurt high 1
            delay = f(1)
        },
        hurtHighMedium = {
            { q = q(2,133,41,64), ox = 26, oy = 63 }, --hurt high 1
            { q = q(45,133,46,64), ox = 31, oy = 63, delay = f(20) }, --hurt high 2
            { q = q(2,133,41,64), ox = 26, oy = 63, delay = f(3) }, --hurt high 1
            delay = f(1)
        },
        hurtHighStrong = {
            { q = q(2,133,41,64), ox = 26, oy = 63 }, --hurt high 1
            { q = q(45,133,46,64), ox = 31, oy = 63, delay = f(28) }, --hurt high 2
            { q = q(2,133,41,64), ox = 26, oy = 63, delay = f(3) }, --hurt high 1
            delay = f(1)
        },
        hurtLowWeak = {
            { q = q(93,134,40,63), ox = 22, oy = 62 }, --hurt low 1
            { q = q(135,136,44,61), ox = 23, oy = 60, delay = f(12) }, --hurt low 2
            { q = q(93,134,40,63), ox = 22, oy = 62, delay = f(3) }, --hurt low 1
            delay = f(1)
        },
        hurtLowMedium = {
            { q = q(93,134,40,63), ox = 22, oy = 62 }, --hurt low 1
            { q = q(135,136,44,61), ox = 23, oy = 60, delay = f(20) }, --hurt low 2
            { q = q(93,134,40,63), ox = 22, oy = 62, delay = f(3) }, --hurt low 1
            delay = f(1)
        },
        hurtLowStrong = {
            { q = q(93,134,40,63), ox = 22, oy = 62 }, --hurt low 1
            { q = q(135,136,44,61), ox = 23, oy = 60, delay = f(28) }, --hurt low 2
            { q = q(93,134,40,63), ox = 22, oy = 62, delay = f(3) }, --hurt low 1
            delay = f(1)
        },
        fall = {
            { q = q(2,199,50,62), ox = 21, oy = 61, delay = f(20) }, --fall 1
            { q = q(106,332,58,55), ox = 36, oy = 54, delay = f(8) }, --fall 2
            { q = q(103,553,68,39), ox = 41, oy = 38 }, --fall 3
            delay = math.huge
        },
        fallBounce = {
            { q = q(54,222,75,39), ox = 46, oy = 31, delay = f(4) }, --fallen
            { q = q(103,553,68,39), ox = 41, oy = 38 }, --fall 3
            delay = math.huge
        },
        fallenDead = {
            { q = q(54,222,75,39), ox = 46, oy = 31 }, --fallen
            delay = math.huge
        },
        getUp = {
            { q = q(54,222,75,39), ox = 46, oy = 31, delay = f(24) }, --fallen
            { q = q(131,209,55,52), ox = 31, oy = 51, delay = f(14) }, --get up
            { q = q(114,73,38,58), ox = 21, oy = 57 }, --duck
            delay = f(13)
        },
        grabbedFront = {
            { q = q(2,133,41,64), ox = 26, oy = 63 }, --hurt high 1
            { q = q(45,133,46,64), ox = 31, oy = 63 }, --hurt high 2
            delay = f(2)
        },
        grabbedBack = {
            { q = q(93,134,40,63), ox = 22, oy = 62 }, --hurt low 1
            { q = q(135,136,44,61), ox = 23, oy = 60 }, --hurt low 2
            delay = f(2)
        },
        grabbedFrames = {
            --default order should be kept: hurt low 2, hurt high 2, fall 1 (rotated -90°), hurt low 2 (/), hurt low 2 (upsideDown), fallen, fall 3
            { q = q(135,136,44,61), ox = 23, oy = 60 }, --hurt low 2
            { q = q(106,332,58,55), ox = 36, oy = 54 }, --fall 2
            { q = q(106,332,58,55), ox = 36, oy = 54, rotate = -1.57, rx = 36, ry = -27 }, --fall 2 (rotated -90°)
            { q = q(135,136,44,61), ox = 23, oy = 60, flipV = -1 }, --hurt low 2 (flipped vertically)
            delay = math.huge
        },
        thrown = {
            --rx = ox / 2, ry = -oy / 2 for this rotation
            { q = q(2,199,50,62), ox = 21, oy = 61, rotate = -1.57, rx = 10, ry = -30, delay = f(24) }, --fall 1 (rotated -90°)
            { q = q(103,553,68,39), ox = 41, oy = 38 }, --fall 3
            delay = math.huge
        },
    }
}
