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

-- The sky spawn platform + portal every player (re)spawns on, enclosed in
-- a glass cube. The floor is the invisible walkable platform (see-through
-- to the ocean below); the 4 walls + ceiling are translucent glass so the
-- space still reads as open while being clearly bounded.
Config.SkySpawnHeight = 250 -- studs above the water surface
Config.SkySpawnPlatformSize = Vector3.new(40, 2, 40)
Config.SkySpawnCubeHeight = 30 -- interior height of the glass cube
Config.SkySpawnPortalOffset = 12 -- studs from the platform center, inside the cube
Config.SkySpawnPortalRadius = 7

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
-- next tier (new color/fins/body/base stats) and Level + XP reset to 1/0 so
-- you level up again within the new tier. Money and shop upgrades are NOT
-- reset. Your evolution TIER NUMBER is shared across every species — only
-- the look (and which species you picked) changes what tier N actually
-- renders as; switching species never resets your Level/XP/Evolution.
Config.LevelsPerEvolution = 12
Config.MaxEvolutionTier = 5 -- 0-indexed (tier 0 = the starting form)

-- Per-tier stats and attack, shared by every species so switching species
-- is a pure reskin, not a rebalance. Attack is what pressing the attack key
-- (see AttackController / PlayerCombat) does — evolving swaps it
-- immediately, since PlayerCombat always reads the attacker's CURRENT
-- Evolution tier live, never a cached value.
--   Type = "melee"    single target in front, within Range and ConeAngle
--   Type = "dash"     lunge forward (DashSpeed) + melee hit during the dash
--   Type = "aoe"      damages every other player within Range, all around
Config.TierProgression = {
	{ SpeedBonus = 0, SizeBonus = 0, Attack = { Name = "Nibble", Type = "melee", Range = 8, ConeAngle = 80, Damage = 8, Cooldown = 1.2 } },
	{ SpeedBonus = 10, SizeBonus = 0.15, Attack = { Name = "Lunge Strike", Type = "dash", Range = 20, ConeAngle = 50, DashSpeed = 90, Damage = 12, Cooldown = 2.5 } },
	{ SpeedBonus = 20, SizeBonus = 0.3, Attack = { Name = "Spin Bite", Type = "aoe", Range = 12, Damage = 14, Cooldown = 2.2 } },
	{ SpeedBonus = 32, SizeBonus = 0.5, Attack = { Name = "Crushing Jaws", Type = "melee", Range = 10, ConeAngle = 60, Damage = 24, Cooldown = 2.8 } },
	{ SpeedBonus = 46, SizeBonus = 0.8, Attack = { Name = "Tidal Slam", Type = "aoe", Range = 18, Damage = 22, Cooldown = 3.5 } },
	{ SpeedBonus = 65, SizeBonus = 1.2, Attack = { Name = "Abyssal Roar", Type = "aoe", Range = 26, Damage = 32, Cooldown = 4.5 } },
}

