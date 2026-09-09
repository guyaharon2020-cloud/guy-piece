-- Makes each ship slowly drift in a small circle around its spawn point,
-- always facing its direction of travel. All ship parts are Anchored, so
-- Model:PivotTo() moves the whole ship (hull, cabin, mast, cannons, humans,
-- health bar) as one rigid group with no physics/welds needed.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local function driftShip(hull)
	local ship = hull.Parent
	if not ship or not ship.PrimaryPart then
		return
	end

	local origin = ship:GetPivot().Position
	local radius = math.random(Config.ShipDriftRadiusMin, Config.ShipDriftRadiusMax)
	local angularSpeed = math.rad(math.random(Config.ShipDriftDegreesPerSecondMin, Config.ShipDriftDegreesPerSecondMax))
	local phase = math.random() * math.pi * 2

	local elapsed = 0
	while ship.Parent do
		local dt = task.wait(0.1)
		elapsed += dt

		local angle = phase + elapsed * angularSpeed
		local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local facing = angle + math.pi / 2 -- tangent to the circle: face the direction of travel

		ship:PivotTo(CFrame.new(origin + offset) * CFrame.Angles(0, facing, 0))
	end
end

CollectionService:GetInstanceAddedSignal("Ship"):Connect(function(hull)
	task.spawn(driftShip, hull)
end)

for _, hull in ipairs(CollectionService:GetTagged("Ship")) do
	task.spawn(driftShip, hull)
end
