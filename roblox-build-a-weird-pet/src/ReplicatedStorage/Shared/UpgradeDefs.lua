-- UpgradeDefs.lua
-- Shared so both UpgradeService (validates purchases) and the client's
-- Upgrades UI (renders names/costs/descriptions) read the same data.

local UpgradeDefs = {}

UpgradeDefs.Definitions = {
	PartGenerator = { name = "Part Generator", maxLevel = 5, baseCost = 50, description = "Lowers the DNA cost to roll parts." },
	Storage = { name = "Storage", maxLevel = 10, baseCost = 75, description = "+15 max stored pets per level." },
	Luck = { name = "Luck", maxLevel = 10, baseCost = 100, description = "Better odds for rare parts & mutations." },
	PetSlots = { name = "Pet Slots", maxLevel = 6, baseCost = 250, description = "+1 equipped pet per level." },
	DNAMultiplier = { name = "DNA Multiplier", maxLevel = 10, baseCost = 150, description = "+10% DNA from challenges per level." },
	CoinMultiplier = { name = "Coin Multiplier", maxLevel = 10, baseCost = 150, description = "+10% Coins from challenges per level." },
}

UpgradeDefs.Order = { "PartGenerator", "Storage", "Luck", "PetSlots", "DNAMultiplier", "CoinMultiplier" }

function UpgradeDefs.costFor(key, level)
	local def = UpgradeDefs.Definitions[key]
	return math.round(def.baseCost * 1.6 ^ (level - 1))
end

return UpgradeDefs
