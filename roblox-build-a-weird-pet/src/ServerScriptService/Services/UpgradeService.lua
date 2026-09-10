-- UpgradeService.lua
-- Lab upgrade tracks. Most effects (roll cost, luck, storage/slot caps) are
-- read directly off profile.Upgrades[<key>] by the services that need them;
-- this module owns validating purchases and the two multiplier helpers used
-- by ChallengeService for reward payouts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local UpgradeService = {}

UpgradeService.Definitions = {
	PartGenerator = { name = "Part Generator", maxLevel = 5, baseCost = 50, description = "Lowers the DNA cost to roll parts." },
	Storage = { name = "Storage", maxLevel = 10, baseCost = 75, description = "+15 max stored pets per level." },
	Luck = { name = "Luck", maxLevel = 10, baseCost = 100, description = "Better odds for rare parts & mutations." },
	PetSlots = { name = "Pet Slots", maxLevel = 6, baseCost = 250, description = "+1 equipped pet per level." },
	DNAMultiplier = { name = "DNA Multiplier", maxLevel = 10, baseCost = 150, description = "+10% DNA from challenges per level." },
	CoinMultiplier = { name = "Coin Multiplier", maxLevel = 10, baseCost = 150, description = "+10% Coins from challenges per level." },
}

function UpgradeService.costFor(key, level)
	local def = UpgradeService.Definitions[key]
	return math.round(def.baseCost * 1.6 ^ (level - 1))
end

function UpgradeService.totalLevel(profile)
	local total = 0
	for _, level in pairs(profile.Upgrades) do
		total += level
	end
	return total
end

function UpgradeService.coinMultiplier(profile)
	return 1 + (profile.Upgrades.CoinMultiplier - 1) * 0.1
end

function UpgradeService.dnaMultiplier(profile)
	return 1 + (profile.Upgrades.DNAMultiplier - 1) * 0.1
end

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = { Coins = profile.Coins, Upgrades = profile.Upgrades }
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

local function onBuyUpgrade(player, key)
	local profile = DataService.Get(player)
	local def = UpgradeService.Definitions[key]
	if not profile or not def then
		return
	end

	local level = profile.Upgrades[key]
	if level >= def.maxLevel then
		pushProfile(player, { Error = key .. " is already maxed out" })
		return
	end

	local cost = UpgradeService.costFor(key, level)
	if profile.Coins < cost then
		pushProfile(player, { Error = "Not enough Coins" })
		return
	end

	profile.Coins -= cost
	profile.Upgrades[key] = level + 1
	pushProfile(player)
end

function UpgradeService.init()
	Remotes.Event.BuyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
end

return UpgradeService
