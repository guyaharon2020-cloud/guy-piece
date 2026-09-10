-- LabBuilder.lua
-- Procedurally builds the baseplate, laboratory hub, interaction stations
-- and world portals. Everything interactive is a plain Part carrying a
-- ProximityPrompt plus attributes the client's generic StationController
-- reads to know what to do -- no bespoke per-station client scripts needed.
--
-- ProximityPrompts (rather than click-detectors or touch zones) are used
-- deliberately: they render a large, consistent "hold to interact" button
-- on both PC (keyboard) and mobile (tap-and-hold), which is what the brief
-- asks for under "optimized for both PC and mobile".

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))

local LabBuilder = {}

local WORLD_COLORS = {
	Backyard = Color3.fromRGB(90, 200, 90),
	Laboratory = Color3.fromRGB(90, 200, 220),
	AlienPlanet = Color3.fromRGB(160, 60, 200),
	Volcano = Color3.fromRGB(230, 80, 30),
	GlitchWorld = Color3.fromRGB(0, 255, 100),
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function label(parent, text, studsOffset, size)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = size or UDim2.new(8, 0, 2, 0)
	billboard.StudsOffset = studsOffset or Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent

	local text1 = Instance.new("TextLabel")
	text1.BackgroundTransparency = 1
	text1.Size = UDim2.new(1, 0, 1, 0)
	text1.Font = Enum.Font.FredokaOne
	text1.TextScaled = true
	text1.TextColor3 = Color3.new(1, 1, 1)
	text1.TextStrokeTransparency = 0.2
	text1.Text = text
	text1.Parent = billboard
	return billboard
end

local function addPrompt(host, objectText, actionText, holdDuration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = objectText
	prompt.ActionText = actionText
	prompt.HoldDuration = holdDuration or 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = host
	return prompt
end

local function buildBaseplate()
	local baseplate = part({
		Name = "Baseplate",
		Size = Vector3.new(400, 4, 400),
		Position = Vector3.new(0, -2, 0),
		Color = Color3.fromRGB(70, 160, 80),
		Material = Enum.Material.Grass,
	})
	baseplate.Parent = Workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 1, -30)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(200, 255, 220)
	spawn.Duration = 0
	spawn.Parent = Workspace
end

local function buildLabPlatform()
	local platform = part({
		Name = "LabPlatform",
		Size = Vector3.new(60, 2, 60),
		Position = Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(235, 245, 255),
		Material = Enum.Material.SmoothPlastic,
	})
	platform.Parent = Workspace

	for _, offset in ipairs({
		Vector3.new(-28, 8, -28),
		Vector3.new(28, 8, -28),
		Vector3.new(-28, 8, 28),
		Vector3.new(28, 8, 28),
	}) do
		local pillar = part({
			Name = "LabPillar",
			Size = Vector3.new(3, 16, 3),
			Position = platform.Position + offset,
			Color = Color3.fromRGB(120, 220, 255),
			Material = Enum.Material.Neon,
		})
		pillar.Parent = Workspace

		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(120, 220, 255)
		pointLight.Range = 24
		pointLight.Brightness = 2
		pointLight.Parent = pillar
	end

	local titleAnchor = part({
		Name = "LabTitleAnchor",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, 14, 0),
		Transparency = 1,
		CanCollide = false,
	})
	titleAnchor.Parent = Workspace
	label(titleAnchor, "BUILD A WEIRD PET -- LABORATORY", Vector3.new(0, 0, 0), UDim2.new(30, 0, 5, 0))
end

local function buildStation(name, position, color, uiPanel, objectText)
	local station = part({
		Name = name,
		Size = Vector3.new(6, 6, 6),
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
	})
	station.Orientation = Vector3.new(0, 0, 90)
	station:SetAttribute("UIPanel", uiPanel)
	station.Parent = Workspace
	label(station, objectText, Vector3.new(0, 5, 0))
	addPrompt(station, objectText, "Open")
	return station
end

local function buildStations()
	buildStation("PartGeneratorStation", Vector3.new(0, 4, -12), Color3.fromRGB(90, 220, 120), "Generator", "Part Generator")
	buildStation("UpgradeStation", Vector3.new(-14, 4, -6), Color3.fromRGB(180, 100, 240), "Upgrades", "Lab Upgrades")
	buildStation("ShopStation", Vector3.new(14, 4, -6), Color3.fromRGB(240, 200, 60), "Shop", "Shop")
	buildStation("CollectionStation", Vector3.new(0, 4, 12), Color3.fromRGB(90, 180, 240), "Collection", "Collection Book")
	buildStation("InventoryStation", Vector3.new(-14, 4, 6), Color3.fromRGB(240, 120, 160), "Inventory", "Pet Inventory")
end

local function buildChallengeStations()
	local challenges = {
		{ id = "Race", name = "Race Track", color = Color3.fromRGB(255, 90, 90) },
		{ id = "Jump", name = "Jump Pad", color = Color3.fromRGB(255, 220, 90) },
		{ id = "Obstacle", name = "Obstacle Course", color = Color3.fromRGB(90, 255, 140) },
		{ id = "Strength", name = "Strength Test", color = Color3.fromRGB(200, 90, 255) },
		{ id = "Weirdness", name = "Weirdness Contest", color = Color3.fromRGB(90, 220, 255) },
	}

	local radius = 24
	for i, challenge in ipairs(challenges) do
		local angle = math.rad((i - 1) / #challenges * 360)
		local position = Vector3.new(math.sin(angle) * radius, 4, 30 + math.cos(angle) * radius)
		local pad = part({
			Name = "Challenge_" .. challenge.id,
			Size = Vector3.new(8, 1, 8),
			Position = position,
			Color = challenge.color,
			Material = Enum.Material.Neon,
		})
		pad:SetAttribute("ChallengeId", challenge.id)
		pad.Parent = Workspace
		label(pad, challenge.name, Vector3.new(0, 4, 0))
		addPrompt(pad, challenge.name, "Compete")
	end
end

local function buildWorldPortals()
	local radius = 90
	for _, world in ipairs(Worlds.List) do
		local angle = math.rad((world.order - 1) / #Worlds.List * 360 - 90)
		local position = Vector3.new(math.cos(angle) * radius, 6, math.sin(angle) * radius)
		local color = WORLD_COLORS[world.id] or Color3.fromRGB(200, 200, 200)

		local portal = part({
			Name = "Portal_" .. world.id,
			Size = Vector3.new(8, 12, 8),
			Position = position,
			Color = color,
			Material = Enum.Material.Neon,
			Shape = Enum.PartType.Cylinder,
		})
		portal.Orientation = Vector3.new(0, 0, 90)
		portal:SetAttribute("WorldId", world.id)
		portal.Parent = Workspace

		local costText = world.unlockCost > 0 and (" (" .. world.unlockCost .. " Coins)") or " (Start)"
		label(portal, world.name .. costText, Vector3.new(0, 9, 0))
		addPrompt(portal, world.name, "Travel")

		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 30
		light.Brightness = 2
		light.Parent = portal
	end
end

function LabBuilder.build()
	if Workspace:FindFirstChild("Baseplate") then
		return -- idempotent: don't rebuild if the server already has one
	end
	buildBaseplate()
	buildLabPlatform()
	buildStations()
	buildChallengeStations()
	buildWorldPortals()
end

return LabBuilder
