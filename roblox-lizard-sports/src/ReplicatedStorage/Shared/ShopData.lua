-- Static shop catalog. Pure data so it is safe to require from both
-- the server (source of truth for prices/effects) and the client (UI/display).

local ShopData = {}

-- Skins are cosmetic and mutually exclusive: owning several just lets you switch.
ShopData.Skins = {
	{
		id = "classic_green",
		name = "Classic Green",
		description = "The look every legend starts with.",
		price = 0,
		color = Color3.fromRGB(60, 150, 60),
		material = Enum.Material.SmoothPlastic,
	},
	{
		id = "desert_gecko",
		name = "Desert Gecko",
		description = "Sandy scales for a lizard who means business.",
		price = 150,
		color = Color3.fromRGB(190, 150, 90),
		material = Enum.Material.SmoothPlastic,
	},
	{
		id = "toxic_dart",
		name = "Toxic Dart",
		description = "Bright enough to say 'do not eat me'.",
		price = 650,
		color = Color3.fromRGB(80, 255, 90),
		material = Enum.Material.Neon,
	},
	{
		id = "shadow_monitor",
		name = "Shadow Monitor",
		description = "Mysterious, brooding, still needs sunlight to function.",
		price = 700,
		color = Color3.fromRGB(35, 35, 40),
		material = Enum.Material.SmoothPlastic,
	},
	{
		id = "golden_iguana",
		name = "Golden Iguana",
		description = "Flashy. Expensive. Slightly impractical.",
		price = 800,
		color = Color3.fromRGB(230, 190, 60),
		material = Enum.Material.Metal,
	},
	{
		id = "chameleon_rainbow",
		name = "Chameleon Rainbow",
		description = "Can't decide on one color, so it cycles through all of them.",
		price = 500,
		color = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.SmoothPlastic,
		animated = "rainbow",
	},
	{
		id = "disco_lizard",
		name = "Disco Lizard",
		description = "Every sports arena needs one lizard with a light show.",
		price = 1000,
		color = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		animated = "rainbow",
	},
}

-- Gear is cumulative: every gear item you own applies its bonus permanently.
-- "bonus" keys map directly onto the fields AbilityService reads.
ShopData.Gear = {
	{
		id = "sticky_toe_pads",
		name = "Sticky Toe Pads",
		description = "Rubber dish-washing gloves that stick to anything. Great for walls.",
		price = 300,
		bonus = { climbSpeed = 6 },
	},
	{
		id = "turbo_tail_fins",
		name = "Turbo Tail Fins",
		description = "Tiny propeller fins strapped to the tail. Questionable aerodynamics.",
		price = 350,
		bonus = { sprintSpeed = 5 },
	},
	{
		id = "mega_tongue_gum",
		name = "Mega Tongue Gum",
		description = "A wad of bubblegum that stretches your tongue further than nature intended.",
		price = 400,
		bonus = { tongueRange = 10 },
	},
	{
		id = "sun_visor",
		name = "Sun Visor",
		description = "Tiny sunglasses that somehow focus sunlight instead of blocking it.",
		price = 250,
		bonus = { baskingRate = 1.5 },
	},
	{
		id = "tail_insurance",
		name = "Tail Insurance",
		description = "A tiny insurance policy for your tail. Regrows faster after a close call.",
		price = 450,
		bonus = { tailRegrowReduction = 12 },
	},
	{
		id = "disguise_kit",
		name = "Disguise Kit",
		description = "A fake mustache and a convincing rock costume.",
		price = 500,
		bonus = { camoDuration = 3, camoCooldownReduction = 4 },
	},
	{
		id = "energy_drink_backpack",
		name = "Energy Drink Backpack",
		description = "Mini soda cans strapped to your back. Not FDA approved.",
		price = 550,
		bonus = { staminaMax = 40 },
	},
	{
		id = "lucky_cricket_charm",
		name = "Lucky Cricket Charm",
		description = "A dried cricket for good luck. Weird, but it works.",
		price = 900,
		bonus = { coinMultiplier = 0.25 },
	},
}

function ShopData.findSkin(id)
	for _, item in ipairs(ShopData.Skins) do
		if item.id == id then
			return item
		end
	end
	return nil
end

function ShopData.findGear(id)
	for _, item in ipairs(ShopData.Gear) do
		if item.id == id then
			return item
		end
	end
	return nil
end

-- Looks across both catalogs; returns the item and its category ("Skin"/"Gear").
function ShopData.findAny(id)
	local skin = ShopData.findSkin(id)
	if skin then
		return skin, "Skin"
	end
	local gear = ShopData.findGear(id)
	if gear then
		return gear, "Gear"
	end
	return nil, nil
end

return ShopData
