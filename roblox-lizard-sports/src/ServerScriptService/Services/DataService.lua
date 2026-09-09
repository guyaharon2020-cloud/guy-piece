-- Owns the DataStore-backed player profile: coins, owned shop items,
-- equipped skin and lifetime stats. Everything else (live ability state
-- like current stamina) stays in AbilityService and is never persisted.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ProfileStore = DataStoreService:GetDataStore("LizardSportsProfile_v1")

local DataService = {}

local profiles = {} -- [player] = profileTable
local DataUpdated

local DEFAULT_PROFILE = {
	Coins = 100,
	OwnedSkins = { classic_green = true },
	OwnedGear = {},
	EquippedSkin = "classic_green",
	Wins = 0,
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function fillMissing(profile, template)
	for key, value in pairs(template) do
		if profile[key] == nil then
			profile[key] = type(value) == "table" and deepCopy(value) or value
		elseif type(value) == "table" and type(profile[key]) == "table" then
			fillMissing(profile[key], value)
		end
	end
	return profile
end

local function loadProfile(player)
	local key = "Player_" .. player.UserId
	local data
	local ok, err = pcall(function()
		data = ProfileStore:GetAsync(key)
	end)

	if not ok then
		warn(("[DataService] Failed to load profile for %s: %s"):format(player.Name, tostring(err)))
	end

	if type(data) ~= "table" then
		data = deepCopy(DEFAULT_PROFILE)
	else
		data = fillMissing(data, DEFAULT_PROFILE)
	end

	profiles[player] = data
	return data
end

local function saveProfile(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		ProfileStore:SetAsync(key, profile)
	end)
	if not ok then
		warn(("[DataService] Failed to save profile for %s: %s"):format(player.Name, tostring(err)))
	end
end

function DataService.Init(remotes)
	DataUpdated = remotes.DataUpdated

	Players.PlayerAdded:Connect(function(player)
		loadProfile(player)
		DataService.Push(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveProfile(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			saveProfile(player)
		end
	end)

	-- Handles players who joined before this script ran (e.g. Studio Play Solo).
	for _, player in ipairs(Players:GetPlayers()) do
		if not profiles[player] then
			loadProfile(player)
		end
	end
end

function DataService.Get(player)
	return profiles[player]
end

function DataService.Save(player)
	saveProfile(player)
end

-- Broadcasts the player's current profile snapshot to their own client and
-- keeps the classic Roblox leaderboard (leaderstats) in sync.
function DataService.Push(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	if DataUpdated then
		DataUpdated:FireClient(player, profile)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = profile.Coins
		end
		local wins = leaderstats:FindFirstChild("Wins")
		if wins then
			wins.Value = profile.Wins
		end
	end
end

function DataService.AddCoins(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Coins = math.max(0, profile.Coins + amount)
	DataService.Push(player)
end

function DataService.AddWin(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Wins += 1
	DataService.Push(player)
end

return DataService
