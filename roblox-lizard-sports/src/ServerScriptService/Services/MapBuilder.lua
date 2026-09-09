-- Procedurally builds a small but complete playground so the game works
-- immediately after a Rojo sync, with zero manual building required:
-- a spawn hub, two basking spots, a shop kiosk, a sprint track (with one
-- predator trap), a wall-climbing tower, and a bug-hunt arena.

local CollectionService = game:GetService("CollectionService")

local MapBuilder = {}

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth

	for key, value in pairs(props) do
		if key ~= "Parent" and key ~= "Tags" then
			p[key] = value
		end
	end

	if props.Tags then
		for _, tag in ipairs(props.Tags) do
			CollectionService:AddTag(p, tag)
		end
	end

	p.Parent = props.Parent
	return p
end

-- A thin, non-solid marker meant to sit flush on top of an existing floor
-- (start/finish/basking pads) so it triggers Touched without fighting the
-- floor's own collision.
local function overlayPad(name, position, size, color, tags, parent)
	return newPart({
		Name = name,
		Size = size or Vector3.new(10, 0.2, 10),
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = tags,
		Parent = parent,
	})
end

local function buildHub(root)
	newPart({
		Name = "GroundFloor",
		Size = Vector3.new(300, 2, 300),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(110, 190, 110),
		Material = Enum.Material.Grass,
		Parent = root,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(200, 200, 200)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = root

	overlayPad("SunSpot1", Vector3.new(20, 0.1, 20), Vector3.new(12, 0.2, 12), Color3.fromRGB(255, 225, 110), { "SunSpot" }, root)
	overlayPad("SunSpot2", Vector3.new(-20, 0.1, 20), Vector3.new(12, 0.2, 12), Color3.fromRGB(255, 225, 110), { "SunSpot" }, root)

	local kiosk = newPart({
		Name = "ShopKiosk",
		Size = Vector3.new(6, 6, 6),
		Position = Vector3.new(15, 3, 0),
		Color = Color3.fromRGB(200, 140, 60),
		Material = Enum.Material.Wood,
		Parent = root,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open Shop"
	prompt.ObjectText = "Lizard Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = kiosk
end

local function buildSprintTrack(root)
	overlayPad("SprintStartPad", Vector3.new(30, 0.1, 40), nil, Color3.fromRGB(90, 170, 255), { "SprintStart" }, root)
	overlayPad("SprintFinishPad", Vector3.new(130, 0.1, 40), nil, Color3.fromRGB(90, 255, 140), { "SprintFinish" }, root)

	-- A wandering predator: bump into it and you'll drop your tail (see
	-- AbilityService.triggerTailDrop), then have to keep running without it.
	overlayPad("SprintPredator", Vector3.new(80, 0.1, 40), Vector3.new(6, 0.2, 6), Color3.fromRGB(200, 40, 40), { "Predator" }, root)

	overlayPad("SprintSunSpot", Vector3.new(105, 0.1, 40), Vector3.new(10, 0.2, 10), Color3.fromRGB(255, 225, 110), { "SunSpot" }, root)
end

local function buildClimbTower(root)
	local wallPosition = Vector3.new(-80, 30, -60)
	newPart({
		Name = "ClimbWall",
		Size = Vector3.new(20, 60, 2),
		Position = wallPosition,
		Color = Color3.fromRGB(140, 120, 100),
		Material = Enum.Material.Rock,
		Tags = { "Climbable" },
		Parent = root,
	})

	overlayPad("ClimbStartPad", Vector3.new(-80, 0.1, -50), nil, Color3.fromRGB(90, 170, 255), { "ClimbStart" }, root)

	newPart({
		Name = "ClimbFinishPlatform",
		Size = Vector3.new(12, 1, 12),
		Position = Vector3.new(-80, 60.5, -60),
		Color = Color3.fromRGB(90, 255, 140),
		Material = Enum.Material.Neon,
		Tags = { "ClimbFinish" },
		Parent = root,
	})
end

local function buildBugHuntArena(root)
	local center = Vector3.new(-110, 0, 70)
	local size = Vector3.new(50, 1, 50)

	newPart({
		Name = "BugHuntBounds",
		Size = size,
		Position = center + Vector3.new(0, 0.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Tags = { "BugHuntBounds" },
		Parent = root,
	})

	local wallHeight = 6
	local wallThickness = 1
	local half = size / 2
	local walls = {
		{ Vector3.new(center.X, wallHeight / 2, center.Z - half.Z), Vector3.new(size.X, wallHeight, wallThickness) },
		{ Vector3.new(center.X, wallHeight / 2, center.Z + half.Z), Vector3.new(size.X, wallHeight, wallThickness) },
		{ Vector3.new(center.X - half.X, wallHeight / 2, center.Z), Vector3.new(wallThickness, wallHeight, size.Z) },
		{ Vector3.new(center.X + half.X, wallHeight / 2, center.Z), Vector3.new(wallThickness, wallHeight, size.Z) },
	}
	for i, wall in ipairs(walls) do
		newPart({
			Name = "BugHuntWall" .. i,
			Position = wall[1],
			Size = wall[2],
			Color = Color3.fromRGB(90, 130, 90),
			Material = Enum.Material.SmoothPlastic,
			Parent = root,
		})
	end

	overlayPad("BugHuntStartPad", center + Vector3.new(0, 0.1, half.Z - 3), Vector3.new(10, 0.2, 10), Color3.fromRGB(255, 170, 60), { "BugHuntStart" }, root)
end

function MapBuilder.Build()
	if workspace:FindFirstChild("LizardSportsMap") then
		return -- already built (e.g. Studio Play Solo re-running server scripts)
	end

	local root = Instance.new("Folder")
	root.Name = "LizardSportsMap"
	root.Parent = workspace

	buildHub(root)
	buildSprintTrack(root)
	buildClimbTower(root)
	buildBugHuntArena(root)
end

return MapBuilder
