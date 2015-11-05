--[[ Contants for the game dimensions ]]
GUI_HEIGHT = 264
GAME_X = 16
GAME_Y = 16
GAME_WIDTH = love.window.getWidth() - 32
GAME_HEIGHT = love.window.getHeight() - GUI_HEIGHT

--[[ "Classes" ]]
Meteor = require("meteor")
Bullet = require("bullet")
Chunk = require("chunk")
Turret = require("turret")
Building = require("building")
Explosion = require("explosion")
Screen = require("screen")

--[[ Function determining how often meteors spawn.
    timer : time in seconds since game begun ]]
function spawnDelay(timer)
    if timer < 0 then
        return 9999
    elseif timer < 120 then
        return math.min(4, math.max(2, 240 / (timer + 30)))
    elseif timer < 150 then
        return math.min(4, math.max(1.5, 240 / (timer + 30)))
    elseif timer < 240 then
        return 2
    else
        return (math.sin(timer/2) + 1) / 2 + 1
    end
end

--[[ Function to determine the colour of the background
    timer : time in seconds since game begun ]]
function backgroundColour(timer)
    local speed = 100
    local maxGreen = 160
    local minGreen = 50
    local greenRange = maxGreen - minGreen
    local r = 51
    local b = 165
    local g = math.cos(timer / speed) * greenRange / 2 + minGreen + greenRange / 2
    return r, g, b
end

--[[ Function to shake the screen.
    duration : time to shake for
    power    : power of shake ]]
function shakeScreen(duration, power)
    Screen:shake(duration, power, 0.5)
end

