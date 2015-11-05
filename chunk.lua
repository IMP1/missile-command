local Chunk = {
    FADE_DURATION = 4,
    RADIUS = 2
}
Chunk.__index = Chunk

function Chunk.new(x, y, r, speed)
    local this = {}
    setmetatable(this, Chunk)
    this.x = x
    this.y = y
    this.vx = speed * math.cos(r)
    this.vy = speed * math.sin(r)
    this.fade = 0
    this.finished = false
    return this
end

function Chunk:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.fade = self.fade + dt
    if self.fade >= Chunk.FADE_DURATION then
        self.finished = true
    end
    if self.y >= GAME_HEIGHT and not self.finished then
        self.finished = true
        impact(self)
    end
end

function Chunk:draw()
    love.graphics.setColor(32, 0, 0, 255 - (self.fade * 255 / 4))
    love.graphics.circle("fill", self.x, self.y, Chunk.RADIUS)
end

return Chunk