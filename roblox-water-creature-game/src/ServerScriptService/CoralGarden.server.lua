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

coralsFolder.Parent = Workspace
Workspace:SetAttribute("CoralsGenerated", true)
