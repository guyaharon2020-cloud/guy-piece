-- Every player (re)spawns inside a glass cube high above the water — an
-- invisible, walkable floor (Transparency 1 + CanCollide true, so you can
-- stand on it and still see straight through it to the ocean below) with
-- translucent glass walls/ceiling and glowing corner pillars. A ring portal
-- in the middle of the cube prompts a species choice, then teleports you
-- down to the water surface as whichever creature you picked. Since this
-- is the only SpawnLocation in the place, every respawn starts here too.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerSpecies = require(ServerScriptService.Modules.PlayerSpecies)
local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local PromptSpeciesSelectEvent = Remotes:FindFirstChild("PromptSpeciesSelect")
if not PromptSpeciesSelectEvent then
	PromptSpeciesSelectEvent = Instance.new("RemoteEvent")
	PromptSpeciesSelectEvent.Name = "PromptSpeciesSelect"
	PromptSpeciesSelectEvent.Parent = Remotes
end

local SelectSpeciesEvent = Remotes:FindFirstChild("SelectSpecies")
if not SelectSpeciesEvent then
	SelectSpeciesEvent = Instance.new("RemoteEvent")
	SelectSpeciesEvent.Name = "SelectSpecies"
	SelectSpeciesEvent.Parent = Remotes
end

if Workspace:GetAttribute("SkySpawnGenerated") then
	return
end

local skyY = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + Config.SkySpawnHeight

local platform = Instance.new("SpawnLocation")
platform.Name = "SkySpawn"
platform.Size = Config.SkySpawnPlatformSize
platform.CFrame = CFrame.new(Config.WaterCenter.X, skyY, Config.WaterCenter.Z)
platform.Anchored = true
platform.CanCollide = true
platform.Transparency = 1
platform.Neutral = true
platform.Parent = Workspace

-- A thin glowing rim around the invisible platform's edges, so players can
-- see where the edge is even though the floor itself is see-through.
local half = platform.Size.X / 2
local barThickness, barHeight = 0.6, 0.4
local edgeOffsets = {
	{ Vector3.new(0, 0, half), Vector3.new(platform.Size.X, barHeight, barThickness) },
	{ Vector3.new(0, 0, -half), Vector3.new(platform.Size.X, barHeight, barThickness) },
	{ Vector3.new(half, 0, 0), Vector3.new(barThickness, barHeight, platform.Size.Z) },
	{ Vector3.new(-half, 0, 0), Vector3.new(barThickness, barHeight, platform.Size.Z) },
}
for _, edge in ipairs(edgeOffsets) do
	local offset, size = edge[1], edge[2]
	local bar = Instance.new("Part")
	bar.Name = "EdgeGlow"
	bar.Size = size
	bar.CFrame = platform.CFrame * CFrame.new(offset.X, platform.Size.Y / 2 + barHeight / 2, offset.Z)
	bar.Anchored = true
	bar.CanCollide = false
	bar.Material = Enum.Material.Neon
	bar.Color = Color3.fromRGB(150, 220, 255)
	bar.Parent = Workspace
end

--============================================================
-- The glass cube enclosing the spawn area
--============================================================

local cubeHalfWidth = platform.Size.X / 2 + 4
local cubeHeight = Config.SkySpawnCubeHeight
local wallThickness = 1

local function createWall(name, cframe, size)
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.CFrame = cframe
	wall.Anchored = true
	wall.CanCollide = true
	wall.Material = Enum.Material.Glass
	wall.Color = Color3.fromRGB(150, 210, 255)
	wall.Transparency = 0.8
	wall.Parent = Workspace
	return wall
end

local cubeCenterY = skyY + cubeHeight / 2
createWall("SkyCubeWallNorth",
	CFrame.new(Config.WaterCenter.X, cubeCenterY, Config.WaterCenter.Z + cubeHalfWidth),
	Vector3.new(cubeHalfWidth * 2, cubeHeight, wallThickness))
createWall("SkyCubeWallSouth",
	CFrame.new(Config.WaterCenter.X, cubeCenterY, Config.WaterCenter.Z - cubeHalfWidth),
	Vector3.new(cubeHalfWidth * 2, cubeHeight, wallThickness))
createWall("SkyCubeWallEast",
	CFrame.new(Config.WaterCenter.X + cubeHalfWidth, cubeCenterY, Config.WaterCenter.Z),
	Vector3.new(wallThickness, cubeHeight, cubeHalfWidth * 2))
createWall("SkyCubeWallWest",
	CFrame.new(Config.WaterCenter.X - cubeHalfWidth, cubeCenterY, Config.WaterCenter.Z),
	Vector3.new(wallThickness, cubeHeight, cubeHalfWidth * 2))
createWall("SkyCubeCeiling",
	CFrame.new(Config.WaterCenter.X, skyY + cubeHeight, Config.WaterCenter.Z),
	Vector3.new(cubeHalfWidth * 2, wallThickness, cubeHalfWidth * 2))

-- Glowing corner pillars: a Cylinder's default thin axis is local X, so
-- rotating 90° about Z (sending local X to world Y) stands it upright —
-- same trick as the ship masts / coral trunks.
local function createCornerPillar(x, z)
	local pillar = Instance.new("Part")
	pillar.Name = "SkyCubePillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(cubeHeight, 1.2, 1.2)
	pillar.CFrame = CFrame.new(x, cubeCenterY, z) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.Material = Enum.Material.Neon
	pillar.Color = Color3.fromRGB(120, 200, 255)
	pillar.Parent = Workspace
