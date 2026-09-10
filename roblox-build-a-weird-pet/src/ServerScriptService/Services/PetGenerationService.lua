-- PetGenerationService.lua
-- Handles rolling random parts from the Part Generator and combining a
-- player's currently-rolled parts into a finished pet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Remotes"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local PetStats = require(Shared:WaitForChild("PetStats"))
local SecretPets = require(Shared:WaitForChild("SecretPets"))
local PartShop = require(Shared:WaitForChild("PartShop"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local CollectionService = require(script.Parent:WaitForChild("CollectionService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local PetGenerationService = {}

local DNA_ROLL_BASE_COST = 5

local function rollCost(profile)
	local level = profile.Upgrades.PartGenerator
	return math.max(1, DNA_ROLL_BASE_COST - (level - 1))
end

local function luckMultiplier(profile)
	local level = profile.Upgrades.Luck
	return 1 + (level - 1) * 0.2
end

local function shortWord(name)
	return name:match("^(%a+)") or name
end

local function autoName(parts, mutation)
	local base = shortWord(parts.Head.name) .. " " .. shortWord(parts.Body.name)
	if mutation then
		return ("%s the %s"):format(base, mutation.name)
	end
	return base
end

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = {
		Coins = profile.Coins,
		DNA = profile.DNA,
		Mutations = profile.Mutations,
		PendingParts = profile.PendingParts,
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

local function onRequestPartRoll(player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end

	local world = Worlds.get(profile.CurrentWorld)
	if not world or not profile.WorldsUnlocked[world.id] then
		return
	end

	local cost = rollCost(profile)
	if profile.DNA < cost then
		pushProfile(player, { Error = "Not enough DNA" })
		return
	end
	profile.DNA -= cost

	local luck = luckMultiplier(profile)
	local rolled = {}
	for _, slot in ipairs(PetStats.Slots) do
		local pool = world.parts[slot]
		local picked = Rarity.weightedPick(pool, luck)
		rolled[slot] = picked.id
	end
	profile.PendingParts = rolled

	pushProfile(player)
end

-- Buying a specific part (Shop -> Animal Parts) fills just that one slot of
-- the player's pending roll, same as if the generator had rolled it -- lets
-- players lock in a part they want while still rolling/relying on luck for
-- the rest.
local function onBuyPart(player, partId)
	local profile = DataService.Get(player)
	if not profile or type(partId) ~= "string" then
		return
	end

	local def = Worlds.PartById[partId]
	if not def then
		return
	end
	if not profile.WorldsUnlocked[def.worldId] then
		pushProfile(player, { Error = "Unlock that world first" })
		return
	end
	if not PartShop.isPurchasable(def) then
		pushProfile(player, { Error = "That part can't be bought -- roll for it instead" })
		return
	end

	local price = PartShop.priceFor(def)
	if profile.DNA < price then
		pushProfile(player, { Error = "Not enough DNA" })
		return
	end

	profile.DNA -= price
	profile.PendingParts = profile.PendingParts or {}
	profile.PendingParts[def.slot] = def.id

	pushProfile(player)
end

local function onCreatePet(player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local pending = profile.PendingParts
	if not pending then
		return
	end
	if not InventoryService.canAddPet(profile) then
		pushProfile(player, { Error = "Inventory full -- upgrade Storage or release a pet" })
		return
	end

	local parts = {}
	for _, slot in ipairs(PetStats.Slots) do
		local id = pending[slot]
		local def = id and Worlds.PartById[id]
		if not def then
			return -- incomplete/corrupt roll, refuse to create
		end
		parts[slot] = def
	end

	local luck = luckMultiplier(profile)
	local mutation = Mutations.roll(luck)
	local stats, overallRarity, totalValue = PetStats.compute(parts, mutation)
	local comboId = PetStats.comboId(parts)
	local secretName = SecretPets.lookup(comboId)
	local name = secretName or autoName(parts, mutation)

	local partIds = {}
	for slot, def in pairs(parts) do
		partIds[slot] = def.id
	end

	-- Prefixed (not a bare numeric string) so DataStore's array/dictionary
	-- encoding never has ambiguous sequential-integer-looking keys to guess
	-- at across a save/load round trip.
	local petId = "pet_" .. profile.NextPetId
	profile.NextPetId += 1

	local record = {
		id = petId,
		name = name,
		parts = partIds,
		mutationId = mutation and mutation.id or nil,
		stats = stats,
		rarity = overallRarity,
		value = totalValue,
		comboId = comboId,
		isSecret = secretName ~= nil,
	}

	profile.Inventory[petId] = record
	profile.PendingParts = nil

	if mutation then
		profile.Mutations += 1
	end

	CollectionService.RegisterDiscovery(player, record)

	pushProfile(player, {
		NewPet = record,
		DiscoveredCombinations = profile.DiscoveredCombinations,
		DiscoveredCount = profile.DiscoveredCount,
		MilestonesClaimed = profile.MilestonesClaimed,
	})
end

function PetGenerationService.init()
	Remotes.Event.RequestPartRoll.OnServerEvent:Connect(onRequestPartRoll)
	Remotes.Event.BuyPart.OnServerEvent:Connect(onBuyPart)
	Remotes.Event.CreatePet.OnServerEvent:Connect(onCreatePet)
end

return PetGenerationService
