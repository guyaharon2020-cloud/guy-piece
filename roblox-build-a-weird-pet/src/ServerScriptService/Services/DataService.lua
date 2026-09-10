-- DataService.lua
-- Owns loading, caching, autosaving and saving player profiles.
--
-- NOTE: this uses a single UpdateAsync call per save/load with basic retry.
-- That's enough for a prototype / small game. For a shipped game with real
-- concurrency risk (players rejoining across servers quickly), swap this out
-- for a proper session-locking library like ProfileService/ProfileStore --
-- every other service only talks to the small API below, so the swap is
-- isolated to this one file.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataService = {}

local STORE_NAME = "BuildAWeirdPet_Profiles_v1"
local AUTOSAVE_INTERVAL = 120 -- seconds
local MAX_RETRIES = 5

local store = DataStoreService:GetDataStore(STORE_NAME)

local profiles = {} -- [userId] = profile
local loadedSignal = Instance.new("BindableEvent")

local function deepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

DataService.DEFAULT_PROFILE = {
	Coins = 100,
	DNA = 25,
	Mutations = 0,
	Inventory = {}, -- { [petId] = petRecord }
	EquippedPetIds = {},
	DiscoveredCombinations = {}, -- [comboId] = true
	DiscoveredCount = 0,
	MilestonesClaimed = {}, -- [milestoneNumber] = true
	Upgrades = {
		PartGenerator = 1,
		Storage = 1,
		Luck = 1,
		PetSlots = 1,
		DNAMultiplier = 1,
		CoinMultiplier = 1,
	},
	WorldsUnlocked = { Backyard = true },
	CurrentWorld = "Backyard",
	ShopItemsOwned = {},
	EquippedCosmetics = {},
	PendingParts = nil,
	NextPetId = 1,
}

-- Fills in any keys added to DEFAULT_PROFILE since this profile was last saved.
local function reconcile(profile)
	for key, defaultValue in pairs(DataService.DEFAULT_PROFILE) do
		if profile[key] == nil then
			profile[key] = deepCopy(defaultValue)
		end
	end
	return profile
end

local function attempt(fn)
	local lastError
	for i = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(2 ^ i * 0.1) -- 0.2s, 0.4s, 0.8s, 1.6s, 3.2s
	end
	return false, lastError
end

local function keyFor(userId)
	return "Player_" .. userId
end

-- Loads (or creates) a profile for the player and caches it in memory.
-- Safe to call multiple times; subsequent calls are no-ops while cached.
function DataService.Load(player)
	if profiles[player.UserId] then
		return profiles[player.UserId]
	end

	local key = keyFor(player.UserId)
	local ok, result = attempt(function()
		local data = store:GetAsync(key)
		return data
	end)

	local profile
	if ok and result then
		profile = reconcile(result)
	else
		if not ok then
			warn(("DataService: failed to load %s after retries: %s"):format(player.Name, tostring(result)))
		end
		profile = deepCopy(DataService.DEFAULT_PROFILE)
	end

	profiles[player.UserId] = profile
	loadedSignal:Fire(player.UserId)
	return profile
end

-- Returns the cached profile, or nil if it hasn't loaded yet.
function DataService.Get(player)
	return profiles[player.UserId]
end

-- Yields until the profile is loaded (handles the rare case a script asks
-- for data before PlayerAdded's Load call has finished).
function DataService.WaitFor(player)
	if profiles[player.UserId] then
		return profiles[player.UserId]
	end
	while not profiles[player.UserId] and player.Parent do
		loadedSignal.Event:Wait()
	end
	return profiles[player.UserId]
end

function DataService.Save(player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	local key = keyFor(player.UserId)
	local snapshot = deepCopy(profile)
	local ok, err = attempt(function()
		store:SetAsync(key, snapshot)
	end)
	if not ok then
		warn(("DataService: failed to save %s after retries: %s"):format(player.Name, tostring(err)))
	end
	return ok
end

function DataService.Release(player)
	DataService.Save(player)
	profiles[player.UserId] = nil
end

-- Autosave loop for all currently-loaded profiles.
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			if profiles[player.UserId] then
				DataService.Save(player)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if profiles[player.UserId] then
			DataService.Save(player)
		end
	end
end)

return DataService
