-- InventoryService.lua
-- Equip/unequip/release logic plus storage & pet-slot capacity, both driven
-- by lab upgrade levels.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local InventoryService = {}

-- Fires (player) whenever equipped pets change, so PetFollowService can
-- resync the physical models it's puppeting for that player.
InventoryService.EquipChanged = Instance.new("BindableEvent")

local MAX_EQUIPPED_CAP = 6

function InventoryService.maxStorage(profile)
	return 20 + (profile.Upgrades.Storage - 1) * 15
end

function InventoryService.maxEquipped(profile)
	return math.min(MAX_EQUIPPED_CAP, profile.Upgrades.PetSlots)
end

function InventoryService.count(profile)
	local n = 0
	for _ in pairs(profile.Inventory) do
		n += 1
	end
	return n
end

function InventoryService.canAddPet(profile)
	return InventoryService.count(profile) < InventoryService.maxStorage(profile)
end

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = {
		Coins = profile.Coins,
		DNA = profile.DNA,
		EquippedPetIds = profile.EquippedPetIds,
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

local function onEquipPet(player, petId)
	local profile = DataService.Get(player)
	if not profile or type(petId) ~= "string" then
		return
	end
	if not profile.Inventory[petId] then
		return
	end
	for _, id in ipairs(profile.EquippedPetIds) do
		if id == petId then
			return -- already equipped
		end
	end
	if #profile.EquippedPetIds >= InventoryService.maxEquipped(profile) then
		pushProfile(player, { Error = "All pet slots are full" })
		return
	end

	table.insert(profile.EquippedPetIds, petId)
	InventoryService.EquipChanged:Fire(player)
	pushProfile(player)
end

local function onUnequipPet(player, petId)
	local profile = DataService.Get(player)
	if not profile or type(petId) ~= "string" then
		return
	end
	for i, id in ipairs(profile.EquippedPetIds) do
		if id == petId then
			table.remove(profile.EquippedPetIds, i)
			InventoryService.EquipChanged:Fire(player)
			pushProfile(player)
			return
		end
	end
end

local function onReleasePet(player, petId)
	local profile = DataService.Get(player)
	if not profile or type(petId) ~= "string" then
		return
	end
	local record = profile.Inventory[petId]
	if not record then
		return
	end

	for i, id in ipairs(profile.EquippedPetIds) do
		if id == petId then
			table.remove(profile.EquippedPetIds, i)
			break
		end
	end

	profile.Inventory[petId] = nil
	profile.Coins += math.max(1, math.floor(record.value * 0.1))

	InventoryService.EquipChanged:Fire(player)
	pushProfile(player, { ReleasedPetId = petId })
end

function InventoryService.init()
	Remotes.Event.EquipPet.OnServerEvent:Connect(onEquipPet)
	Remotes.Event.UnequipPet.OnServerEvent:Connect(onUnequipPet)
	Remotes.Event.ReleasePet.OnServerEvent:Connect(onReleasePet)
end

return InventoryService
