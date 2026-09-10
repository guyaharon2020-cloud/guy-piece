-- Shared tuning values for the water-creature game.
-- Edit these to change difficulty, spawn rates, and progression pace.

local Config = {}

-- World / water
Config.WaterCenter = Vector3.new(0, -10, 0)
Config.WaterSize = Vector3.new(1000, 60, 1000)
Config.SeabedY = Config.WaterCenter.Y - Config.WaterSize.Y / 2 -- top of the sand floor

-- Map barrier: a hollow sand "frame" filled right at the edge of the water
-- block so players can't swim past the play area.
Config.BarrierThickness = 40
Config.BarrierHeight = 150

-- Corals scattered across the seabed, purely decorative.
Config.CoralCount = 150
Config.GiantCoralCount = 15 -- big centerpiece formations (towers/fans/clams)

-- Small islands ringing the outer play area, purely decorative.
Config.IslandCount = 6

-- The sky spawn platform + portal every player (re)spawns on.
Config.SkySpawnHeight = 250 -- studs above the water surface
Config.SkySpawnPlatformSize = Vector3.new(40, 2, 40)
Config.SkySpawnPortalOffset = 16 -- studs from the platform center

-- Ship patrol movement: slow drift in a small circle around each ship's
-- spawn point.
Config.ShipDriftRadiusMin = 15
Config.ShipDriftRadiusMax = 35
Config.ShipDriftDegreesPerSecondMin = 3
Config.ShipDriftDegreesPerSecondMax = 8

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

-- Each tier's Attack is what pressing the attack key (see AttackController
-- / PlayerCombat) does — evolving swaps it immediately, since PlayerCombat
-- always reads the attacker's CURRENT Evolution tier live, never a cached
-- value.
--   Type = "melee"    single target in front, within Range and ConeAngle
--   Type = "dash"     lunge forward (DashSpeed) + melee hit during the dash
--   Type = "aoe"      damages every other player within Range, all around
--
-- Each tier's Body is a distinct fish-shaped model (see
-- CreatureAppearance.lua) — Length/Width/Height/SnoutLength in studs before
-- the level/evolution size multiplier is applied on top. HasTeeth/HasSpikes
-- add small extra features on top of the base shape.
Config.EvolutionTiers = {
	{
		Name = "Minnow", Color = Color3.fromRGB(90, 170, 200), FinColor = Color3.fromRGB(50, 120, 150),
		FinScale = 1.0, SpeedBonus = 0, SizeBonus = 0,
		Body = { Length = 3.5, Width = 1.2, Height = 1.1, SnoutLength = 0.8 },
		Attack = { Name = "Nibble", Type = "melee", Range = 8, ConeAngle = 80, Damage = 8, Cooldown = 1.2 },
	},
	{
		Name = "Barracuda", Color = Color3.fromRGB(70, 150, 190), FinColor = Color3.fromRGB(30, 100, 140),
		FinScale = 1.15, SpeedBonus = 10, SizeBonus = 0.15,
		Body = { Length = 5.5, Width = 1.1, Height = 1.0, SnoutLength = 1.3 },
		Attack = { Name = "Lunge Strike", Type = "dash", Range = 20, ConeAngle = 50, DashSpeed = 90, Damage = 12, Cooldown = 2.5 },
	},
	{
		Name = "Reef Shark", Color = Color3.fromRGB(100, 115, 130), FinColor = Color3.fromRGB(55, 65, 78),
		FinScale = 1.3, SpeedBonus = 20, SizeBonus = 0.3,
		Body = { Length = 6, Width = 1.7, Height = 1.5, SnoutLength = 1.2 },
		Attack = { Name = "Spin Bite", Type = "aoe", Range = 12, Damage = 14, Cooldown = 2.2 },
	},
	{
		Name = "Great White", Color = Color3.fromRGB(160, 168, 176), FinColor = Color3.fromRGB(75, 80, 90),
		FinScale = 1.5, SpeedBonus = 32, SizeBonus = 0.5,
		Body = { Length = 7.5, Width = 2.1, Height = 1.9, SnoutLength = 1.5 },
		Attack = { Name = "Crushing Jaws", Type = "melee", Range = 10, ConeAngle = 60, Damage = 24, Cooldown = 2.8 },
	},
	{
		Name = "Megalodon", Color = Color3.fromRGB(55, 60, 75), FinColor = Color3.fromRGB(18, 20, 28),
		FinScale = 1.8, SpeedBonus = 46, SizeBonus = 0.8,
		Body = { Length = 9.5, Width = 2.6, Height = 2.3, SnoutLength = 1.8, HasTeeth = true },
		Attack = { Name = "Tidal Slam", Type = "aoe", Range = 18, Damage = 22, Cooldown = 3.5 },
	},
	{
		Name = "Leviathan", Color = Color3.fromRGB(25, 195, 160), FinColor = Color3.fromRGB(10, 255, 200),
		FinScale = 2.2, SpeedBonus = 65, SizeBonus = 1.2,
		Body = { Length = 11.5, Width = 3.1, Height = 2.7, SnoutLength = 2.1, HasTeeth = true, HasSpikes = true },
		Attack = { Name = "Abyssal Roar", Type = "aoe", Range = 26, Damage = 32, Cooldown = 4.5 },
	},
}
Config.MaxEvolutionTier = #Config.EvolutionTiers - 1 -- 0-indexed (tier 0 = Minnow)

-- Players above this Y (i.e. still on/near the sky spawn platform) can
-- neither attack nor be attacked — a simple anti-spawn-kill safe zone.
Config.PvPSafeZoneY = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 50

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
		SailColor = Color3.fromRGB(235, 225, 205),
		MastCount = 1,
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
		SailColor = Color3.fromRGB(220, 220, 225),
		MastCount = 2,
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
		SailColor = Color3.fromRGB(235, 220, 180),
		MastCount = 3,
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
