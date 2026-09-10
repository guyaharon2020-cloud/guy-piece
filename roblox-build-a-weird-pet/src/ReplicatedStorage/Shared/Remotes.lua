-- Remotes.lua
-- Single source of truth for every RemoteEvent/RemoteFunction the game uses.
-- Require this from both server and client; it lazily creates the Instances
-- under ReplicatedStorage.Remotes the first time it's required (server first).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT_NAMES = {
	-- server -> client (push)
	"ProfileUpdated", -- (profileDelta) partial state sync after any change
	"PetDiscovered", -- (petRecord, isNewDiscovery, milestone?) client toast
	"SecretPetAnnouncement", -- (playerName, petName) server-wide broadcast
	"ChallengeResult", -- (challengeId, score, rewardCoins, rewardDNA)

	-- client -> server (fire-and-forget)
	"RequestPartRoll",
	"CreatePet",
	"EquipPet",
	"UnequipPet",
	"BuyUpgrade",
	"UnlockWorld",
	"BuyShopItem",
	"StartChallenge",
}

local FUNCTION_NAMES = {
	"GetInitialProfile", -- full profile snapshot on client boot
}

local Remotes = {}
Remotes.Event = {}
Remotes.Function = {}

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

for _, name in ipairs(EVENT_NAMES) do
	local instance = folder:FindFirstChild(name)
	if not instance then
		instance = Instance.new("RemoteEvent")
		instance.Name = name
		instance.Parent = folder
	end
	Remotes.Event[name] = instance
end

for _, name in ipairs(FUNCTION_NAMES) do
	local instance = folder:FindFirstChild(name)
	if not instance then
		instance = Instance.new("RemoteFunction")
		instance.Name = name
		instance.Parent = folder
	end
	Remotes.Function[name] = instance
end

return Remotes
