local Meteor = {
    MIN_SIZE = 8,
    MAX_SIZE = 16,
    MIN_SPEED = 32,
    MAX_SPEED = 64,
    SHOCKWAVE = 32,
    maxLineOpacity = 255
}
Meteor.__index = Meteor

function Meteor.new(startX, endX, speed, size)
    startX = startX + GAME_X
    endX = endX + GAME_X
    local this = {}
    setmetatable(this, Meteor)
    local r = math.atan2(GAME_Y + GAME_HEIGHT, endX - startX)
    this.vx = speed * math.cos(r)
    this.vy = speed * math.sin(r)
    local warningOffset = 2 * this.vy - size * math.random()
    this.x = startX - warningOffset * math.cos(r)
    this.y = GAME_Y - warningOffset * math.sin(r)
    this.size = size
    this.lineOpacity = 0
    this.finished = false
    return this
end

function Meteor.generateRandom()
    local startX = math.floor(math.random() * GAME_WIDTH)
    local endX = math.floor(math.random() * GAME_WIDTH)
    local speed = Meteor.MIN_SPEED + math.floor(math.random() * (Meteor.MAX_SPEED - Meteor.MIN_SPEED))
    local size = Meteor.MIN_SIZE + math.floor(math.random() * (Meteor.MAX_SIZE - Meteor.MIN_SIZE))
    return Meteor.new(startX, endX, speed, size)
end

function Meteor:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.lineOpacity = math.min(Meteor.maxLineOpacity, self.lineOpacity + dt * 128)
    if self.y >= GAME_Y + GAME_HEIGHT then
        self.finished = true
        impact(self)
    end
end

function Meteor:hit()
    score = score + 10
    meteorsDestroyed = meteorsDestroyed + 1
    self.finished = true
    self:createChunks()
end

function Meteor:createChunks()
    local MIN_CHUNKS = 2
    local MAX_CHUNKS = 6
    local r = math.atan2(self.vy, self.vx)
    local speed = math.sqrt(self.vy^2 + self.vx^2)
    for i = 1, MIN_CHUNKS + math.random() * (MAX_CHUNKS - MIN_CHUNKS) do
        local a = (math.random() * math.pi / 16) - math.pi / 16
        local v = math.random() + 0.5
        table.insert(chunks, Chunk.new(self.x, self.y, r + a, speed * v))
    end
end

function Meteor:draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.size)
    if Meteor.maxLineOpacity > 0 then
        local y = GAME_Y + GAME_HEIGHT - self.y
        love.graphics.setColor(0, 0, 0, self.lineOpacity)
        love.graphics.line(self.x, self.y, self.x + (y * self.vx / self.vy), self.y + y)
    end
end

return Meteor