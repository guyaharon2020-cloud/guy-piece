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

-- Economy: destroying a raft/ship pays out per human that was aboard
Config.MoneyPerHuman = 1
Config.XPPerHuman = 10

-- Leveling
Config.WalkSpeedPerLevel = 3
Config.SizePerLevel = 0.03 -- +3% scale per level (on top of the evolution tier's base)
Config.BaseWalkSpeed = 40
Config.MaxLevel = 50

-- XP required to go from `level` to `level + 1`
function Config.XPForLevel(level)
	return math.floor(100 * level ^ 1.35)
end

-- Evolution: every LevelsPerEvolution levels, the creature evolves into the
-- next tier (new color/fins/base stats) and Level + XP reset to 1/0 so you
-- level up again within the new tier. Money and shop upgrades are NOT reset.
Config.LevelsPerEvolution = 12
Config.EvolutionTiers = {
	{ Name = "Minnow", Color = Color3.fromRGB(90, 170, 200), FinColor = Color3.fromRGB(50, 120, 150), FinScale = 1.0, SpeedBonus = 0, SizeBonus = 0 },
	{ Name = "Barracuda", Color = Color3.fromRGB(70, 150, 190), FinColor = Color3.fromRGB(30, 100, 140), FinScale = 1.15, SpeedBonus = 10, SizeBonus = 0.15 },
	{ Name = "Reef Shark", Color = Color3.fromRGB(100, 115, 130), FinColor = Color3.fromRGB(55, 65, 78), FinScale = 1.3, SpeedBonus = 20, SizeBonus = 0.3 },
	{ Name = "Great White", Color = Color3.fromRGB(160, 168, 176), FinColor = Color3.fromRGB(75, 80, 90), FinScale = 1.5, SpeedBonus = 32, SizeBonus = 0.5 },
	{ Name = "Megalodon", Color = Color3.fromRGB(55, 60, 75), FinColor = Color3.fromRGB(18, 20, 28), FinScale = 1.8, SpeedBonus = 46, SizeBonus = 0.8 },
	{ Name = "Leviathan", Color = Color3.fromRGB(25, 195, 160), FinColor = Color3.fromRGB(10, 255, 200), FinScale = 2.2, SpeedBonus = 65, SizeBonus = 1.2 },
}
Config.MaxEvolutionTier = #Config.EvolutionTiers - 1 -- 0-indexed (tier 0 = Minnow)

-- Ships: several types, each with its own size/color/human count. Types with
-- HasCannon fire on nearby players at short range (see ShipCannons).
Config.ShipSpawnInterval = 25
Config.MaxShips = 4
Config.ShipTypes = {
	{
		Key = "Sloop",
		Name = "Sloop",
		Weight = 50,
		HullSize = Vector3.new(28, 6, 11),
		HullColor = Color3.fromRGB(120, 85, 55),
		CabinColor = Color3.fromRGB(150, 110, 70),
		HumansMin = 8,
		HumansMax = 12,
		HealthBonus = 0,
		HasCannon = false,
	},
	{
		Key = "Frigate",
		Name = "Frigate",
		Weight = 35,
		HullSize = Vector3.new(34, 7, 13),
		HullColor = Color3.fromRGB(70, 75, 82),
		CabinColor = Color3.fromRGB(45, 48, 55),
		HumansMin = 12,
		HumansMax = 18,
		HealthBonus = 6,
		HasCannon = true,
		CannonDamage = 10,
		CannonRange = 55,
		CannonCooldown = 5,
	},
	{
		Key = "Galleon",
		Name = "Galleon",
		Weight = 15,
		HullSize = Vector3.new(42, 8, 16),
		HullColor = Color3.fromRGB(120, 35, 40),
		CabinColor = Color3.fromRGB(150, 120, 40),
		HumansMin = 18,
		HumansMax = 26,
		HealthBonus = 14,
		HasCannon = true,
		CannonDamage = 16,
		CannonRange = 65,
		CannonCooldown = 4,
	},
}

-- Picks a ship type using each entry's Weight (bigger weight = more common).
function Config.PickShipType()
	local totalWeight = 0
	for _, shipType in ipairs(Config.ShipTypes) do
		totalWeight += shipType.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, shipType in ipairs(Config.ShipTypes) do
		cumulative += shipType.Weight
		if roll <= cumulative then
			return shipType
		end
	end

	return Config.ShipTypes[#Config.ShipTypes]
end

-- Ship combat
Config.ShipContactDamage = 15 -- base damage dealt to the player per ram hit
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
	Vitality = {
		Name = "Vitality",
		Description = "Increases your max health.",
		MaxTier = 9,
		BaseCost = 15,
		CostGrowth = 1.55,
		HealthPerTier = 20,
	},
	Armor = {
		Name = "Scales",
		Description = "Reduces damage taken from ships and cannon fire.",
		MaxTier = 9,
		BaseCost = 18,
		CostGrowth = 1.6,
		DamageReductionPercentPerTier = 4,
	},
	SwimSpeed = {
		Name = "Fins",
		Description = "Swim faster.",
		MaxTier = 9,
		BaseCost = 12,
		CostGrowth = 1.5,
		SpeedPerTier = 4,
	},
	MoneyBoost = {
		Name = "Greed",
		Description = "Earn more Money per human destroyed.",
		MaxTier = 9,
		BaseCost = 20,
		CostGrowth = 1.7,
		PercentPerTier = 8,
	},
	XPBoost = {
		Name = "Wisdom",
		Description = "Earn more XP per human destroyed.",
		MaxTier = 9,
		BaseCost = 20,
		CostGrowth = 1.7,
		PercentPerTier = 8,
	},
}
Config.UpgradeOrder = { "AttackPower", "Vitality", "Armor", "SwimSpeed", "MoneyBoost", "XPBoost" }

-- Cost to go from `currentTier` to `currentTier + 1` for the given upgrade.
function Config.UpgradeCost(upgradeKey, currentTier)
	local upgrade = Config.Upgrades[upgradeKey]
	return math.floor(upgrade.BaseCost * (upgrade.CostGrowth ^ currentTier))
end

-- Robux shop ("super powers" bought with real Robux via Developer Products).
-- IMPORTANT: ProductId = 0 is a placeholder. Create each Developer Product in
-- Studio (Monetization tab, once the place is published) and paste its real
-- ID here before this can actually be purchased.
Config.GoldenScalesDamageReductionPercent = 25
Config.RobuxProducts = {
	{
		Key = "DoubleMoney30",
		ProductId = 0,
		Name = "2x Money (30 min)",
		Description = "Doubles the Money you earn from every kill for 30 minutes.",
		DisplayPriceHint = "R$ 49",
		Kind = "Boost",
		BoostType = "Money",
		Multiplier = 2,
		DurationSeconds = 1800,
	},
	{
		Key = "DoubleXP30",
		ProductId = 0,
		Name = "2x XP (30 min)",
		Description = "Doubles the XP you earn from every kill for 30 minutes.",
		DisplayPriceHint = "R$ 49",
		Kind = "Boost",
		BoostType = "XP",
		Multiplier = 2,
		DurationSeconds = 1800,
	},
	{
		Key = "DepthCharge",
		ProductId = 0,
		Name = "Depth Charge",
		Description = "Instantly sinks the next ship you touch, no matter its health.",
		DisplayPriceHint = "R$ 25",
		Kind = "Consumable",
		Charges = 1,
	},
	{
		Key = "GoldenScales",
		ProductId = 0,
		Name = "Golden Scales",
		Description = "Permanent +25% damage reduction from ships, forever, and a shimmering gold look.",
		DisplayPriceHint = "R$ 149",
		Kind = "Permanent",
	},
}

return Config
