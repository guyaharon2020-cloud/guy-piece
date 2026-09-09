-- Shared tuning values for the water-creature game.
-- Edit these to change difficulty, spawn rates, and progression pace.

local Config = {}

-- World / water
Config.WaterCenter = Vector3.new(0, -10, 0)
Config.WaterSize = Vector3.new(1000, 60, 1000)

-- Raft spawning
Config.RaftSpawnInterval = 8 -- seconds between spawn attempts
Config.MaxRafts = 12 -- rafts alive at once
Config.SpawnRadius = 400 -- studs from the water center
Config.HumansPerRaftMin = 2
Config.HumansPerRaftMax = 6

-- Economy: destroying a raft pays out per human that was on it
Config.MoneyPerHuman = 1
Config.XPPerHuman = 10

-- Leveling: swim speed and size grow with level
Config.BaseWalkSpeed = 40
Config.WalkSpeedPerLevel = 3
Config.SizePerLevel = 0.03 -- +3% scale per level
Config.MaxLevel = 50

-- XP required to go from `level` to `level + 1`
function Config.XPForLevel(level)
	return math.floor(100 * level ^ 1.35)
end

-- Ships: bigger, tougher targets than rafts. They carry more humans (a
-- bigger payout) but take several hits to sink and hit back while you're
-- attacking them, so the shop upgrades below matter most here.
Config.ShipSpawnInterval = 25
Config.MaxShips = 4
Config.HumansPerShipMin = 8
Config.HumansPerShipMax = 15
Config.ShipContactDamage = 15 -- base damage dealt to the player per hit landed
Config.ShipTouchCooldown = 1 -- seconds between hits registering against the same ship

-- Upgrade shop: tiers bought with Money (leaderstat), 0 = not purchased yet.
Config.Upgrades = {
	AttackPower = {
		Name = "Bite Power",
		Description = "Deal more damage per hit against ships.",
		MaxTier = 9,
		BaseCost = 15,
		CostGrowth = 1.6,
	},
	Armor = {
		Name = "Armor",
		Description = "More max health and less damage taken from ships.",
		MaxTier = 9,
		BaseCost = 15,
		CostGrowth = 1.6,
		HealthPerTier = 20,
		DamageReductionPerTier = 1.5,
	},
	SwimSpeed = {
		Name = "Fins",
		Description = "Swim faster.",
		MaxTier = 9,
		BaseCost = 12,
		CostGrowth = 1.5,
		SpeedPerTier = 4,
	},
}

-- Cost to go from `currentTier` to `currentTier + 1` for the given upgrade.
function Config.UpgradeCost(upgradeKey, currentTier)
	local upgrade = Config.Upgrades[upgradeKey]
	return math.floor(upgrade.BaseCost * (upgrade.CostGrowth ^ currentTier))
end

return Config
