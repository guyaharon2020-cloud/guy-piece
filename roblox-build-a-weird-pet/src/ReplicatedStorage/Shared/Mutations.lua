-- Mutations.lua
-- Rare visual/stat modifiers that can be rolled onto any freshly created pet.

local Mutations = {}

-- rollChance is "out of 100000" so we can express very small odds precisely.
-- statMultiplier applies to every stat on the pet. valueMultiplier applies to
-- the pet's DNA/collection value on top of its rarity multiplier.
Mutations.List = {
	{
		id = "Giant",
		name = "Giant",
		rollChance = 4000,
		statMultiplier = 1.25,
		valueMultiplier = 2,
		scale = 1.6,
		color = nil,
		material = nil,
	},
	{
		id = "Tiny",
		name = "Tiny",
		rollChance = 4000,
		statMultiplier = 1.1,
		valueMultiplier = 2,
		scale = 0.55,
		color = nil,
		material = nil,
	},
	{
		id = "Glowing",
		name = "Glowing",
		rollChance = 2500,
		statMultiplier = 1.3,
		valueMultiplier = 3,
		scale = 1,
		color = nil,
		material = Enum.Material.Neon,
	},
	{
		id = "Metallic",
		name = "Metallic",
		rollChance = 1500,
		statMultiplier = 1.5,
		valueMultiplier = 4,
		scale = 1,
		color = Color3.fromRGB(200, 200, 210),
		material = Enum.Material.Metal,
	},
	{
		id = "Rainbow",
		name = "Rainbow",
		rollChance = 600,
		statMultiplier = 1.75,
		valueMultiplier = 6,
		scale = 1,
		color = nil, -- handled specially: cycles hue over time
		material = Enum.Material.Neon,
		rainbow = true,
	},
	{
		id = "Shadow",
		name = "Shadow",
		rollChance = 300,
		statMultiplier = 2,
		valueMultiplier = 8,
		scale = 1.05,
		color = Color3.fromRGB(15, 15, 20),
		material = Enum.Material.SmoothPlastic,
	},
	{
		id = "Crystal",
		name = "Crystal",
		rollChance = 150,
		statMultiplier = 2.5,
		valueMultiplier = 12,
		scale = 1,
		color = Color3.fromRGB(150, 220, 255),
		material = Enum.Material.Glass,
	},
	{
		id = "Glitched",
		name = "Glitched",
		rollChance = 40,
		statMultiplier = 3.5,
		valueMultiplier = 20,
		scale = 1,
		color = Color3.fromRGB(0, 0, 0),
		material = Enum.Material.Neon,
		glitch = true,
	},
}

local ROLL_DENOMINATOR = 100000

-- Rolls at most one mutation. `luckMultiplier` >= 1 improves odds proportionally.
function Mutations.roll(luckMultiplier)
	luckMultiplier = luckMultiplier or 1
	-- Iterate rarest-first so multiple simultaneously-eligible rolls favor the rarer one.
	local ordered = table.clone(Mutations.List)
	table.sort(ordered, function(a, b)
		return a.rollChance < b.rollChance
	end)

	for _, mutation in ipairs(ordered) do
		local chance = mutation.rollChance * luckMultiplier
		if math.random(1, ROLL_DENOMINATOR) <= chance then
			return mutation
		end
	end
	return nil
end

function Mutations.get(id)
	if not id then
		return nil
	end
	for _, mutation in ipairs(Mutations.List) do
		if mutation.id == id then
			return mutation
		end
	end
	return nil
end

return Mutations
