-- Every player (re)spawns on an invisible, walkable platform high above the
-- water — Transparency 1 + CanCollide true means you can stand on it and
-- still see straight through it to the ocean below. A glowing portal on the
-- platform teleports whoever touches it down to the water surface. Since
-- this is the only SpawnLocation in the place, every respawn starts here
-- too, so dying sends you back through the portal flow.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

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

-- The portal: a glowing vertical disc a short walk from the platform
-- center. A Cylinder part's flat round face already stands vertical with
-- no extra rotation needed (its thin axis is local X).
local portal = Instance.new("Part")
portal.Name = "Portal"
portal.Shape = Enum.PartType.Cylinder
portal.Size = Vector3.new(1, 14, 14)
portal.Anchored = true
portal.CanCollide = false
portal.Material = Enum.Material.Neon
portal.Color = Color3.fromRGB(80, 180, 255)
portal.Transparency = 0.25
portal.CFrame = CFrame.new(Config.WaterCenter.X, skyY + 7, Config.WaterCenter.Z + Config.SkySpawnPortalOffset)
portal.Parent = Workspace

local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(120, 200, 255)
light.Range = 24
light.Brightness = 2
light.Parent = portal

local dropPoint = Vector3.new(
	Config.WaterCenter.X,
	Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 6,
	Config.WaterCenter.Z
)

local lastTeleportAt = {}

portal.Touched:Connect(function(otherPart)
	local character = otherPart.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local now = os.clock()
	if lastTeleportAt[player] and now - lastTeleportAt[player] < 2 then
		return
	end
	lastTeleportAt[player] = now

	character:PivotTo(CFrame.new(dropPoint))
end)

Players.PlayerRemoving:Connect(function(player)
	lastTeleportAt[player] = nil
end)

Workspace:SetAttribute("SkySpawnGenerated", true)
