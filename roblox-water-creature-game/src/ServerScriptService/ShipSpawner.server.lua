-- Periodically spawns ships: bigger, tougher versions of rafts. Ships carry
-- more humans (a bigger payout) but have a Health pool and hit back while
-- being attacked, so upgrading in the shop pays off most against these.

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

	ship:GetAttributeChangedSignal("Health"):Connect(function()
		local health = ship:GetAttribute("Health") or 0
		local ratio = math.clamp(health / maxHealth, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end)
end

local function spawnShip()
	if #shipsFolder:GetChildren() >= Config.MaxShips then
		return
	end

	local angle = math.random() * math.pi * 2
	local distance = math.random(80, Config.SpawnRadius)
	local x = Config.WaterCenter.X + math.cos(angle) * distance
	local z = Config.WaterCenter.Z + math.sin(angle) * distance
	local y = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 2

	local ship = Instance.new("Model")
	ship.Name = "Ship"

	local hull = Instance.new("Part")
	hull.Name = "Hitbox"
	hull.Size = Vector3.new(32, 6, 12)
	hull.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	hull.Anchored = true
	hull.Color = Color3.fromRGB(90, 65, 45)
	hull.Material = Enum.Material.WoodPlanks
	hull.Parent = ship

	ship.PrimaryPart = hull

	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(8, 5, 8)
	cabin.CFrame = hull.CFrame * CFrame.new(-6, 5, 0)
	cabin.Anchored = true
	cabin.CanCollide = false
	cabin.Color = Color3.fromRGB(120, 90, 60)
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

	local humanCount = math.random(Config.HumansPerShipMin, Config.HumansPerShipMax)
	for _ = 1, humanCount do
		local localOffset = Vector3.new(math.random(-140, 140) / 10, 4, math.random(-50, 50) / 10)
		local worldPosition = (hull.CFrame * CFrame.new(localOffset)).Position
		local human = createHuman(worldPosition)
		human.Parent = ship
	end

	local shipHealth = humanCount + math.random(2, 5)
	ship:SetAttribute("HumanCount", humanCount)
	ship:SetAttribute("Health", shipHealth)
	ship:SetAttribute("MaxHealth", shipHealth)

	createHealthBar(ship, hull, shipHealth)

	CollectionService:AddTag(hull, "Ship")
	ship.Parent = shipsFolder
end

while true do
	spawnShip()
	task.wait(Config.ShipSpawnInterval)
end
