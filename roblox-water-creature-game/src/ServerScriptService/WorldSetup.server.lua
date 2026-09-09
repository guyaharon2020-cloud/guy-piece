-- Fills the workspace Terrain with a big water volume (plus a sandy floor)
-- and tunes Lighting/water visuals for a nicer ocean look, the first time
-- the server starts. Safe to re-run: it skips itself once already generated.

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

	-- Nicer water look than the flat default.
	terrain.WaterColor = Color3.fromRGB(15, 80, 120)
	terrain.WaterTransparency = 0.6
	terrain.WaterReflectance = 0.15
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
