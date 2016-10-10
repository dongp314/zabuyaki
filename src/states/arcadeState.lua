arcadeState = {}

function arcadeState:init()
end

function arcadeState:resume()
    --restore BGM music volume
    TEsound.volume("sfx", GLOBAL_SETTING.SFX_VOLUME)
    TEsound.volume("music", GLOBAL_SETTING.BGM_VOLUME)
end

-- blocking walls
local left_block_wall = {type = "wall"}
local right_block_wall = {type = "wall"}

function arcadeState:enter(_, players)
    player1 = nil
    player2 = nil
    player3 = nil

    local top_floor_y = 454

    GLOBAL_UNIT_ID = 1  --recalc players IDs for proper life bar coords
    -- create players
    if players[1] then
--    player1 = Rick:new("RICK", GetSpriteInstance("src/def/char/rick.lua"), Control1, 190, 180, shader, {255,255,255, 255})
        player1 = players[1].hero:new(players[1].name,
            GetSpriteInstance(players[1].sprite_instance),
            Control1,
            60, top_floor_y + 65,
            players[1].shader,
            {255,255,255, 255})
    end
    GLOBAL_UNIT_ID = 2  --recalc players IDs for proper life bar coords
    if players[2] then
        --     player2 = Chai:new("CHAI", GetSpriteInstance("src/def/char/chai.lua"), Control2, 240, 200, shader )
        player2 = players[2].hero:new(players[2].name,
            GetSpriteInstance(players[2].sprite_instance),
            Control2,
            90, top_floor_y + 35,
            players[2].shader)
        --player2.horizontal = -1
        --player2.face = -1
    end
    GLOBAL_UNIT_ID = 3  --recalc players IDs for proper life bar coords
    if players[3] then
--        player3 = Kisa:new("KISA", GetSpriteInstance("src/def/char/rick.lua"), Control3, 220, 200-30, shader, {255,255,255, 255})
        player3 = players[3].hero:new(players[3].name,
            GetSpriteInstance(players[3].sprite_instance),
            Control3,
            120, top_floor_y + 5,
            players[3].shader,
            {255,255,255, 255})
    end

    GLOBAL_UNIT_ID = GLOBAL_SETTING.MAX_PLAYERS + 1  --enemy IDs go after the max player ID

    local gopper1 = Gopper:new("GOPPER", GetSpriteInstance("src/def/char/gopper.lua"), button3, 500, top_floor_y + 20, shaders.gopper[4], {255,255,255, 255})
    local gopper2 = Gopper:new("GOPPER2", GetSpriteInstance("src/def/char/gopper.lua"), button3, 1510, top_floor_y + 20, shaders.gopper[2], {255,255,255, 255})
    gopper2:setToughness(1)
    local gopper3 = Gopper:new("GOPPER3", GetSpriteInstance("src/def/char/gopper.lua"), button3, 1560, top_floor_y + 40, shaders.gopper[3], {255,255,255, 255})
    gopper3:setToughness(2)
    local gopper4 = Gopper:new("GOPPER4", GetSpriteInstance("src/def/char/gopper.lua"), button3, 1520, top_floor_y + 30, shaders.gopper[4], {255,255,255, 255})
    gopper4:setToughness(3)
    local gopper5 = Gopper:new("GOPPER5", GetSpriteInstance("src/def/char/gopper.lua"), button3, 1540, top_floor_y + 25, nil, {255,255,255, 255})
    gopper5:setToughness(4)
    local gopper6 = Gopper:new("GOPPER6", GetSpriteInstance("src/def/char/gopper.lua"), button3, 1525, top_floor_y + 35, nil, {255,255,255, 255})
    gopper6:setToughness(5)

    local dummy4 = Rick:new("Dummie4", GetSpriteInstance("src/def/char/rick.lua"), button3, 260, top_floor_y + 20, shaders.rick[4], {255,255,255, 255})
    dummy4:setToughness(5)
    dummy4.horizontal = -1
    dummy4.face = -1
    local dummy5 = Chai:new("Dummie5", GetSpriteInstance("src/def/char/chai.lua"), button3, 220, top_floor_y + 20, shaders.chai[3], {255,255,255, 255})
    dummy5:setToughness(5)
    dummy5.horizontal = -1
    dummy5.face = -1

    local temper1 = Temper:new("TEMPER", GetSpriteInstance("src/def/char/rick.lua"), button3, 1670, top_floor_y + 40, shaders.rick[5], {255,255,255, 255})

    local niko1 = Niko:new("niko", GetSpriteInstance("src/def/char/niko.lua"), button3, 550 + love.math.random(-20,20), top_floor_y + 0, shaders.niko[2], {255,255,255, 255})
    local niko2 = Niko:new("niko2", GetSpriteInstance("src/def/char/niko.lua"), button3, 1510 + love.math.random(-20,20), top_floor_y + 10, nil, {255,255,255, 255})
    niko2:setToughness(1)
    local niko3 = Niko:new("niko3", GetSpriteInstance("src/def/char/niko.lua"), button3, 1560 + love.math.random(-20,20), top_floor_y + 20, shaders.niko[2], {255,255,255, 255})
    niko3:setToughness(2)
    local niko4 = Niko:new("niko4", GetSpriteInstance("src/def/char/niko.lua"), button3, 1520 + love.math.random(-20,20), top_floor_y + 30, shaders.niko[2], {255,255,255, 255})
    niko4:setToughness(3)
    local niko5 = Niko:new("niko5", GetSpriteInstance("src/def/char/niko.lua"), button3, 1540 + love.math.random(-20,20), top_floor_y + 40, nil, {255,255,255, 255})
    niko5:setToughness(4)
    local niko6 = Niko:new("niko6", GetSpriteInstance("src/def/char/niko.lua"), button3, 1525 + love.math.random(-20,20), top_floor_y + 50, nil, {255,255,255, 255})
    niko6:setToughness(5)

    --Item:initialize(name, sprite, hp, money, func, x, y, shader, color)
    local item1 = Item:new("Apple", "+15 HP", gfx.items.apple, 15, 0, nil, 130,top_floor_y + 30)
    local item2 = Item:new("Chicken", "+50 HP", gfx.items.chicken, 50, 0, nil, 660,top_floor_y + 50)
