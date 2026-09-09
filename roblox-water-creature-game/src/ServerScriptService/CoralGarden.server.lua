-- Scatters decorative coral clusters across the seabed, once, on first
-- server start. Purely visual: every part is non-collidable so it never
-- blocks swimming. Built entirely from primitive Parts/SpecialMesh — no
-- asset upload needed.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

if Workspace:GetAttribute("CoralsGenerated") then
	return
end

local CORAL_COLORS = {
	Color3.fromRGB(255, 111, 145),
	Color3.fromRGB(255, 159, 67),
	Color3.fromRGB(162, 95, 220),
	Color3.fromRGB(255, 206, 84),
	Color3.fromRGB(72, 219, 199),
}

local function randomCoralColor()
	return CORAL_COLORS[math.random(1, #CORAL_COLORS)]
end

local function createBranchCoral(position)
	local model = Instance.new("Model")
	model.Name = "Coral"

	local color = randomCoralColor()
	local branchCount = math.random(3, 5)
	local primaryBranch

	for _ = 1, branchCount do
		local branch = Instance.new("Part")
		branch.Name = "Branch"
		branch.Size = Vector3.new(0.8, math.random(30, 55) / 10, 0.8)
		branch.Color = color
		branch.Material = Enum.Material.Slate
		branch.Anchored = true
		branch.CanCollide = false
		branch.CanQuery = false

		local tilt = math.rad(math.random(-25, 25))
		local spin = math.rad(math.random(0, 360))
		local horizontalOffset = Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
		branch.CFrame = CFrame.new(position + horizontalOffset) * CFrame.Angles(tilt, spin, 0) * CFrame.new(0, branch.Size.Y / 2, 0)
		branch.Parent = model

		-- Tapers the branch into a spike. Guarded because MeshType.Pyramid is
		-- an easy enum name to get wrong — if it is, the branch just stays a
		-- plain block instead of breaking coral generation entirely.
		local mesh = Instance.new("SpecialMesh")
		local ok = pcall(function()
			mesh.MeshType = Enum.MeshType.Pyramid
		end)
		if ok then
			mesh.Parent = branch
		else
			mesh:Destroy()
		end

		primaryBranch = primaryBranch or branch
	end

	model.PrimaryPart = primaryBranch
	return model
end

local function createBrainCoral(position)
	local part = Instance.new("Part")
	part.Name = "BrainCoral"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(math.random(20, 40) / 10, math.random(14, 22) / 10, math.random(20, 40) / 10)
	part.Color = randomCoralColor()
	part.Material = Enum.Material.Slate
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = CFrame.new(position + Vector3.new(0, part.Size.Y / 2, 0))
	return part
end

local function createSeaRod(position)
	local part = Instance.new("Part")
	part.Name = "SeaRod"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(math.random(25, 45) / 10, 0.35, 0.35)
	part.Color = randomCoralColor()
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = CFrame.new(position + Vector3.new(0, part.Size.X / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return part
end

-- A tall stacked "trunk" coral tower with a spiky crown on top. Each trunk
-- segment is a Cylinder rotated 90° about Z (the same trusted rotation
-- ShipSpawner uses for masts) so it stands upright instead of lying flat.
local function createGiantCoralTower(position)
	local model = Instance.new("Model")
	model.Name = "GiantCoral"

	local color = randomCoralColor()
	local segments = math.random(4, 6)
	local baseRadius = math.random(25, 40) / 10
	local currentY = position.Y
	local primary

	for i = 1, segments do
		local segHeight = math.random(35, 55) / 10
		local segRadius = baseRadius * (1 - (i - 1) / segments * 0.5)

		local segment = Instance.new("Part")
		segment.Name = "Trunk"
		segment.Shape = Enum.PartType.Cylinder
		segment.Size = Vector3.new(segHeight, segRadius * 2, segRadius * 2)
		segment.Color = color
		segment.Material = Enum.Material.Slate
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanQuery = false
		segment.CFrame = CFrame.new(position.X, currentY + segHeight / 2, position.Z) * CFrame.Angles(0, 0, math.rad(90))
		segment.Parent = model

		currentY += segHeight
		primary = primary or segment
	end

	for _ = 1, math.random(4, 7) do
		local branch = Instance.new("Part")
		branch.Name = "CrownBranch"
		branch.Size = Vector3.new(0.8, math.random(25, 45) / 10, 0.8)
		branch.Color = color
		branch.Material = Enum.Material.Slate
		branch.Anchored = true
		branch.CanCollide = false
		branch.CanQuery = false

		local tilt = math.rad(math.random(-30, 30))
		local spin = math.rad(math.random(0, 360))
		local horizontalOffset = Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
		branch.CFrame = CFrame.new(Vector3.new(position.X, currentY, position.Z) + horizontalOffset)
			* CFrame.Angles(tilt, spin, 0) * CFrame.new(0, branch.Size.Y / 2, 0)
		branch.Parent = model
	end

	model.PrimaryPart = primary
	return model
end

-- A big flat "hand fan" of thin translucent blades radiating from a shared
-- base point. Each blade is only rolled (rotated about local Z) then moved
-- along its OWN now-tilted local Y — standard CFrame composition, so each
-- blade ends up offset outward at its own angle from the same base, exactly
-- like a real fan.
local function createGiantFanCoral(position)
	local model = Instance.new("Model")
	model.Name = "GiantCoral"

	local color = randomCoralColor()
	local bladeCount = math.random(7, 11)
	local fanRadius = math.random(45, 70) / 10
	local primary

	for i = 1, bladeCount do
		local t = (i - 1) / (bladeCount - 1)
		local angle = math.rad(-60 + t * 120)

		local blade = Instance.new("Part")
		blade.Name = "FanBlade"
		blade.Size = Vector3.new(0.15, fanRadius, fanRadius * 0.35)
		blade.Color = color
		blade.Material = Enum.Material.Glass
		blade.Transparency = 0.35
		blade.Anchored = true
		blade.CanCollide = false
		blade.CanQuery = false
		blade.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, angle) * CFrame.new(0, fanRadius / 2, 0)
		blade.Parent = model

		primary = primary or blade
	end

	model.PrimaryPart = primary
	return model
end

-- A giant clam: two large domed "shells" opened at an angle around a
-- glowing pearl. Uses only Ball shapes, so there's no orientation ambiguity
-- to get wrong.
local function createGiantClam(position)
	local model = Instance.new("Model")
	model.Name = "GiantCoral"

	local shellColor = Color3.fromRGB(235, 225, 245)
	local shellSize = Vector3.new(math.random(60, 90) / 10, math.random(30, 45) / 10, math.random(50, 75) / 10)

	local bottomShell = Instance.new("Part")
	bottomShell.Name = "ClamBottom"
	bottomShell.Shape = Enum.PartType.Ball
	bottomShell.Size = shellSize
	bottomShell.Color = shellColor
	bottomShell.Material = Enum.Material.Marble
	bottomShell.Anchored = true
	bottomShell.CanCollide = false
	bottomShell.CanQuery = false
	bottomShell.CFrame = CFrame.new(position + Vector3.new(0, shellSize.Y * 0.25, 0))
	bottomShell.Parent = model

	local topShell = Instance.new("Part")
	topShell.Name = "ClamTop"
	topShell.Shape = Enum.PartType.Ball
	topShell.Size = shellSize
	topShell.Color = shellColor
	topShell.Material = Enum.Material.Marble
	topShell.Anchored = true
	topShell.CanCollide = false
	topShell.CanQuery = false
	topShell.CFrame = CFrame.new(position + Vector3.new(0, shellSize.Y * 0.6, 0))
		* CFrame.Angles(math.rad(35), 0, 0)
		* CFrame.new(0, -shellSize.Y * 0.15, shellSize.Z * 0.3)
	topShell.Parent = model

	local pearl = Instance.new("Part")
	pearl.Name = "Pearl"
	pearl.Shape = Enum.PartType.Ball
	pearl.Size = Vector3.new(1.2, 1.2, 1.2)
	pearl.Color = Color3.fromRGB(255, 250, 230)
	pearl.Material = Enum.Material.Neon
	pearl.Anchored = true
	pearl.CanCollide = false
	pearl.CanQuery = false
	pearl.CFrame = CFrame.new(position + Vector3.new(0, shellSize.Y * 0.35, 0))
	pearl.Parent = model

	model.PrimaryPart = bottomShell
	return model
end

local coralsFolder = Instance.new("Folder")
coralsFolder.Name = "Corals"

for _ = 1, Config.CoralCount do
	local angle = math.random() * math.pi * 2
	local distance = math.random(0, Config.SpawnRadius)
	local position = Vector3.new(
		Config.WaterCenter.X + math.cos(angle) * distance,
		Config.SeabedY,
		Config.WaterCenter.Z + math.sin(angle) * distance
	)

	local roll = math.random()
	local piece
	if roll < 0.55 then
		piece = createBranchCoral(position)
	elseif roll < 0.8 then
		piece = createBrainCoral(position)
	else
		piece = createSeaRod(position)
	end

	piece.Parent = coralsFolder
end

-- Big centerpiece formations, scattered in among the regular corals. Each
-- one is wrapped individually so a mistake in one giant piece never stops
-- the rest (regular corals included, since this comes after them) from
-- placing.
for _ = 1, Config.GiantCoralCount do
	local ok, err = pcall(function()
		local angle = math.random() * math.pi * 2
		local distance = math.random(0, Config.SpawnRadius)
		local position = Vector3.new(
			Config.WaterCenter.X + math.cos(angle) * distance,
			Config.SeabedY,
			Config.WaterCenter.Z + math.sin(angle) * distance
		)

		local roll = math.random()
		local piece
		if roll < 0.4 then
			piece = createGiantCoralTower(position)
		elseif roll < 0.75 then
			piece = createGiantFanCoral(position)
		else
			piece = createGiantClam(position)
		end

		piece.Parent = coralsFolder
	end)
	if not ok then
		warn("CoralGarden: a giant coral piece failed and was skipped — " .. tostring(err))
	end
end

coralsFolder.Parent = Workspace
Workspace:SetAttribute("CoralsGenerated", true)
