-- Rarity.lua
-- Central definition of pet/part rarity tiers, ordered weakest to strongest.

local Rarity = {}

Rarity.Order = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

Rarity.Info = {
	Common = { weight = 1000, color = Color3.fromRGB(190, 190, 190), valueMultiplier = 1 },
	Uncommon = { weight = 500, color = Color3.fromRGB(90, 200, 90), valueMultiplier = 1.5 },
	Rare = { weight = 200, color = Color3.fromRGB(70, 140, 240), valueMultiplier = 2.5 },
	Epic = { weight = 75, color = Color3.fromRGB(170, 80, 230), valueMultiplier = 4 },
	Legendary = { weight = 25, color = Color3.fromRGB(240, 180, 40), valueMultiplier = 7 },
	Mythic = { weight = 7, color = Color3.fromRGB(240, 60, 60), valueMultiplier = 12 },
	Secret = { weight = 1, color = Color3.fromRGB(20, 20, 20), valueMultiplier = 25 },
}

local rankByName = {}
for index, name in ipairs(Rarity.Order) do
	rankByName[name] = index
end

-- Returns 1 for Common .. #Order for Secret. Used to compare two rarities.
function Rarity.rank(name)
	return rankByName[name] or 1
end

-- Given a list of rarity names (e.g. one per body part), returns the
-- highest rarity among them. A pet is only as "common" as its rarest part.
function Rarity.highest(names)
	local best = "Common"
	for _, name in ipairs(names) do
		if Rarity.rank(name) > Rarity.rank(best) then
			best = name
		end
	end
	return best
end

-- Weighted random pick from a list of { rarity = "Common", ... } entries.
-- `luckMultiplier` >= 1 skews the roll toward rarer entries.
function Rarity.weightedPick(entries, luckMultiplier)
	luckMultiplier = luckMultiplier or 1

	local totalWeight = 0
	local weights = table.create(#entries)
	for i, entry in ipairs(entries) do
		local base = Rarity.Info[entry.rarity].weight
		-- Higher luck raises the effective weight of rarer (lower base weight) entries.
		local boosted = base ^ (1 / luckMultiplier)
		weights[i] = boosted
		totalWeight += boosted
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for i, entry in ipairs(entries) do
		cursor += weights[i]
		if roll <= cursor then
			return entry
		end
	end
	return entries[#entries]
end

return Rarity
