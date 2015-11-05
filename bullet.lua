local Bullet = {
	TRAIL_FADE = 512,
}
Bullet.__index = Bullet

function Bullet.new(x, y, r, speed, size)
	local this = {}
	setmetatable(this, Bullet)
	this.x = x
	this.y = y
	this.vx = speed * math.cos(r)
	this.vy = speed * math.sin(r)
	this.size = size
	this.finished = false
	this.trail = {}
	return this
end

function Bullet:update(dt)
	if self.finished then return end
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt
	if #self.trail == 0 or (self.x - self.trail[#self.trail].x) ^ 2 + (self.y - self.trail[#self.trail].y) ^ 2 > (self.size / 2) ^ 2 then
		table.insert(self.trail, {x = self.x, y = self.y, opac = 255})
	end
	-- check collisions
	for _, m in pairs(meteors) do
		local distSquared = (m.x - self.x)^2 + (m.y - self.y)^2
		if distSquared < (m.size + self.size)^2 then
			self.finished = true
			m:hit()
			table.insert(explosions, Explosion.new(self.x, self.y))
		end
	end
	-- update trail
	local finished = {}
	for i, t in pairs(self.trail) do
		t.opac = math.max(0, t.opac - Bullet.TRAIL_FADE * dt)
		if t.opac == 0 then
			table.insert(finished, 1)
		end
	end
	for i = #finished, 1, -1 do
		table.remove(self.trail, finished[i])
	end
end

function Bullet:draw()
	if self.finished then return end
	love.graphics.setColor(255, 255, 255)
	love.graphics.circle("fill", self.x, self.y, self.size)
	for _, t in pairs(self.trail) do
		love.graphics.setColor(255, 255, 255, t.opac)
		love.graphics.circle("fill", t.x, t.y, self.size)
	end
end

return Bullet