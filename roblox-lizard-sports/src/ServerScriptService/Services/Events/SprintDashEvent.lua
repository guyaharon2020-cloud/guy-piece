-- "Sprint Dash": a timed run from start pad to finish pad. Rewards scale
-- with speed; a fast enough time counts as a win on the leaderboard.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.Parent.DataService)

local WIN_TIME_SECONDS = 12
local BASE_REWARD = 200
local REWARD_PER_SECOND_PENALTY = 5
local MIN_REWARD = 20

local SprintDashEvent = {}

local Remotes
local activeRuns = {} -- [player] = startClock

local function bindStart(part)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or activeRuns[player] then
			return
		end
		activeRuns[player] = os.clock()
		if Remotes then
			Remotes.EventStatus:FireClient(player, { event = "SprintDash", state = "Running" })
		end
	end)
end

local function bindFinish(part)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local startClock = activeRuns[player]
		if not startClock then
			return
		end
		activeRuns[player] = nil

		local elapsed = os.clock() - startClock
		local reward = math.clamp(math.floor(BASE_REWARD - elapsed * REWARD_PER_SECOND_PENALTY), MIN_REWARD, BASE_REWARD)
		DataService.AddCoins(player, reward)
		if elapsed <= WIN_TIME_SECONDS then
			DataService.AddWin(player)
		end

		if Remotes then
			Remotes.EventStatus:FireClient(player, {
				event = "SprintDash",
				state = "Finished",
				time = elapsed,
				reward = reward,
			})
		end
	end)
end

function SprintDashEvent.Init(remotes)
	Remotes = remotes

	for _, part in ipairs(CollectionService:GetTagged("SprintStart")) do
		bindStart(part)
	end
	CollectionService:GetInstanceAddedSignal("SprintStart"):Connect(bindStart)

	for _, part in ipairs(CollectionService:GetTagged("SprintFinish")) do
		bindFinish(part)
	end
	CollectionService:GetInstanceAddedSignal("SprintFinish"):Connect(bindFinish)

	Players.PlayerRemoving:Connect(function(player)
		activeRuns[player] = nil
	end)
end

return SprintDashEvent
