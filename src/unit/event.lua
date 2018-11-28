local class = require "lib/middleclass"
local Event = class('Event', Unit)

function Event:initialize(name, sprite, x, y, f, input)
    Unit.initialize(self, name, sprite, x, y, f, input)
    self.type = "event"
    self.properties = f
end

function Event:setOnStage(stage)
    stage.objects:add(self)
    self.isDisabled = self.properties.disabled  -- disable Point events
end

local statesForGo = { walk = true, stand = true, run = true, duck = true, eventMove = true }
function Event:checkAndStart(player)
    if self.properties.go -- 'go' event type
        and statesForGo[player.state]
        and player.z <= player:getMinZ()
    then
        player:setState(player.eventMove, {
            duration = self.properties.duration,
            animation = self.properties.animation,
            face = tonumber(self.properties.face),
            x = self.properties.go.x,
            y = self.properties.go.y,
            z = self.properties.z,
            fadein = self.properties.fadein,
            fadeout = self.properties.fadeout,
            nextevent = self.properties.nextevent,
            event = self
        })
        return true
    end
    return false
end

function Event:startNext(startByPlayer)
    dp("= Start Next event:", self.properties.nextevent)
    if self.properties.nextevent then
        return self:startByName(self.properties.nextevent, startByPlayer)
    end
    return false
end

function Event:startByName(eventName, startByPlayer)
    dp("= Start Event by name:", eventName, startByPlayer and startByPlayer.name or "na")
    local event = stage.objects:getByName(eventName)
    if event then
        return event:startEvent(startByPlayer)
    end
    return false
end

local collidedPlayer = {}
function Event:updateAI(dt)
    local wasApplied = false
    if self.isDisabled then
        return
    end
    -- Run Event on Players collision
    collidedPlayer = {}
    for i = 1, GLOBAL_SETTING.MAX_PLAYERS do
        local player = getRegisteredPlayer(i)
        if player and player:isAlive() then
            if statesForGo[player.state] and self.shape:collidesWith(player.shape) then
                collidedPlayer[#collidedPlayer+1] = player
            end
        end
    end
    if #collidedPlayer > 0 then
        if self.properties.move == "player" then
            wasApplied = self:checkAndStart(collidedPlayer[1]) --1st detected player
        elseif self.properties.move == "players" then --all alive players
            for i = 1, GLOBAL_SETTING.MAX_PLAYERS do
                local player = getRegisteredPlayer(i)
                if player and player:isAlive() then
                    wasApplied = self:checkAndStart(player) or wasApplied --every alive walking player
                end
            end
        else
            error("Event '"..self.name.."' unknown move type: "..tostring(self.properties.move))
        end
        self.isDisabled = wasApplied
    end
end

function Event:startEvent(startByPlayer)
    if self.isDisabled then
        return false
    end
    local wasApplied = false
    if startByPlayer and self.properties.move == "player" then
        wasApplied = self:checkAndStart(startByPlayer) --1st detected player
    elseif self.properties.move == "players" then --all alive players
        for i = 1, GLOBAL_SETTING.MAX_PLAYERS do
            local player = getRegisteredPlayer(i)
            if player and player:isAlive() then
                wasApplied = self:checkAndStart(player) or wasApplied --every alive walking player
            end
        end
    else
        error("Event '"..self.name.."' unknown move type: "..tostring(self.properties.move))
    end
    self.isDisabled = wasApplied
    return wasApplied
end

function Event:onHurt()
end

function Event:drawShadow()
end

function Event:defaultDraw(l, t, w, h)
    if not self.isDisabled then
        colors:set("red", nil, 80)
        love.graphics.rectangle("line", l + self.x - self.width/2, t + self.y - self.height/2, self.width, self.height)
    end
end

return Event