--    item2 = Item:new("Custom func sample", "+20 Pts.", gfx.items.apple, 20, 0, function(s, t) dp(t.name .. " called custom item ("..s.name..") func") end, 460,180)
    local item3 = Item:new("Beef", "+100 HP", gfx.items.beef, 100, 0, nil, 750,top_floor_y + 40 )

    level_objects = Entity:new()
    level_objects:addArray({
        gopper1, gopper2, gopper3, gopper4, gopper5, gopper6,
        niko1, niko2, niko3, niko4, niko5, niko6,
        dummy4, dummy5,
        temper1,
        item1, item2, item3
    })
    if player1 then
        level_objects:add(player1)
    end
    if player2 then
        level_objects:add(player2)
    end
    if player3 then
        level_objects:add(player3)
    end

    --load level
    level = Level01:new()

    --adding BLOCKING left-right walls
    level.world:add(left_block_wall, -10, 0, 40, level.worldHeight) --left
    level.world:add(right_block_wall, level.worldWidth+20, 0, 40, level.worldHeight) --right

    --adding players into collision world 15x7
    level_objects:addToWorld()

    mainCamera = Camera:new(level.worldWidth, level.worldHeight)

    --start BGM
    TEsound.stop("music")
    TEsound.playLooping("res/bgm/testtrck.xm", "music")

    TEsound.volume("sfx", GLOBAL_SETTING.SFX_VOLUME)
    TEsound.volume("music", GLOBAL_SETTING.BGM_VOLUME)
end

