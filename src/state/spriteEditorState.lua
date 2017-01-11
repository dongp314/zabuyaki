-- Sprite Editor
spriteEditorState = {}

local time = 0
local screen_width = 640
local screen_height = 480
local menu_item_h = 40
local menu_y_offset = 200 - menu_item_h
local menu_x_offset = 0
local hint_y_offset = 80
local title_y_offset = 24
local left_item_offset  = 6
local top_item_offset  = 6
local item_width_margin = left_item_offset * 2
local item_height_margin = top_item_offset * 2 - 2

local txt_options_logo = love.graphics.newText( gfx.font.kimberley, "SPRITE" )

local txt_items = {"ANIMATIONS", "SHADERS", "EXPORT", "BACK"}
local txt_hints = {"", "", "", "" }

--local heroes = {
--}

--local weapons = {
--}

local hero = nil
local sprite = nil
local animations = nil

local function fillMenu(txt_items, txt_hints)
    local m = {}
    local max_item_width, max_item_x = 8, 0
    for i = 1, #txt_items do
        local w = gfx.font.arcade4:getWidth(txt_items[i])
        if w > max_item_width then
            max_item_x = menu_x_offset + screen_width / 2 - w / 2
            max_item_width = w
        end
    end
    for i = 1, #txt_items do
        local w = gfx.font.arcade4:getWidth(txt_items[i])
        local h = gfx.font.arcade4:getHeight(txt_items[i])
        local x = menu_x_offset + screen_width / 2 - w / 2
        local y = menu_y_offset + i * menu_item_h

        m[#m + 1] = {
            item = txt_items[i],
            hint = txt_hints[i],
            x = x,
            y = y,
            rect_x = max_item_x,
            w = max_item_width,
            h = h,
            n = 1
        }
    end
    return m
end

local menu = fillMenu(txt_items, txt_hints)

local menu_state, old_menu_state = 1, 1
local mouse_x, mouse_y = 0,0

local function CheckPointCollision(x,y, x1,y1,w1,h1)
    return x < x1+w1 and
            x >= x1 and
            y < y1+h1 and
            y >= y1
end


local sort_abc_func = function( a, b ) return a.bName < b.bName end

