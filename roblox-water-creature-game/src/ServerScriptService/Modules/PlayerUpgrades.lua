-- Owns each player's shop upgrade tiers (a non-leaderstat "Upgrades" folder,
-- so it doesn't clutter the player list) and the purchase logic.
-- Server-authoritative: the client only ever asks to purchase, never sets a
-- tier directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

local PlayerUpgrades = {}

function PlayerUpgrades.Init(player)
	if player:FindFirstChild("Upgrades") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Upgrades"

	for _, key in ipairs(Config.UpgradeOrder) do
		local tier = Instance.new("IntValue")
		tier.Name = key
		tier.Value = 0
		tier.Parent = folder
	end

	folder.Parent = player
end

function PlayerUpgrades.GetTier(player, key)
	local folder = player:FindFirstChild("Upgrades")
	return folder and folder[key].Value or 0
end

function PlayerUpgrades.GetAttackPower(player)
	return 1 + PlayerUpgrades.GetTier(player, "AttackPower")
end

function PlayerUpgrades.GetExtraMaxHealth(player)
	return PlayerUpgrades.GetTier(player, "Vitality") * Config.Upgrades.Vitality.HealthPerTier
end

function PlayerUpgrades.GetExtraWalkSpeed(player)
	return PlayerUpgrades.GetTier(player, "SwimSpeed") * Config.Upgrades.SwimSpeed.SpeedPerTier
end

function PlayerUpgrades.GetMoneyMultiplier(player)
	local tier = PlayerUpgrades.GetTier(player, "MoneyBoost")
	return 1 + tier * Config.Upgrades.MoneyBoost.PercentPerTier / 100
end

function PlayerUpgrades.GetXPMultiplier(player)
	local tier = PlayerUpgrades.GetTier(player, "XPBoost")
	return 1 + tier * Config.Upgrades.XPBoost.PercentPerTier / 100
end

-- Combines the Armor upgrade with the permanent "Golden Scales" Robux perk
-- (stored as a replicated BoolValue under player.Consumables — see
-- RobuxShop.lua) into a single percent reduction applied to incoming damage.
function PlayerUpgrades.ReduceIncomingDamage(player, baseDamage)
	local armorTier = PlayerUpgrades.GetTier(player, "Armor")
	local reductionPercent = armorTier * Config.Upgrades.Armor.DamageReductionPercentPerTier

	local consumables = player:FindFirstChild("Consumables")
	local goldenScales = consumables and consumables:FindFirstChild("GoldenScales")
	if goldenScales and goldenScales.Value then
		reductionPercent += Config.GoldenScalesDamageReductionPercent
	end

	reductionPercent = math.min(reductionPercent, 85)
	return math.max(1, baseDamage * (1 - reductionPercent / 100))
end

-- Attempts to buy the next tier of `key` for `player`. Returns
-- (true, newTier) on success or (false, reason) on failure.
function PlayerUpgrades.Purchase(player, key)
	local upgradeConfig = Config.Upgrades[key]
	if not upgradeConfig then
		return false, "Unknown upgrade"
	end

	local folder = player:FindFirstChild("Upgrades")
	local leaderstats = player:FindFirstChild("leaderstats")
	if not folder or not leaderstats then
		return false, "Not ready"
	end

	local tierValue = folder[key]
	if tierValue.Value >= upgradeConfig.MaxTier then
		return false, "Already maxed"
	end

	local cost = Config.UpgradeCost(key, tierValue.Value)
	if leaderstats.Money.Value < cost then
		return false, "Not enough money"
	end

	leaderstats.Money.Value -= cost
	tierValue.Value += 1

	return true, tierValue.Value
end

return PlayerUpgrades
