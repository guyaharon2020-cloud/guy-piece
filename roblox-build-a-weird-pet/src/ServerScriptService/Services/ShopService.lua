-- ShopService.lua
-- Purely cosmetic shop (trails, emotes, name colors) so the game stays
-- fully playable without spending Robux. Buying an item immediately equips
-- it -- owning a second item of the same type just swaps which is active.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local ShopService = {}

ShopService.Items = {
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

local byId = {}
for _, item in ipairs(ShopService.Items) do
	byId[item.id] = item
end

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = {
		Coins = profile.Coins,
		DNA = profile.DNA,
		Mutations = profile.Mutations,
		ShopItemsOwned = profile.ShopItemsOwned,
		EquippedCosmetics = profile.EquippedCosmetics,
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

local function onBuyShopItem(player, itemId)
	local profile = DataService.Get(player)
	local item = byId[itemId]
	if not profile or not item then
		return
	end

	if not profile.ShopItemsOwned[itemId] then
		local balance = profile[item.currency]
		if not balance or balance < item.price then
			pushProfile(player, { Error = "Not enough " .. item.currency })
			return
		end
		profile[item.currency] = balance - item.price
		profile.ShopItemsOwned[itemId] = true
	end

	profile.EquippedCosmetics[item.type] = itemId
	pushProfile(player)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Cosmetic trail rendering hook: kept intentionally minimal here --
		-- a full Trail instance needs two Attachments on the character,
		-- which the client sets up in ShopController using the equipped
		-- cosmetic id it receives from GetInitialProfile/ProfileUpdated.
	end)
end)

function ShopService.init()
	Remotes.Event.BuyShopItem.OnServerEvent:Connect(onBuyShopItem)
end

return ShopService
