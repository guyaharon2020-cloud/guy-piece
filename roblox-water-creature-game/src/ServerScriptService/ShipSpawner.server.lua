-- Periodically spawns ships: bigger, tougher versions of rafts, picked from
-- several types (see GameConfig.ShipTypes) with different sizes, colors,
-- and human counts. Types with HasCannon also get tagged "Cannon" so
-- ShipCannons.server.lua fires on nearby players.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local shipsFolder = Workspace:FindFirstChild("Ships")
if not shipsFolder then
	shipsFolder = Instance.new("Folder")
	shipsFolder.Name = "Ships"
	shipsFolder.Parent = Workspace
end

local function createHuman(position)
	local human = Instance.new("Model")
	human.Name = "Human"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1, 2, 1)
	body.CFrame = CFrame.new(position)
	body.Anchored = true
	body.CanCollide = false
	body.Color = Color3.fromRGB(240, 200, 160)
	body.Parent = human

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.8, 0.8, 0.8)
	head.CFrame = CFrame.new(position + Vector3.new(0, 1.4, 0))
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(255, 224, 189)
	head.Parent = human

	human.PrimaryPart = body
	return human
end

-- A small floating bar above the ship's hull showing remaining Health, so
-- players can see how many more hits a ship needs.
local function createHealthBar(ship, hull, maxHealth)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 140, 0, 16)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hull

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 1, 0)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	back.BorderSizePixel = 0
	back.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Position = UDim2.new(0, 0, -1, -2)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Text = ship.Name
	label.Parent = billboard

	ship:GetAttributeChangedSignal("Health"):Connect(function()
		local health = ship:GetAttribute("Health") or 0
		local ratio = math.clamp(health / maxHealth, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end)
end

-- Decorative cannon barrels sticking out both sides of the hull, purely
-- visual (the actual firing logic lives in ShipCannons.server.lua).
local function addCannonBarrels(ship, hull)
	for _, side in ipairs({ -1, 1 }) do
		local barrel = Instance.new("Part")
		barrel.Name = "CannonBarrel"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(3, 0.8, 0.8)
		barrel.Color = Color3.fromRGB(35, 35, 38)
		barrel.Material = Enum.Material.Metal
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.CFrame = hull.CFrame * CFrame.new(0, 1, side * (hull.Size.Z / 2 + 1)) * CFrame.Angles(0, 0, math.rad(90))
		barrel.Parent = ship
	end
end

-- Flag, railings, and a bowsprit for a more detailed, ship-like silhouette.
-- The hull's local X axis is its length (bow/stern), Z is its beam
-- (port/starboard) — matches the cannon barrel and human-scatter offsets
-- above.
local function addShipDetails(ship, hull, shipType)
	local mastTop = hull.CFrame * CFrame.new(2, 18, 0)

	local flag = Instance.new("WedgePart")
	flag.Name = "Flag"
	flag.Size = Vector3.new(0.2, 2.5, 4)
	flag.Color = shipType.HullColor
	flag.Material = Enum.Material.Fabric
	flag.Anchored = true
	flag.CanCollide = false
	flag.CFrame = mastTop * CFrame.new(0, -1, 2) * CFrame.Angles(0, math.rad(90), 0)
	flag.Parent = ship

	for _, side in ipairs({ -1, 1 }) do
		local rail = Instance.new("Part")
		rail.Name = "Railing"
		rail.Size = Vector3.new(hull.Size.X * 0.92, 1.4, 0.4)
		rail.Color = Color3.fromRGB(60, 45, 30)
		rail.Material = Enum.Material.Wood
		rail.Anchored = true
		rail.CanCollide = false
		rail.CFrame = hull.CFrame * CFrame.new(0, hull.Size.Y / 2 + 0.7, side * (hull.Size.Z / 2 - 0.3))
		rail.Parent = ship
	end

	local bowsprit = Instance.new("Part")
	bowsprit.Name = "Bowsprit"
	bowsprit.Size = Vector3.new(8, 0.6, 0.6)
	bowsprit.Color = Color3.fromRGB(70, 50, 35)
	bowsprit.Material = Enum.Material.Wood
	bowsprit.Anchored = true
	bowsprit.CanCollide = false
	bowsprit.CFrame = hull.CFrame * CFrame.new(hull.Size.X / 2 + 3, hull.Size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(10))
	bowsprit.Parent = ship
end

local function spawnShip()
	if #shipsFolder:GetChildren() >= Config.MaxShips then
		return
	end

	local shipType = Config.PickShipType()

	local angle = math.random() * math.pi * 2
	local distance = math.random(80, Config.SpawnRadius)
	local x = Config.WaterCenter.X + math.cos(angle) * distance
	local z = Config.WaterCenter.Z + math.sin(angle) * distance
	local y = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 2

	local ship = Instance.new("Model")
	ship.Name = shipType.Name

	local hull = Instance.new("Part")
	hull.Name = "Hitbox"
	hull.Size = shipType.HullSize
	hull.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	hull.Anchored = true
	hull.Color = shipType.HullColor
	hull.Material = Enum.Material.WoodPlanks
	hull.Parent = ship

	ship.PrimaryPart = hull

	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(8, 5, 8)
	cabin.CFrame = hull.CFrame * CFrame.new(-hull.Size.X / 4, 5, 0)
	cabin.Anchored = true
	cabin.CanCollide = false
	cabin.Color = shipType.CabinColor
	cabin.Material = Enum.Material.Wood
	cabin.Parent = ship

	local mast = Instance.new("Part")
	mast.Name = "Mast"
	mast.Shape = Enum.PartType.Cylinder
	mast.Size = Vector3.new(18, 1, 1)
	mast.CFrame = hull.CFrame * CFrame.new(2, 9, 0) * CFrame.Angles(0, 0, math.rad(90))
	mast.Anchored = true
	mast.CanCollide = false
	mast.Color = Color3.fromRGB(70, 50, 35)
	mast.Parent = ship

	addShipDetails(ship, hull, shipType)

	if shipType.HasCannon then
		addCannonBarrels(ship, hull)
	end

	local humanCount = math.random(shipType.HumansMin, shipType.HumansMax)
	for _ = 1, humanCount do
		local localOffset = Vector3.new(
			math.random(-hull.Size.X * 4, hull.Size.X * 4) / 10,
			4,
			math.random(-hull.Size.Z * 4, hull.Size.Z * 4) / 10
		)
		local worldPosition = (hull.CFrame * CFrame.new(localOffset)).Position
		local human = createHuman(worldPosition)
		human.Parent = ship
	end

	local shipHealth = humanCount + shipType.HealthBonus + math.random(2, 5)
	ship:SetAttribute("ShipType", shipType.Key)
	ship:SetAttribute("HumanCount", humanCount)
	ship:SetAttribute("Health", shipHealth)
	ship:SetAttribute("MaxHealth", shipHealth)

	if shipType.HasCannon then
		ship:SetAttribute("CannonDamage", shipType.CannonDamage)
		ship:SetAttribute("CannonRange", shipType.CannonRange)
		ship:SetAttribute("CannonCooldown", shipType.CannonCooldown)
	end

	createHealthBar(ship, hull, shipHealth)

	CollectionService:AddTag(hull, "Ship")
	if shipType.HasCannon then
		CollectionService:AddTag(hull, "Cannon")
	end

	ship.Parent = shipsFolder
end

while true do
	spawnShip()
	task.wait(Config.ShipSpawnInterval)
end
