-- Bootstraps player progress, upgrades, and the Robux consumables folder on
-- join, and re-applies level stats + fish appearance whenever a player's
-- character respawns.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)
local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)
local RobuxShop = require(ServerScriptService.Modules.RobuxShop)
local CreatureAppearance = require(ServerScriptService.Modules.CreatureAppearance)

local function onPlayerAdded(player)
	PlayerProgress.Init(player)
	PlayerUpgrades.Init(player)
	RobuxShop.Init(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5) -- let the Humanoid finish rigging before we touch it
		PlayerProgress.ApplyLevelStats(player)
		CreatureAppearance.Apply(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