-- Species: each has its own 6-tier look (Color/FinColor/FinScale/Body) built
-- by CreatureAppearance.lua according to BodyStyle:
--   "streamlined"  elongated body + pointed snout + forked tail (Fish, Dolphin)
--   "serpentine"   upright curled body + long snout + coiled tail (Sea Horse)
-- ShopCost = 0 means it's a free starter, choosable at the portal
-- (SkySpawn.server.lua). ShopCost > 0 means it must be bought first (see
-- PlayerSpecies.lua / the shop's Creatures tab) before it can be selected.
Config.Species = {
	Fish = {
		Name = "Fish",
		ShopCost = 0,
		BodyStyle = "streamlined",
		Tiers = {
			{ Name = "Minnow", Color = Color3.fromRGB(90, 170, 200), FinColor = Color3.fromRGB(50, 120, 150), FinScale = 1.0,
				Body = { Length = 3.5, Width = 1.2, Height = 1.1, SnoutLength = 0.8 } },
			{ Name = "Barracuda", Color = Color3.fromRGB(70, 150, 190), FinColor = Color3.fromRGB(30, 100, 140), FinScale = 1.15,
				Body = { Length = 5.5, Width = 1.1, Height = 1.0, SnoutLength = 1.3 } },
			{ Name = "Reef Shark", Color = Color3.fromRGB(100, 115, 130), FinColor = Color3.fromRGB(55, 65, 78), FinScale = 1.3,
				Body = { Length = 6, Width = 1.7, Height = 1.5, SnoutLength = 1.2 } },
			{ Name = "Great White", Color = Color3.fromRGB(160, 168, 176), FinColor = Color3.fromRGB(75, 80, 90), FinScale = 1.5,
				Body = { Length = 7.5, Width = 2.1, Height = 1.9, SnoutLength = 1.5 } },
			{ Name = "Megalodon", Color = Color3.fromRGB(55, 60, 75), FinColor = Color3.fromRGB(18, 20, 28), FinScale = 1.8,
				Body = { Length = 9.5, Width = 2.6, Height = 2.3, SnoutLength = 1.8, HasTeeth = true } },
			{ Name = "Leviathan", Color = Color3.fromRGB(25, 195, 160), FinColor = Color3.fromRGB(10, 255, 200), FinScale = 2.2,
				Body = { Length = 11.5, Width = 3.1, Height = 2.7, SnoutLength = 2.1, HasTeeth = true, HasSpikes = true } },
		},
	},
	SeaHorse = {
		Name = "Sea Horse",
		ShopCost = 0,
		BodyStyle = "serpentine",
		Tiers = {
			{ Name = "Hatchling Seahorse", Color = Color3.fromRGB(230, 210, 140), FinColor = Color3.fromRGB(200, 170, 100), FinScale = 1.0,
				Body = { Height = 2.2, Width = 0.7, SnoutLength = 0.6, TailSegments = 3 } },
			{ Name = "Common Seahorse", Color = Color3.fromRGB(210, 150, 80), FinColor = Color3.fromRGB(180, 120, 60), FinScale = 1.1,
				Body = { Height = 3.2, Width = 0.85, SnoutLength = 0.9, TailSegments = 4 } },
			{ Name = "Spiny Seahorse", Color = Color3.fromRGB(140, 90, 160), FinColor = Color3.fromRGB(110, 60, 130), FinScale = 1.2,
				Body = { Height = 4, Width = 1.0, SnoutLength = 1.1, TailSegments = 4, HasSpines = true } },
			{ Name = "Pygmy Dragon", Color = Color3.fromRGB(90, 170, 110), FinColor = Color3.fromRGB(60, 140, 80), FinScale = 1.35,
				Body = { Height = 4.8, Width = 1.2, SnoutLength = 1.3, TailSegments = 5, HasSpines = true } },
			{ Name = "Weedy Seadragon", Color = Color3.fromRGB(180, 140, 60), FinColor = Color3.fromRGB(140, 100, 40), FinScale = 1.55,
				Body = { Height = 5.8, Width = 1.4, SnoutLength = 1.6, TailSegments = 5, HasSpines = true } },
			{ Name = "Kraken Seahorse", Color = Color3.fromRGB(40, 200, 190), FinColor = Color3.fromRGB(20, 255, 230), FinScale = 1.8,
				Body = { Height = 7, Width = 1.7, SnoutLength = 1.9, TailSegments = 6, HasSpines = true } },
		},
	},
	Dolphin = {
		Name = "Dolphin",
		ShopCost = 600,
		BodyStyle = "streamlined",
		Tiers = {
			{ Name = "Dolphin Calf", Color = Color3.fromRGB(140, 160, 175), FinColor = Color3.fromRGB(110, 130, 145), FinScale = 1.0,
				Body = { Length = 4, Width = 1.3, Height = 1.3, SnoutLength = 0.9 } },
			{ Name = "Bottlenose", Color = Color3.fromRGB(120, 145, 165), FinColor = Color3.fromRGB(90, 115, 135), FinScale = 1.2,
				Body = { Length = 6, Width = 1.6, Height = 1.6, SnoutLength = 1.3 } },
			{ Name = "Spinner Dolphin", Color = Color3.fromRGB(100, 130, 155), FinColor = Color3.fromRGB(75, 100, 125), FinScale = 1.35,
				Body = { Length = 7, Width = 1.8, Height = 1.8, SnoutLength = 1.4 } },
			{ Name = "Pilot Whale", Color = Color3.fromRGB(60, 70, 80), FinColor = Color3.fromRGB(40, 48, 56), FinScale = 1.55,
				Body = { Length = 8.5, Width = 2.3, Height = 2.2, SnoutLength = 1.5 } },
			{ Name = "Orca", Color = Color3.fromRGB(20, 22, 26), FinColor = Color3.fromRGB(245, 245, 245), FinScale = 1.8,
				Body = { Length = 10, Width = 2.7, Height = 2.6, SnoutLength = 1.6 } },
			{ Name = "Ancient Orca", Color = Color3.fromRGB(15, 40, 45), FinColor = Color3.fromRGB(140, 255, 235), FinScale = 2.1,
				Body = { Length = 12, Width = 3.2, Height = 3.0, SnoutLength = 1.8 } },
		},
	},
}
Config.SpeciesOrder = { "Fish", "SeaHorse", "Dolphin" }
Config.StarterSpecies = { "Fish", "SeaHorse" } -- free, choosable at the portal
Config.DefaultSpecies = "Fish"

-- Players above this Y (i.e. still on/near the sky spawn platform) can
-- neither attack nor be attacked — a simple anti-spawn-kill safe zone.
Config.PvPSafeZoneY = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 50

-- Ships: several types, each with its own size/color/human count. Types with
-- HasCannon fire on nearby players at short range (see ShipCannons).
Config.ShipSpawnInterval = 22
Config.MaxShips = 6
Config.ShipTypes = {
	{
		Key = "Sloop",
		Name = "Sloop",
		Weight = 35,
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
		Key = "Brigantine",
		Name = "Brigantine",
		Weight = 25,
		HullSize = Vector3.new(31, 6.5, 12),
		HullColor = Color3.fromRGB(95, 100, 70),
		CabinColor = Color3.fromRGB(120, 125, 90),
		SailColor = Color3.fromRGB(225, 220, 195),
		MastCount = 2,
		HumansMin = 10,
		HumansMax = 15,
		HealthBonus = 3,
		HasCannon = false,
	},
	{
		Key = "Frigate",
		Name = "Frigate",
		Weight = 22,
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
		Weight = 12,
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
	{
		Key = "ManOfWar",
		Name = "Man-of-War",
		Weight = 6,
		HullSize = Vector3.new(52, 9.5, 19),
		HullColor = Color3.fromRGB(45, 35, 30),
		CabinColor = Color3.fromRGB(70, 55, 45),
		SailColor = Color3.fromRGB(210, 195, 150),
		MastCount = 3,
		HumansMin = 26,
		HumansMax = 36,
		HealthBonus = 24,
		HasCannon = true,
		CannonDamage = 22,
		CannonRange = 75,
		CannonCooldown = 3.5,
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
