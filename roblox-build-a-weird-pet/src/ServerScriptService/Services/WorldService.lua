-- WorldService.lua
-- Handles traveling to / unlocking worlds. Worlds must be unlocked in
-- order (you can't skip to Volcano without unlocking Laboratory and Alien
-- Planet first) so the part power curve stays meaningful.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Worlds = require(Shared:WaitForChild("Worlds"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local WorldService = {}

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = {
		Coins = profile.Coins,
		WorldsUnlocked = profile.WorldsUnlocked,
		CurrentWorld = profile.CurrentWorld,
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

-- Selecting an already-unlocked world is free travel; selecting the next
-- locked world in sequence attempts to purchase it.
local function onUnlockWorld(player, worldId)
	local profile = DataService.Get(player)
	local world = Worlds.get(worldId)
	if not profile or not world then
		return
	end

	if profile.WorldsUnlocked[worldId] then
		profile.CurrentWorld = worldId
		pushProfile(player)
		return
	end

	local previous = Worlds.List[world.order - 1]
	if previous and not profile.WorldsUnlocked[previous.id] then
		pushProfile(player, { Error = "Unlock " .. previous.name .. " first" })
		return
	end

	if profile.Coins < world.unlockCost then
		pushProfile(player, { Error = "Not enough Coins to unlock " .. world.name })
		return
	end

	profile.Coins -= world.unlockCost
	profile.WorldsUnlocked[worldId] = true
	profile.CurrentWorld = worldId
	pushProfile(player)
end

function WorldService.init()
	Remotes.Event.UnlockWorld.OnServerEvent:Connect(onUnlockWorld)
end

return WorldService
