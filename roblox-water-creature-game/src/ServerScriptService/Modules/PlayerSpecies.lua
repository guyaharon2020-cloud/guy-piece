-- Tracks which water-creature species each player owns and which one is
-- currently selected. The two starters (see Config.StarterSpecies) are
-- always owned for free; others must be bought in the shop's Creatures tab
-- (ShopCost > 0) before they can be selected. Server-authoritative: the
-- client only ever requests a purchase or a selection, never sets either
-- directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

local PlayerSpecies = {}

function PlayerSpecies.Init(player)
	if player:FindFirstChild("Species") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Species"

	for _, key in ipairs(Config.SpeciesOrder) do
		local owned = Instance.new("BoolValue")
		owned.Name = key
		owned.Value = Config.Species[key].ShopCost == 0
		owned.Parent = folder
	end

	folder.Parent = player

	if not player:GetAttribute("SelectedSpecies") then
		player:SetAttribute("SelectedSpecies", Config.DefaultSpecies)
	end
end

function PlayerSpecies.IsOwned(player, key)
	local folder = player:FindFirstChild("Species")
	local owned = folder and folder:FindFirstChild(key)
	return owned ~= nil and owned.Value == true
end

function PlayerSpecies.GetSelected(player)
	local key = player:GetAttribute("SelectedSpecies")
	if key and Config.Species[key] then
		return key
	end
	return Config.DefaultSpecies
end

-- Returns (true) on success or (false, reason) on failure. Does not
-- teleport or rebuild appearance — callers (SkySpawn's portal handler) do
-- that afterward.
function PlayerSpecies.Select(player, key)
	if not Config.Species[key] then
		return false, "Unknown species"
	end
	if not PlayerSpecies.IsOwned(player, key) then
		return false, "Not owned"
	end

	player:SetAttribute("SelectedSpecies", key)
	return true
end

-- Returns (true) on success or (false, reason) on failure.
function PlayerSpecies.Purchase(player, key)
	local species = Config.Species[key]
	if not species then
		return false, "Unknown species"
	end
	if species.ShopCost <= 0 then
		return false, "Not purchasable"
	end
	if PlayerSpecies.IsOwned(player, key) then
		return false, "Already owned"
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local folder = player:FindFirstChild("Species")
	if not leaderstats or not folder then
		return false, "Not ready"
	end

	if leaderstats.Money.Value < species.ShopCost then
		return false, "Not enough money"
	end

	leaderstats.Money.Value -= species.ShopCost
	folder[key].Value = true

	return true
end

return PlayerSpecies