end
for _, x in ipairs({ Config.WaterCenter.X + cubeHalfWidth, Config.WaterCenter.X - cubeHalfWidth }) do
	for _, z in ipairs({ Config.WaterCenter.Z + cubeHalfWidth, Config.WaterCenter.Z - cubeHalfWidth }) do
		createCornerPillar(x, z)
	end
end

--============================================================
-- The portal: a double ring around a glowing disc, facing the platform
-- (i.e. its normal points along Z, back toward spawn center) so it reads
-- face-on to a player walking up to it — not edge-on.
--============================================================

local portalRadius = Config.SkySpawnPortalRadius
local portalCenter = CFrame.new(
	Config.WaterCenter.X,
	skyY + portalRadius + 2,
	Config.WaterCenter.Z + Config.SkySpawnPortalOffset
)

local portalModel = Instance.new("Model")
portalModel.Name = "Portal"

-- Outer frame ring: segments placed via a Z-axis "roll" rotation then
-- translated along the now-rotated local Y — the same technique as the
-- giant fan corals — which traces a circle in portalCenter's X-Y plane
-- (normal along Z, matching the direction a player approaches from).
local outerSegments = 16
for i = 1, outerSegments do
	local angle = (i - 1) / outerSegments * math.pi * 2
	local seg = Instance.new("Part")
	seg.Name = "PortalFrame"
	seg.Size = Vector3.new(1.6, 2.2, 1)
	seg.Color = Color3.fromRGB(35, 40, 50)
	seg.Material = Enum.Material.Metal
	seg.Anchored = true
	seg.CanCollide = false
	seg.CFrame = portalCenter * CFrame.Angles(0, 0, angle) * CFrame.new(0, portalRadius + 0.9, 0)
	seg.Parent = portalModel
end

-- Inner glow ring — same placement technique, smaller radius, brighter.
-- Kept in its own table so it can be spun for a swirling-portal effect.
local innerRingParts = {}
local innerSegments = 20
for i = 1, innerSegments do
	local seg = Instance.new("Part")
	seg.Name = "PortalGlow"
	seg.Size = Vector3.new(1, 1.3, 0.4)
	seg.Color = Color3.fromRGB(90, 190, 255)
	seg.Material = Enum.Material.Neon
	seg.Anchored = true
	seg.CanCollide = false
	seg.Parent = portalModel
	table.insert(innerRingParts, seg)
end

-- The glowing center disc. A Cylinder's thin axis defaults to local X, so
-- (unlike the ring above, which is naturally correct) it needs an explicit
-- 90°-about-Y rotation to send that thin axis to world Z — otherwise the
-- disc would stand edge-on to an approaching player instead of face-on.
local disc = Instance.new("Part")
disc.Name = "PortalDisc"
disc.Shape = Enum.PartType.Cylinder
disc.Size = Vector3.new(0.4, portalRadius * 1.8, portalRadius * 1.8)
disc.Color = Color3.fromRGB(80, 180, 255)
disc.Material = Enum.Material.Neon
disc.Transparency = 0.35
disc.Anchored = true
disc.CanCollide = false
disc.CFrame = portalCenter * CFrame.Angles(0, math.rad(90), 0)
disc.Parent = portalModel

local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(120, 200, 255)
light.Range = 28
light.Brightness = 2.5
light.Parent = disc

-- The touch trigger — same orientation fix as the disc, invisible, sized
-- to roughly cover the ring so it's easy to walk into.
local trigger = Instance.new("Part")
trigger.Name = "PortalTrigger"
trigger.Shape = Enum.PartType.Cylinder
trigger.Size = Vector3.new(3, portalRadius * 2, portalRadius * 2)
trigger.Transparency = 1
trigger.Anchored = true
trigger.CanCollide = false
trigger.CFrame = portalCenter * CFrame.Angles(0, math.rad(90), 0)
trigger.Parent = portalModel

portalModel.Parent = Workspace

-- Slowly spins the inner ring around the portal's own facing axis (Z) for
-- a swirling effect. Updated a few times a second rather than every frame
-- — it's purely cosmetic, no need for 60Hz replication.
task.spawn(function()
	local rotation = 0
	while portalModel.Parent do
		rotation += math.rad(4)
		for i, seg in ipairs(innerRingParts) do
			local placementAngle = (i - 1) / innerSegments * math.pi * 2
			seg.CFrame = portalCenter * CFrame.Angles(0, 0, placementAngle + rotation) * CFrame.new(0, portalRadius, 0)
		end
		task.wait(0.1)
	end
end)

--============================================================
-- Species choice + teleport
--============================================================

local dropPoint = Vector3.new(
	Config.WaterCenter.X,
	Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 6,
	Config.WaterCenter.Z
)

local lastPromptAt = {}

trigger.Touched:Connect(function(otherPart)
	local character = otherPart.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local now = os.clock()
	if lastPromptAt[player] and now - lastPromptAt[player] < 2 then
		return
	end
	lastPromptAt[player] = now

	PromptSpeciesSelectEvent:FireClient(player)
end)

SelectSpeciesEvent.OnServerEvent:Connect(function(player, speciesKey)
	if typeof(speciesKey) ~= "string" then
		return
	end

	local success = PlayerSpecies.Select(player, speciesKey)
	if not success then
		return
	end

	PlayerProgress.ApplyLevelStats(player) -- rebuilds the fish body for the new species

	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(dropPoint))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastPromptAt[player] = nil
end)

Workspace:SetAttribute("SkySpawnGenerated", true)
