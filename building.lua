local Building = {
	IMAGES = {
		city = love.graphics.newImage("city.png"),
		factory = love.graphics.newImage("factory.png"),
		radar = love.graphics.newImage("radar.png"),
	},
    drawHealth = true,
}
Building.__index = Building

function Building.new(x, y, image, vital, onUpdate, onDeath, onDraw)
	local this = {}
	setmetatable(this, Building)
	this.image = Building.IMAGES[image]
	this.width = this.image:getWidth()
	this.height = this.image:getHeight()
	this.vital = vital
	this.x = GAME_X + math.floor(x)
	this.y = GAME_Y + math.floor(y - this.height)
	this.onUpdate = onUpdate
	this.onDeath = onDeath
	this.onDraw = onDraw
	this.health = 100
	this.destroyed = false
	return this
end

function Building:update(dt)
	if self.destroyed then return end
	if self.onUpdate then
		self:onUpdate(dt)
	end
end

function Building:draw()
	if self.destroyed then return end
	love.graphics.setColor(255, 255, 255)
	-- love.graphics.rectangle("fill", self.x - self.width / 2, self.y, self.width, self.height)
	love.graphics.draw(self.image, self.x - self.width / 2, self.y)
	if self.onDraw then
		self:onDraw()
	end
	if Building.drawHealth then
		love.graphics.setColor(192, 192, 192)
		local h = string.format("%.2f", self.health)
		love.graphics.printf(h .. "%", self.x - self.width / 2, self.y - 16, self.width, "center")
	end
end

function Building:damage(nearness)
	self.health = self.health - nearness * 40
	if self.health <= 0 then
		self.health = 0
		self:destroy()
	end
end

function Building:destroy()
	self.destroyed = true
	score = score - 500
	if self.onDeath then
		self:onDeath()
	end
    table.insert(explosions, Explosion.new(self.x, self.y))
end

return Building