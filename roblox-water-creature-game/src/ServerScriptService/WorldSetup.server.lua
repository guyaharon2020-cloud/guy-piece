-- Fills the workspace Terrain with a big water volume (plus a sandy floor)
-- the first time the server starts, so the place works with no manual
-- Studio setup. Safe to re-run: it skips itself once already generated.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

if not Workspace:GetAttribute("WaterWorldGenerated") then
	local terrain = Workspace.Terrain

	terrain:FillBlock(CFrame.new(Config.WaterCenter), Config.WaterSize, Enum.Material.Water)

	local seabedCenter = Config.WaterCenter - Vector3.new(0, Config.WaterSize.Y / 2 + 5, 0)
	local seabedSize = Vector3.new(Config.WaterSize.X, 10, Config.WaterSize.Z)
	terrain:FillBlock(CFrame.new(seabedCenter), seabedSize, Enum.Material.Sand)

	Workspace:SetAttribute("WaterWorldGenerated", true)
end

Workspace.FallenPartsDestroyHeight = Config.WaterCenter.Y - Config.WaterSize.Y