--[[ Load game ]]
function love.load()
    --[[ Load music ]]
    bgm = love.audio.newSource("03 MoozE - Radwind Pt1.ogg")
    bgm:setVolume(0.5)
    bgm:play()
    --[[ Set default graphics style ]]
    love.graphics.setBackgroundColor(255, 255, 255)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)
    --[[ Change cursor and trap mouse in the window ]]
    cursorImageData = love.image.newImageData("cursor.png")
    cursor = love.mouse.newCursor(cursorImageData, 8, 8)
    love.mouse.setCursor(cursor)
    love.mouse.setGrabbed(true)
    love.mouse.setVisible(true)
    --[[ Setup random seed ]]
    math.randomseed(os.time()); math.random(); math.random(); math.random()
    --[[ Initial variable setup ]]
    paused = false
    timer = -10
    spawnCounter = 10
    score = 0
    shotsFired = 0
    meteorsDestroyed = 0
    gameOver = false
    meteors = {}
    explosions = {}
    chunks = {}
    bullets = {}
    --[[ List of turrets ]]
    turrets = {
        Turret.new(32, GAME_HEIGHT),
        Turret.new(GAME_WIDTH / 2, GAME_HEIGHT),
        Turret.new(GAME_WIDTH - 32, GAME_HEIGHT),
    }
    selectedTurret = 1
    --[[ Function for scanner 1 dying ]]
    local scanner1Death = function(self)
        love.mouse.setVisible(false)
    end
    local scanner1Update = function(self, dt)
        if self.lastHealth == nil then self.lastHealth = self.health end
        if self.lastHealth  ~= self.health then
            local cursorOpacity = function(x, y, r, g, b, a)
                local alpha = math.max(0, math.min(255, a * self.health / 100))
                return r, g, b, alpha
            end
            local imageData = love.image.newImageData("cursor.png")
            imageData:mapPixel(cursorOpacity)
            cursor = love.mouse.newCursor(imageData, 8, 8)
            love.mouse.setCursor(cursor)
            self.lastHealth = self.health
        end
    end
    --[[ Function for scanner 2 dying ]]
    local scanner2Update = function(self)
        Meteor.maxLineOpacity = 255 * self.health / 100
    end
    local scanner2Death = function(self)
        Meteor.maxLineOpacity = 0
    end
    --[[ Update function for the ammo generator buildings ]]
    local ammoUpdate = function(self, dt)
        if self.target.ammo < self.target.maxAmmo then
            self.ammoGenerationTimer = self.ammoGenerationTimer + dt
            if self.ammoGenerationTimer >= self:ammoGenerationDelay() then
                self.target.ammo = self.target.ammo + 1
                self.ammoGenerationTimer = self.ammoGenerationTimer - self:ammoGenerationDelay()
            end
        end
    end
    --[[ Draw function for ammo building completion bars ]]
    local ammoDraw = function(self)
        love.graphics.setColor(32, 32, 32)
        local w = 24
        love.graphics.rectangle("line", self.x - w/2, self.y + self.height + 4, w, 4)
        w = w * self.ammoGenerationTimer / self:ammoGenerationDelay()
        love.graphics.rectangle("fill", self.x - w/2, self.y + self.height + 4, w, 4)
    end
    --[[ List of buildings ]]
    buildings = {
        Building.new(GAME_WIDTH / 4, GAME_HEIGHT, "radar", false, scanner1Update, scanner1Death, nil),
        Building.new(GAME_WIDTH / 12, GAME_HEIGHT, "factory", false, ammoUpdate, nil, ammoDraw),
        Building.new(4.4 * GAME_WIDTH / 8, GAME_HEIGHT, "factory", false, ammoUpdate, nil, ammoDraw),
        Building.new(11 * GAME_WIDTH / 12, GAME_HEIGHT, "factory", false, ammoUpdate, nil, ammoDraw),
        Building.new(3 * GAME_WIDTH / 4, GAME_HEIGHT, "city", true),
        Building.new(4 * GAME_WIDTH / 12, GAME_HEIGHT, "city", true),
        Building.new(8 * GAME_WIDTH / 12, GAME_HEIGHT, "city", true),
        Building.new(10 * GAME_WIDTH / 12, GAME_HEIGHT, "radar", false, scanner2Update, scanner2Death, nil),
    }
    local ammoGenerationDelay = function(self) 
        -- base delay
        local delay = 2 + math.max(0, timer / 600)
        local h = math.max(0.01, self.health)
        delay = delay / (h / 100)
        return delay
    end
    buildings[2].target = turrets[1]
    buildings[2].ammoGenerationDelay = ammoGenerationDelay
    buildings[2].ammoGenerationTimer = 0
    buildings[3].target = turrets[2]
    buildings[3].ammoGenerationDelay = ammoGenerationDelay
    buildings[3].ammoGenerationTimer = 0
    buildings[4].target = turrets[3]
    buildings[4].ammoGenerationDelay = ammoGenerationDelay
    buildings[4].ammoGenerationTimer = 0
    showTimer = true
    screenShakes = {}
end

-- pauses if the person alt-tabs away
function love.focus(f)
    paused = not f
    love.mouse.setGrabbed(not paused)
end

