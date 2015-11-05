local Turret = {
	IMAGES = {
		base = love.graphics.newImage("turret_base.png"),
		gun = love.graphics.newImage("turret_gun.png"),
	},
	GUN_LENGTH = 4,
	START_AMMO = 10,
	START_RELOAD = 0.2,
	START_BULLET_SPEED = 192,
	START_BULLET_SIZE = 2,
}
Turret.__index = Turret

function Turret.new(x, y)
	local this = {}
	setmetatable(this, Turret)
	this.x = GAME_X + x
	this.y = GAME_Y + y
	this.width = Turret.IMAGES.base:getWidth()
	this.height = Turret.IMAGES.base:getHeight()
	this.midX = this.x
	this.midY = this.y - this.height/2
	this.r = -math.pi/2
	this.ammo = Turret.START_AMMO
	this.maxAmmo = this.ammo
	this.reloadTimer = 0
	this.reloadDelay = Turret.START_RELOAD
	this.bulletSpeed = Turret.START_BULLET_SPEED
	this.bulletSize = Turret.START_BULLET_SIZE
	this.health = 100
	this.destroyed = false
	return this
end

function Turret:update(dt)
	if self.destroyed then return end
	-- Update aim
	local mx, my = love.mouse.getPosition()
	local x = self.midX + 14 * math.cos(self.r)
	local y = self.midY + 14 * math.sin(self.r)
	self.r = math.atan2(my - y, mx - x)
	
	-- Update reload
	if self.reloadTimer > 0 then
		self.reloadTimer = math.max(0, self.reloadTimer - dt)
	end
end

function Turret:draw(selected)
	if self.destroyed then return end
	if selected then
		love.graphics.setColor(255, 255, 255)
	else
		love.graphics.setColor(128, 128, 128)
	end
	local ox, oy = Turret.IMAGES.gun:getWidth()/2, Turret.IMAGES.gun:getHeight()/2
	love.graphics.draw(Turret.IMAGES.base, self.x, self.y - self.height, 0, 1, 1, ox)
	love.graphics.draw(Turret.IMAGES.gun, self.x, self.y + 12 - self.height, self.r, 1, 1, ox, oy)
	if Building.drawHealth then
		love.graphics.setColor(192, 192, 192)
		local h = string.format("%.2f", self.health)
		love.graphics.printf(h .. "%", self.x - self.width / 2, self.y - 32 - self.height, self.width, "center")
	end
	love.graphics.setColor(32, 32, 32)
	love.graphics.printf(self.ammo, self.x - self.width / 2, self.y + 8, self.width, "center")
end

function Turret:fire()
	if self.ammo <= 0 then return end
	if self.reloadTimer > 0 then return end
	local x = self.midX + 14 * math.cos(self.r)
	local y = self.midY + 14 * math.sin(self.r)
	table.insert(bullets, Bullet.new(x, y, self.r, self.bulletSpeed, self.bulletSize))
	self.reloadTimer = self.reloadDelay
	self.ammo = self.ammo - 1
	shotsFired = shotsFired + 1
end

function Turret:damage(nearness)
	self.health = self.health - nearness * 20
	if self.health <= 0 then
		self.health = 0
        self:destroy()
	end
end

function Turret:destroy()
	self.destroyed = true
	if self.onDeath then
		self:onDeath()
	end
    table.insert(explosions, Explosion.new(self.x, self.y))
end

return Turret