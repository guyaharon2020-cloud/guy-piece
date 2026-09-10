-- UpgradeService.lua
-- Lab upgrade tracks. Most effects (roll cost, luck, storage/slot caps) are
-- read directly off profile.Upgrades[<key>] by the services that need them;
-- this module owns validating purchases and the two multiplier helpers used
-- by ChallengeService for reward payouts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local UpgradeDefs = require(Shared:WaitForChild("UpgradeDefs"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local UpgradeService = {}

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
	local def = UpgradeDefs.Definitions[key]
	if not profile or not def then
		return
	end

	local level = profile.Upgrades[key]
	if level >= def.maxLevel then
		pushProfile(player, { Error = key .. " is already maxed out" })
		return
	end

	local cost = UpgradeDefs.costFor(key, level)
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
