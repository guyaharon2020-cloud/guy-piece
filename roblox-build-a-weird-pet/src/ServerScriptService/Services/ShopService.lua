-- ShopService.lua
-- Purely cosmetic shop (trails, emotes, name colors) so the game stays
-- fully playable without spending Robux. Buying an item immediately equips
-- it -- owning a second item of the same type just swaps which is active.
-- Actually rendering the cosmetic (Trail instance, name color, emote
-- animation) happens client-side in ShopController, driven by
-- profile.EquippedCosmetics from ProfileUpdated/GetInitialProfile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local ShopItems = require(Shared:WaitForChild("ShopItems"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local ShopService = {}

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
	local item = ShopItems.ById[itemId]
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

function ShopService.init()
	Remotes.Event.BuyShopItem.OnServerEvent:Connect(onBuyShopItem)
end

return ShopService
