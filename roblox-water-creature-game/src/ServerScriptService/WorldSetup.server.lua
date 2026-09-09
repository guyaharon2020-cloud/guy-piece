-- Fills the workspace Terrain with a big water volume (plus a sandy floor
-- and a sand barrier ring around the edge) and tunes Lighting/water visuals
-- for a nicer ocean look, the first time the server starts. Safe to re-run:
-- the Terrain/Lighting part skips itself once already generated.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

if not Workspace:GetAttribute("WaterWorldGenerated") then
	local terrain = Workspace.Terrain

	terrain:FillBlock(CFrame.new(Config.WaterCenter), Config.WaterSize, Enum.Material.Water)

	local seabedCenter = Config.WaterCenter - Vector3.new(0, Config.WaterSize.Y / 2 + 5, 0)
	local seabedSize = Vector3.new(Config.WaterSize.X, 10, Config.WaterSize.Z)
	terrain:FillBlock(CFrame.new(seabedCenter), seabedSize, Enum.Material.Sand)

	-- A sand barrier ring, built from 4 slabs sitting entirely OUTSIDE the
	-- water block's footprint (never overlapping it), so it can never
	-- overwrite the water. Each slab spans the full outer width on one axis
	-- so the 4 slabs overlap at the corners and leave no gaps.
	local halfX = Config.WaterSize.X / 2
	local halfZ = Config.WaterSize.Z / 2
	local outerX = halfX + Config.BarrierThickness
	local outerZ = halfZ + Config.BarrierThickness
	local wallY = Config.WaterCenter.Y

	local function fillWall(x, z, sizeX, sizeZ)
		terrain:FillBlock(
			CFrame.new(Config.WaterCenter.X + x, wallY, Config.WaterCenter.Z + z),
			Vector3.new(sizeX, Config.BarrierHeight, sizeZ),
			Enum.Material.Sand
		)
	end

	fillWall(0, halfZ + Config.BarrierThickness / 2, outerX * 2, Config.BarrierThickness) -- north
	fillWall(0, -(halfZ + Config.BarrierThickness / 2), outerX * 2, Config.BarrierThickness) -- south
	fillWall(halfX + Config.BarrierThickness / 2, 0, Config.BarrierThickness, outerZ * 2) -- east
	fillWall(-(halfX + Config.BarrierThickness / 2), 0, Config.BarrierThickness, outerZ * 2) -- west

	-- Nicer water look than the flat default.
	terrain.WaterColor = Color3.fromRGB(10, 135, 150)
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.2
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 8

	-- Ocean-daylight lighting + a soft haze so distant rafts/ships fade in.
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(60, 90, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 150, 170)
	Lighting.FogColor = Color3.fromRGB(40, 90, 120)
	Lighting.FogStart = 150
	Lighting.FogEnd = 700

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(180, 210, 230)
	atmosphere.Decay = Color3.fromRGB(100, 140, 170)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	Workspace:SetAttribute("WaterWorldGenerated", true)
end

Workspace.FallenPartsDestroyHeight = Config.WaterCenter.Y - Config.WaterSize.Y
