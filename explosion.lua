local Explosion = {
    SIZE = 64,
    DURATION = 0.2,
}
Explosion.__index = Explosion

function Explosion.new(x, y, size, duration)
    local this = {}
    setmetatable(this, Explosion)
    this.x = x
    this.y = y
    this.size = 0
    this.maxSize = size or Explosion.SIZE
    this.speed = this.maxSize / (duration or Explosion.DURATION)
    this.finished = false
    shakeScreen(0.6, this.maxSize / 2)
    return this
end

function Explosion:update(dt)
    if self.finished then return end
    self.size = self.size + self.speed * dt
    if self.size >= self.maxSize then
        self.finished = true
    end
end

function Explosion:draw()
    if self.finished then return end
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.circle("fill", self.x, self.y, self.size)
end

return Explosion