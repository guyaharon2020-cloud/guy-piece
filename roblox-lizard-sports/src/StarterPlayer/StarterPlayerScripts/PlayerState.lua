-- Single client-side cache of the latest profile (coins/owned items/skin)
-- and live ability stats (stamina/tail/cooldowns), so every controller
-- reads the same data instead of each parsing remotes independently.

local PlayerState = {}

local profile = nil
local stats = nil
local profileListeners = {}

function PlayerState.Init(remotes)
	remotes:WaitForChild("DataUpdated").OnClientEvent:Connect(function(newProfile)
		profile = newProfile
		for _, callback in ipairs(profileListeners) do
			task.spawn(callback, profile)
		end
	end)

	remotes:WaitForChild("StatsUpdated").OnClientEvent:Connect(function(newStats)
		stats = newStats
	end)
end

function PlayerState.GetProfile()
	return profile
end

function PlayerState.GetStats()
	return stats
end

function PlayerState.OnProfileChanged(callback)
	table.insert(profileListeners, callback)
end

return PlayerState
