-- Periodically spawns ships: bigger, tougher versions of rafts, picked from
-- several types (see GameConfig.ShipTypes) with different sizes, colors,
-- and human counts. Types with HasCannon also get tagged "Cannon" so
-- ShipCannons.server.lua fires on nearby players.
--
-- The hull's local X axis is its length (bow/stern), Z is its beam
-- (port/starboard) — every decoration below is placed relative to that.
--
-- All the decorative detail (bow, masts/sails, railings, bowsprit,
-- portholes, wake trail) is built in one pcall-wrapped pass per ship: if
-- any single piece has a mistake, the ship still spawns with its working
-- hitbox/health/humans intact — only the decoration is skipped.

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

-- A pointed prow: a WedgePart whose taper runs along its own local Z axis by
-- default, rotated 90° about Y so that taper instead runs along the hull's
-- local X (length) axis — the flat, full-height face blends into the hull,
-- tapering forward to a point.
local function addBow(ship, hull, shipType)
	local bowLength = hull.Size.X * 0.18
	local bow = Instance.new("WedgePart")
	bow.Name = "Bow"
	bow.Size = Vector3.new(hull.Size.Z, hull.Size.Y, bowLength)
	bow.Color = shipType.HullColor
	bow.Material = Enum.Material.WoodPlanks
	bow.Anchored = true
	bow.CanCollide = false
	bow.CFrame = hull.CFrame * CFrame.new(hull.Size.X / 2 + bowLength / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	bow.Parent = ship
end

local function addRailingsAndBowsprit(ship, hull)
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

-- One mast with a crosswise square sail (and a colored stripe matching the
-- hull) at hull-local X offset `xOffset`. The tallest/foremost mast also
-- gets the flag.
local function addMast(ship, hull, shipType, xOffset, height, withFlag)
	local mast = Instance.new("Part")
	mast.Name = "Mast"
	mast.Shape = Enum.PartType.Cylinder
	mast.Size = Vector3.new(height, 1, 1)
	mast.CFrame = hull.CFrame * CFrame.new(xOffset, hull.Size.Y / 2 + height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	mast.Anchored = true
	mast.CanCollide = false
	mast.Color = Color3.fromRGB(70, 50, 35)
	mast.Parent = ship

	local sailHeight = height * 0.55
	local sailWidth = hull.Size.Z * 0.75
	local sailY = hull.Size.Y / 2 + height * 0.55

	local sail = Instance.new("Part")
	sail.Name = "Sail"
	sail.Size = Vector3.new(0.3, sailHeight, sailWidth)
	sail.Color = shipType.SailColor
	sail.Material = Enum.Material.Fabric
	sail.Anchored = true
	sail.CanCollide = false
	sail.CFrame = hull.CFrame * CFrame.new(xOffset, sailY, 0)
	sail.Parent = ship

	local stripe = Instance.new("Part")
	stripe.Name = "SailStripe"
	stripe.Size = Vector3.new(0.32, sailHeight * 0.18, sailWidth)
	stripe.Color = shipType.HullColor
	stripe.Material = Enum.Material.Fabric
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.CFrame = hull.CFrame * CFrame.new(xOffset, sailY, 0)
	stripe.Parent = ship

	if withFlag then
		local mastTop = hull.CFrame * CFrame.new(xOffset, hull.Size.Y / 2 + height, 0)
		local flag = Instance.new("WedgePart")
		flag.Name = "Flag"
		flag.Size = Vector3.new(0.2, 2.5, 4)
		flag.Color = shipType.HullColor
		flag.Material = Enum.Material.Fabric
		flag.Anchored = true
		flag.CanCollide = false
		flag.CFrame = mastTop * CFrame.new(0, -1, 2) * CFrame.Angles(0, math.rad(90), 0)
		flag.Parent = ship
	end
end

local function addMasts(ship, hull, shipType)
	local mastCount = shipType.MastCount or 1
	local mastHeight = 18 + hull.Size.X * 0.15

	if mastCount == 1 then
		addMast(ship, hull, shipType, 2, mastHeight, true)
		return
	end

	-- Spread masts along the hull's length, evenly, main mast (tallest,
	-- flagged) roughly amidships and the rest slightly shorter.
	local spread = hull.Size.X * 0.55
	for i = 1, mastCount do
		local t = (i - 1) / (mastCount - 1) -- 0..1 from stern to bow
		local xOffset = -spread / 2 + t * spread
		local isMain = i == math.ceil(mastCount / 2)
		addMast(ship, hull, shipType, xOffset, isMain and mastHeight or mastHeight * 0.8, isMain)
	end
end

local function addPortholes(ship, hull)
	local count = math.clamp(math.floor(hull.Size.X / 8), 3, 6)
	for i = 1, count do
		local t = (i - 0.5) / count
		local xOffset = -hull.Size.X * 0.4 + t * hull.Size.X * 0.8

		for _, side in ipairs({ -1, 1 }) do
			local porthole = Instance.new("Part")
			porthole.Name = "Porthole"
			porthole.Shape = Enum.PartType.Cylinder
			porthole.Size = Vector3.new(0.3, 1, 1)
			porthole.Color = Color3.fromRGB(20, 20, 25)
			porthole.Material = Enum.Material.Metal
			porthole.Anchored = true
			porthole.CanCollide = false
			porthole.CFrame = hull.CFrame * CFrame.new(xOffset, 0, side * (hull.Size.Z / 2 + 0.15)) * CFrame.Angles(0, math.rad(90), 0)
			porthole.Parent = ship
		end
	end
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
		-- A Cylinder's thin axis defaults to local X; rotating 90° about Y
		-- (not Z — that would stand it upright instead) sends that axis to
		-- world Z, pointing the barrel outward through the hull's side.
		barrel.CFrame = hull.CFrame * CFrame.new(0, 1, side * (hull.Size.Z / 2 + 1)) * CFrame.Angles(0, math.rad(90), 0)
		barrel.Parent = ship
	end
end

-- A trailing foam/wake ParticleEmitter at the bow, riding along with the
-- ship (it's a descendant of `ship`, so ShipMovement's Model:PivotTo moves
-- it along with everything else).
local function addWakeTrail(ship, hull)
	local wakeHolder = Instance.new("Part")
	wakeHolder.Name = "WakeEmitter"
	wakeHolder.Size = Vector3.new(0.2, 0.2, 0.2)
	wakeHolder.Transparency = 1
	wakeHolder.Anchored = true
	wakeHolder.CanCollide = false
	wakeHolder.CanQuery = false
	wakeHolder.CFrame = hull.CFrame * CFrame.new(hull.Size.X / 2, -hull.Size.Y / 2 + 1, 0)
	wakeHolder.Parent = ship

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 15
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(30, 10)
	emitter.Parent = wakeHolder
end

local function addAllDecorations(ship, hull, shipType)
	local ok, err = pcall(function()
		addBow(ship, hull, shipType)
		addRailingsAndBowsprit(ship, hull)
		addMasts(ship, hull, shipType)
		addPortholes(ship, hull)
		addWakeTrail(ship, hull)
		if shipType.HasCannon then
			addCannonBarrels(ship, hull)
		end
	end)
	if not ok then
		warn("ShipSpawner: decoration failed for a " .. shipType.Name .. " — " .. tostring(err))
	end
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

	local upperCabin = Instance.new("Part")
	upperCabin.Name = "UpperCabin"
	upperCabin.Size = Vector3.new(4.5, 3, 4.5)
	upperCabin.CFrame = hull.CFrame * CFrame.new(-hull.Size.X / 4, 8, 0)
	upperCabin.Anchored = true
	upperCabin.CanCollide = false
	upperCabin.Color = shipType.CabinColor
	upperCabin.Material = Enum.Material.Wood
	upperCabin.Parent = ship

	addAllDecorations(ship, hull, shipType)

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