function spriteEditorState:enter(_, _hero)
    hero = _hero
    sprite = GetSpriteInstance(hero.sprite_instance)
    sprite.size_scale = 2
    animations = {}
    for key, val in pairs(sprite.def.animations) do
        --print(key, val)
        animations[#animations + 1] = key
    end
    table.sort( animations )
    menu[menu_state].n = 1
    SetSpriteAnimation(sprite,animations[menu[menu_state].n])
    mouse_x, mouse_y = 0,0
    --TEsound.stop("music")
    -- Prevent double press at start (e.g. auto confirmation)
    Control1.attack:update()
    Control1.jump:update()
    Control1.start:update()
    Control1.back:update()
    love.graphics.setLineWidth( 2 )
    self:wheelmoved(0, 0)   --pick 1st sprite to draw
end

--Only P1 can use menu / options
local function player_input(controls)
    if controls.jump:pressed() or controls.back:pressed() then
        sfx.play("sfx","menu_cancel")
        return Gamestate.pop()
    elseif controls.attack:pressed() or controls.start:pressed() then
        return spriteEditorState:confirm( mouse_x, mouse_y, 1)
    end
    if controls.horizontal:pressed(-1)then
        spriteEditorState:wheelmoved(0, -1)
    elseif controls.horizontal:pressed(1)then
        spriteEditorState:wheelmoved(0, 1)
    elseif controls.vertical:pressed(-1) then
        menu_state = menu_state - 1
    elseif controls.vertical:pressed(1) then
        menu_state = menu_state + 1
    end
    if menu_state < 1 then
        menu_state = #menu
    end
    if menu_state > #menu then
        menu_state = 1
    end
end

function spriteEditorState:update(dt)
    time = time + dt
    if menu_state ~= old_menu_state then
        sfx.play("sfx","menu_move")
        old_menu_state = menu_state
    end

    if sprite then
        UpdateSpriteInstance(sprite, dt)
    end

    player_input(Control1)
end

function spriteEditorState:draw()
    push:apply("start")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setFont(gfx.font.arcade4)
    for i = 1,#menu do
        local m = menu[i]
        if i == 1 then
            m.item = "#"..m.n.." "..animations[m.n]
            m.hint = "" --..heroes[m.n].sprite_instance
        elseif i == 2 then
            m.item = " #"..m.n.." "
            m.hint = "..."
        end
        local w = gfx.font.arcade4:getWidth(m.item)
        local wb = w + item_width_margin
        local h = gfx.font.arcade4:getHeight(m.item)

        if i == old_menu_state then
            love.graphics.setColor(0, 0, 0, 80)
            love.graphics.rectangle("fill",
                (screen_width - wb) / 2, m.y - top_item_offset,
                wb, h + item_height_margin, 4,4,1)
            love.graphics.setColor(255,200,40, 255)
            love.graphics.rectangle("line",
                (screen_width - wb) / 2, m.y - top_item_offset,
                wb, h + item_height_margin, 4,4,1)

            love.graphics.setColor(255, 255, 255, 255)
            local w = gfx.font.arcade4:getWidth( m.hint )
            love.graphics.print(m.hint, (screen_width - w) / 2, screen_height - hint_y_offset)

        end
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(m.item, (screen_width - w) / 2, m.y )
        if GLOBAL_SETTING.MOUSE_ENABLED and
                CheckPointCollision(mouse_x, mouse_y, (screen_width - wb) / 2, m.y - top_item_offset,
                    wb, h + item_height_margin )
        then
            menu_state = i
        end
    end
    --header
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(txt_options_logo, (screen_width - txt_options_logo:getWidth()) / 2, title_y_offset)

    --sprite
    local sc = sprite.def.animations[sprite.cur_anim][1]
    local x_step = (sc.ox or 20) * 4 + 8 or 100
    local x = screen_width /2 - (#hero.shaders - 1) * x_step / 2
    love.graphics.setColor(255, 255, 255, 255)
    for i = 1, #hero.shaders do
        if hero.shaders[i] then
            love.graphics.setShader(hero.shaders[i])
        end
        if sprite then
            DrawSpriteInstance(sprite, x + (i - 1) * x_step , menu_y_offset + menu_item_h / 2)
        end
        if hero.shaders[i] then
            love.graphics.setShader()
        end
    end
    if #hero.shaders < 1 then
        if sprite then --for Obstacles w/o shaders
            DrawSpriteInstance(sprite, screen_width /2, menu_y_offset + menu_item_h / 2)
        end
    end
    show_debug_indicator()
    push:apply("end")
end

function spriteEditorState:confirm( x, y, button, istouch )
    if (button == 1 and menu_state == #menu) or button == 2 then
        sfx.play("sfx","menu_cancel")
        TEsound.stop("music")
        TEsound.volume("music", GLOBAL_SETTING.BGM_VOLUME)
        return Gamestate.pop()
    end
    if button == 1 then
        if menu_state == 1 then
            sfx.play("sfx","menu_select")
        elseif menu_state == 2 then
            sfx.play("sfx","menu_select")
        end
    end
end

function spriteEditorState:mousepressed( x, y, button, istouch )
    if not GLOBAL_SETTING.MOUSE_ENABLED then
        return
    end
    spriteEditorState:confirm( x, y, button, istouch )
end

function spriteEditorState:mousemoved( x, y, dx, dy)
    if not GLOBAL_SETTING.MOUSE_ENABLED then
        return
    end
    mouse_x, mouse_y = x, y
end

function spriteEditorState:wheelmoved(x, y)
    local i = 0
    if y > 0 then
        i = 1
    elseif y < 0 then
        i = -1
    end
    menu[menu_state].n = menu[menu_state].n + i
    if menu_state == 1 then
        if menu[menu_state].n < 1 then
            menu[menu_state].n = #animations
        end
        if menu[menu_state].n > #animations then
            menu[menu_state].n = 1
        end
        SetSpriteAnimation(sprite, animations[menu[menu_state].n])

    elseif menu_state == 2 then
--        if menu[menu_state].n < 0 then
--            menu[menu_state].n = #weapons
--        end
--        if menu[menu_state].n > #weapons then
            menu[menu_state].n = 1
--        end
    end
    if menu_state ~= 3 then
        sfx.play("sfx","menu_move")
    end
end
