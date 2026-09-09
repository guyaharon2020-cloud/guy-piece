-- Bootstraps player progress (leaderstats) on join and re-applies level-based
-- stats whenever a player's character respawns.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)

local function onPlayerAdded(player)
	PlayerProgress.Init(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5) -- let the Humanoid finish rigging before we touch it
		PlayerProgress.ApplyLevelStats(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
