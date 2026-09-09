-- Owns each player's shop upgrade tiers (a non-leaderstat "Upgrades" folder,
-- so it doesn't clutter the player list) and the purchase logic.
-- Server-authoritative: the client only ever asks to purchase, never sets a
-- tier directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

local UPGRADE_KEYS = { "AttackPower", "Armor", "SwimSpeed" }

local PlayerUpgrades = {}

function PlayerUpgrades.Init(player)
	if player:FindFirstChild("Upgrades") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Upgrades"

	for _, key in ipairs(UPGRADE_KEYS) do
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
	return PlayerUpgrades.GetTier(player, "Armor") * Config.Upgrades.Armor.HealthPerTier
end

function PlayerUpgrades.GetShipDamageTaken(player)
	local armorTier = PlayerUpgrades.GetTier(player, "Armor")
	local reduction = armorTier * Config.Upgrades.Armor.DamageReductionPerTier
	return math.max(2, Config.ShipContactDamage - reduction)
end

function PlayerUpgrades.GetExtraWalkSpeed(player)
	return PlayerUpgrades.GetTier(player, "SwimSpeed") * Config.Upgrades.SwimSpeed.SpeedPerTier
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
