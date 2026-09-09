-- "Climb Tower": scale the gecko wall from the base pad to the top pad
-- using the wall-climb ability (see AbilityService). Same start/finish
-- timing pattern as SprintDashEvent, tuned for a slower, vertical course.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.Parent.DataService)

local WIN_TIME_SECONDS = 20
local BASE_REWARD = 250
local REWARD_PER_SECOND_PENALTY = 4
local MIN_REWARD = 30

local ClimbTowerEvent = {}

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
			Remotes.EventStatus:FireClient(player, { event = "ClimbTower", state = "Running" })
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
				event = "ClimbTower",
				state = "Finished",
				time = elapsed,
				reward = reward,
			})
		end
	end)
end

function ClimbTowerEvent.Init(remotes)
	Remotes = remotes

	for _, part in ipairs(CollectionService:GetTagged("ClimbStart")) do
		bindStart(part)
	end
	CollectionService:GetInstanceAddedSignal("ClimbStart"):Connect(bindStart)

	for _, part in ipairs(CollectionService:GetTagged("ClimbFinish")) do
		bindFinish(part)
	end
	CollectionService:GetInstanceAddedSignal("ClimbFinish"):Connect(bindFinish)

	Players.PlayerRemoving:Connect(function(player)
		activeRuns[player] = nil
	end)
end

return ClimbTowerEvent