function love.update(dt)
    if paused then return end -- don't update if paused
    Screen:update(dt)
    if not gameOver then
        timer = timer + dt -- update timer unless game over
    end
    -- Update Spawns
    spawnCounter = spawnCounter - dt
    if spawnCounter <= 0 then
        table.insert(meteors, Meteor.generateRandom())
        spawnCounter = spawnCounter + spawnDelay(timer)
    end
    -- Update Meteors
    local finished = {}
    for i, m in pairs(meteors) do
        m:update(dt)
        if m.finished then
            table.insert(finished, i)
        end
    end
    for i = #finished, 1, -1 do
        table.remove(meteors, finished[i])
    end
    -- Update Chunks
    finished = {}
    for i, c in pairs(chunks) do
        c:update(dt)
        if c.finished then
            table.insert(finished, i)
        end
    end
    for i = #finished, 1, -1 do
        table.remove(chunks, finished[i])
    end
    -- Update Bullets
    finished = {}
    for i, b in pairs(bullets) do
        b:update(dt)
        if b.finished then
            table.insert(finished, i)
        end
    end
    for i = #finished, 1, -1 do
        table.remove(bullets, finished[i])
    end
    -- Update Turrets
    finished = {}
    for i, t in pairs(turrets) do
        t:update(dt)
        if t.destroyed then
            table.insert(finished, i)
            if i == selectedTurret then
                selectedTurret = 1
            end
        end
    end
    for i = #finished, 1, -1 do
        table.remove(turrets, finished[i])
    end
    -- Update Buildings
    finished = {}
    for i, b in pairs(buildings) do
        b:update(dt)
        if b.destroyed then
            table.insert(finished, i)
        end
    end
    for i = #finished, 1, -1 do
        table.remove(buildings, finished[i])
    end
    -- Update Explosions
    finished = {}
    for i, e in pairs(explosions) do
        e:update(dt)
        if e.destroyed then
            table.insert(finished, i)
        end
    end
    for i = #finished, 1, -1 do
        table.remove(explosions, finished[i])
    end
    -- Determine Game Over
    local vitalBuildingsRemaining = 0
    for _, b in pairs(buildings) do
        if b.vital then 
            vitalBuildingsRemaining = vitalBuildingsRemaining + 1 
        end
    end
    if vitalBuildingsRemaining == 0 then
        gameOver = true
    end
end

function love.draw()
    Screen:set()
        --[[ draw background ]]
        local r, g, b = backgroundColour(timer)
        love.graphics.setBackgroundColor(r, g, b)
        --[[ draw ground ]]
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("fill", GAME_X - 64, GAME_Y + GAME_HEIGHT, GAME_WIDTH + 128, Screen.HEIGHT - GAME_HEIGHT + 64)
        --[[ draw objects ]]
        for i, t in pairs(turrets) do
            t:draw(i == selectedTurret)
        end
        for _, b in pairs(buildings) do
            b:draw()
        end
        for _, m in pairs(meteors) do
            m:draw()
        end
        for _, c in pairs(chunks) do
            c:draw()
        end
        for _, b in pairs(bullets) do
            b:draw()
        end
        for _, e in pairs(explosions) do
            e:draw()
        end
    Screen:unset()
    --[[ draw GUI ]]
    
    --[[ draw timer ]]
    love.graphics.setColor(32, 32, 32)
    local t
    if timer >= 0 then
        local h = math.floor(timer / (60 * 60))
        local m = math.floor(timer / 60) % 60
        local s = timer % 60
        t = string.format("%02d:%02d:%04.1f", h, m, s)
    else
        local s = math.abs(timer)
        t = string.format("-00:00:%04.1f", s)
    end
    love.graphics.printf("Time: " .. t, 0, Screen.HEIGHT - 16, Screen.WIDTH, "center")
    -- love.graphics.printf(spawnDelay(timer), 0, Screen.HEIGHT - 16, Screen.WIDTH, "left") -- for debugging
    
    if gameOver then
        --[[ draw game over screen ]]
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle("fill", 0, 0, Screen.WIDTH, Screen.HEIGHT)
        love.graphics.setColor(255, 255, 255)
        local h = timer / (60 * 60)
        local m = (timer / 60) % 60
        local s = timer % 60
        local msg = string.format("You survived for %d hours, %d minutes and %d seconds.", h, m, s)
        love.graphics.printf(msg, 0, 64 + 16 * 2, Screen.WIDTH, "center")
        msg = string.format("You fired %d shots, destroying %d meteors.", shotsFired, meteorsDestroyed)
        love.graphics.printf(msg, 0, 64 + 16 * 6, Screen.WIDTH, "center")
        love.graphics.printf("Click anywhere to continue", 0, Screen.HEIGHT / 2 + 16, Screen.WIDTH, "center")
    elseif paused then
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle("fill", 0, 0, Screen.WIDTH, Screen.HEIGHT)
        love.graphics.setColor(255, 255, 255)
        love.graphics.printf("Paused", 0, Screen.HEIGHT / 2 - 16, Screen.WIDTH, "center")
        love.graphics.printf("Press any key to continue", 0, Screen.HEIGHT / 2 + 16, Screen.WIDTH, "center")
    end
