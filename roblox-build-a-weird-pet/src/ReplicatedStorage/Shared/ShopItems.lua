-- ShopItems.lua
-- Shared so both ShopService (validates purchases) and the client's Shop UI
-- (renders the catalog) read the same data.

local ShopItems = {}

ShopItems.List = {
	{ id = "trail_sparkle", name = "Sparkle Trail", type = "Trail", currency = "Coins", price = 500, color = Color3.fromRGB(255, 255, 255) },
	{ id = "trail_fire", name = "Fire Trail", type = "Trail", currency = "Coins", price = 1500, color = Color3.fromRGB(255, 120, 40) },
	{ id = "trail_rainbow", name = "Rainbow Trail", type = "Trail", currency = "DNA", price = 800, rainbow = true },
	{ id = "trail_shadow", name = "Shadow Trail", type = "Trail", currency = "Mutations", price = 15, color = Color3.fromRGB(20, 20, 25) },

	{ id = "namecolor_gold", name = "Gold Name", type = "NameColor", currency = "Coins", price = 1000, color = Color3.fromRGB(255, 215, 60) },
	{ id = "namecolor_toxic", name = "Toxic Name", type = "NameColor", currency = "Coins", price = 2500, color = Color3.fromRGB(140, 255, 60) },
	{ id = "namecolor_rainbow", name = "Rainbow Name", type = "NameColor", currency = "Mutations", price = 25, rainbow = true },

	{ id = "emote_wave", name = "Wave Emote", type = "Emote", currency = "Coins", price = 200 },
	{ id = "emote_dance", name = "Dance Emote", type = "Emote", currency = "Coins", price = 600 },
}

ShopItems.ById = {}
for _, item in ipairs(ShopItems.List) do
	ShopItems.ById[item.id] = item
end

return ShopItems