function arcadeState:update(dt)
    level_objects:update(dt)
    --sort players by y
    level_objects:sortByY()

    level:update(dt)

    --center camera over all players
    local pc = 0
    local mx = 0
    local my = 430 -- const vertical Y (no scroll)
    local x1, x2, x3
    if player1 then
        x1 = player1.x
    end
    if player2 then
        x2 = player2.x
    end
    if player3 then
        x3 = player3.x
    end
    -- Stage Scale
    local max_distance = 320+160 - 50
    local min_distance = 320 - 50
    local min_zoom = 1.5
    local max_zoom = 2
    local delta = max_distance - min_distance
    x1 = x1 or x2 or x3 or 0
    x2 = x2 or x1 or x3 or 0
    x3 = x3 or x1 or x2 or 0
    local minx = math.min(x1, x2, x3)
    local maxx = math.max(x1, x2, x3)
    local dist = maxx - minx
    local scale = max_zoom

    if dist > max_distance - 60 then
        -- move block walls
        local actualX, actualY, cols, len = level.world:move(left_block_wall, maxx - max_distance - 40, 0, function() return "cross" end)
        local actualX2, actualY2, cols2, len2 = level.world:move(right_block_wall, minx + max_distance +1, 0, function() return "cross" end)
        --dp(actualX, actualX2, player1.x, player2.x)
    else
        -- move block walls
        local actualX, actualY, cols, len = level.world:move(left_block_wall, -100, 0, function() return "cross" end)
        local actualX2, actualY2, cols2, len2 = level.world:move(right_block_wall, 4400, 0, function() return "cross" end)
        --dp(actualX, actualX2, player1.x, player2.x)
    end

    if dist > min_distance then
        if dist > max_distance then
            scale = min_zoom
        elseif dist < max_distance then
            scale = ((max_distance - dist) / delta) * 2
        end
    end
    if mainCamera:getScale() ~= scale then
        mainCamera:setScale( 2 * math.max(scale, min_zoom) )
		if math.max(scale, min_zoom) < max_zoom then
			canvas:setFilter("linear", "linear", 2)
		else
            canvas:setFilter("nearest", "nearest")
		end
    end
    mainCamera:update(dt,math.floor((minx + maxx) / 2), math.floor(my))

    -- PAUSE (only for P1)
    if Control1.back:pressed() then
        GLOBAL_SCREENSHOT = love.graphics.newImage(love.graphics.newScreenshot(false))
        return Gamestate.push(pauseState)
    end
    watch_debug_variables()
end

function arcadeState:draw()
    love.graphics.setCanvas(canvas)
    --love.graphics.setBackgroundColor(255, 255, 255)
    mainCamera:draw(function(l, t, w, h)
        -- draw camera stuff here
        love.graphics.setColor(255, 255, 255, 255)
        level.background:draw(l, t, w, h)
        level_objects:draw(l,t,w,h)

        -- draw block walls
        love.graphics.setColor(0, 0, 0, 100)
        love.graphics.rectangle("fill", level.world:getRect(left_block_wall))
        love.graphics.rectangle("fill", level.world:getRect(right_block_wall))

        show_debug_boxes() -- debug draw bump boxes

        --TODO add foreground parallax for levels
        --foreground:draw(l, t, w, h)
    end)
    love.graphics.setCanvas()
    love.graphics.setColor(255, 255, 255, 255)
--    love.graphics.draw(canvas)
--    love.graphics.draw(canvas, 0,0, 0, 0.5,0.5)
    love.graphics.draw(canvas, 0,0, nil, 0.5)

    --HP bars
    if player1 then
        player1.infoBar:draw(0,0)
        if player1.victim_infoBar then
            player1.victim_infoBar:draw(0,0)
        end
    end
    if player2 then
        player2.infoBar:draw(0,0)
        if player2.victim_infoBar then
            player2.victim_infoBar:draw(0,0)
        end
    end
    if player3 then
        player3.infoBar:draw(0,0)
        if player3.victim_infoBar then
            player3.victim_infoBar:draw(0,0)
        end
    end
    show_debug_grid()
    show_debug_controls()
    show_debug_variables()
    show_debug_indicator()
end

function arcadeState:keypressed(key, unicode)
    check_debug_keys(key)
end

function arcadeState:wheelmoved( dx, dy )
end