end

function love.keypressed(key, isRepeat)
    if gameOver then -- if in game over, keypress restarts
        love.load()
        return
    end
    local num = tonumber(key)
    if num ~= nil and num >= 1 and num <= #turrets then
        selectedTurret = num
    end
    --[[ quit key presses ]]
    if (key == "q" or key == "w") and love.keyboard.isDown("lctrl") then
        love.event.quit()
    end
    if key == "f4" and love.keyboard.isDown("lalt") then
        love.event.quit()
    end
    --[[ hide/show health of buildings ]]
    if key == "tab" then
        Building.drawHealth = not Building.drawHealth
    end
    --[[ pause game ]]
    if (key == "escape" or key == " " or key == "p") and not paused then
        paused = true
        love.mouse.setGrabbed(false)
    elseif paused then
        paused = false
        love.mouse.setGrabbed(true)
    end
    --[[ Force gameover ]]
    if key == "k" then
        for _, t in pairs(turrets) do
            t.destroyed = true
        end
        for _, b in pairs(buildings) do
            b:destroy()
        end
    end
    --[[ Debugging Commands ]]
    if key == "t" then
        turrets[selectedTurret]:destroy()
    end
    if key == "o" then
        for _, b in pairs(buildings) do
            b:damage(0.1)
        end
    end
    if key == "i" then
        for _, b in pairs(buildings) do
            if b.vital then
                b:damage(0.1)
            end
        end
    end
end

function love.mousepressed(x, y, key)
    if gameOver then -- if in game over, mousepress restarts
        love.load()
        return
    end
    if paused then
        paused = false
        love.mouse.setGrabbed(true)
        return
    end
    --[[ Fire current turret ]]
    if key == "l" and #turrets > 0 then
        turrets[selectedTurret]:fire()
    --[[ scroll through turrets ]]
    elseif key == "wu" or key == "m" then
        selectedTurret = 1 + selectedTurret % #turrets
    elseif key == "wd" then
        selectedTurret = selectedTurret - 1
        if selectedTurret == 0 then selectedTurret = #turrets end
    end
end

-- handle an object hitting the ground
function impact(obj)
    local x, y = obj.x, obj.y
    if getmetatable(obj) == Meteor then -- object is a meteor
        for _, t in pairs(turrets) do
            local distSquared = (t.y - y)^2 + (t.x - x)^2
            if distSquared <= (Meteor.SHOCKWAVE + t.width)^2 then
                local nearness = 1 - (distSquared / (Meteor.SHOCKWAVE + t.width)^2)
                t:damage(nearness)
            end
        end
        for _, b in pairs(buildings) do
            local distSquared = (b.y - y)^2 + (b.x - x)^2
            if distSquared <= (Meteor.SHOCKWAVE + b.width)^2 then
                local nearness = 1 - (distSquared / (Meteor.SHOCKWAVE + b.width)^2)
                b:damage(nearness)
            end
        end
        table.insert(explosions, Explosion.new(x, y))
    elseif getmetatable(obj) == Chunk then -- object is debris
        for _, t in pairs(turrets) do
            local distSquared = (t.y - y)^2 + (t.x - x)^2
            if distSquared <= (Chunk.RADIUS + t.width)^2 then
                local nearness = 1 - (distSquared / (Meteor.SHOCKWAVE + t.width)^2)
                t:damage(nearness / 10)
            end
        end
        for _, b in pairs(buildings) do
            local distSquared = (b.y - y)^2 + (b.x - x)^2
            if distSquared <= (Chunk.RADIUS + b.width)^2 then
                local nearness = 1 - (distSquared / (Meteor.SHOCKWAVE + b.width)^2)
                b:damage(nearness / 10)
            end
        end
    end
end