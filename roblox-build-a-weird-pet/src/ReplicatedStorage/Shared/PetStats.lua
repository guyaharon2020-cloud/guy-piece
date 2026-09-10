-- PetStats.lua
-- Slot list + stat computation shared by server (authoritative) and client (previews).

local Rarity = require(script.Parent:WaitForChild("Rarity"))

local PetStats = {}

PetStats.Slots = { "Head", "Body", "Legs", "Eyes", "Special", "Ability" }

PetStats.StatKeys = { "Speed", "Strength", "Jump", "Luck", "Weirdness" }

-- parts: table keyed by slot name -> part definition (see Worlds.lua for shape).
-- mutation: optional mutation definition from Mutations.lua.
-- Returns: stats table, overallRarity string, totalValue number
function PetStats.compute(parts, mutation)
	local stats = {}
	for _, key in ipairs(PetStats.StatKeys) do
		stats[key] = 0
	end

	local rarities = {}
	for _, slot in ipairs(PetStats.Slots) do
		local part = parts[slot]
		if part then
			table.insert(rarities, part.rarity)
			for _, key in ipairs(PetStats.StatKeys) do
				stats[key] += (part.statBonuses and part.statBonuses[key]) or 0
			end
		end
	end

	local overallRarity = Rarity.highest(rarities)
	local rarityMult = Rarity.Info[overallRarity].valueMultiplier

	local statMult = rarityMult
	local valueMult = rarityMult
	if mutation then
		statMult *= mutation.statMultiplier
		valueMult *= mutation.valueMultiplier
	end

	local totalValue = 0
	for _, key in ipairs(PetStats.StatKeys) do
		stats[key] = math.round(stats[key] * statMult * 10) / 10
		totalValue += stats[key]
	end
	totalValue = math.round(totalValue * valueMult)

	return stats, overallRarity, totalValue
end

-- Deterministic id for a part combination, ignoring mutation. Two pets built
-- from the same six parts always produce the same combo id, which is what
-- the Collection Book uses to track "discovered" combinations.
function PetStats.comboId(parts)
	local ids = {}
	for _, slot in ipairs(PetStats.Slots) do
		local part = parts[slot]
		table.insert(ids, part and part.id or "none")
	end
	return table.concat(ids, "|")
end

return PetStats
