-- CollectionService.lua
-- Tracks which part-combinations a player has discovered (the Collection
-- Book), grants milestone rewards, and handles secret-pet detection +
-- server-wide announcements.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local CollectionService = {}

local MILESTONES = { 10, 25, 50, 100 }

local function milestoneReward(milestone)
	-- Scales up steeply -- these are meant to feel like real celebrations.
	return milestone * 50, milestone * 5 -- coins, DNA
end

local SECRET_COIN_REWARD = 5000
local SECRET_DNA_REWARD = 500

-- Called right after a pet is created. Updates the Collection Book, fires
-- discovery/milestone/secret events, and grants the associated rewards.
function CollectionService.RegisterDiscovery(player, petRecord)
	local profile = DataService.Get(player)
	if not profile then
		return
	end

	local comboId = petRecord.comboId
	local isNewDiscovery = not profile.DiscoveredCombinations[comboId]
	local milestoneHit = nil

	if isNewDiscovery then
		-- Store the name (not just `true`) so the Collection Book UI can list
		-- what was discovered, not just a count.
		profile.DiscoveredCombinations[comboId] = petRecord.name
		profile.DiscoveredCount += 1

		for _, milestone in ipairs(MILESTONES) do
			-- Keyed by string, not number: DataStores silently turn sparse
			-- numeric-keyed table keys into strings on save/load, so a
			-- numeric key here would stop matching after a server restart.
			local milestoneKey = tostring(milestone)
			if profile.DiscoveredCount >= milestone and not profile.MilestonesClaimed[milestoneKey] then
				profile.MilestonesClaimed[milestoneKey] = true
				local coinReward, dnaReward = milestoneReward(milestone)
				profile.Coins += coinReward
				profile.DNA += dnaReward
				milestoneHit = milestone
				break -- only announce the single milestone just crossed
			end
		end
	end

	Remotes.Event.PetDiscovered:FireClient(player, petRecord, isNewDiscovery, milestoneHit)

	if petRecord.isSecret then
		profile.Coins += SECRET_COIN_REWARD
		profile.DNA += SECRET_DNA_REWARD
		Remotes.Event.SecretPetAnnouncement:FireAllClients(player.Name, petRecord.name)
	end
end

function CollectionService.init() end

return CollectionService
