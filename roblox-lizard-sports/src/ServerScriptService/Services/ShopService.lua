-- Validates and applies PurchaseItem / EquipSkin requests from clients.
-- The server is the only source of truth for prices and ownership;
-- the client only ever sends an item id.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopData = require(ReplicatedStorage.Shared.ShopData)

local DataService = require(script.Parent.DataService)
local LizardBuilder = require(script.Parent.LizardBuilder)

local ShopService = {}

local function ownsItem(profile, category, id)
	if category == "Skin" then
		return profile.OwnedSkins[id] == true
	else
		return profile.OwnedGear[id] == true
	end
end

local function grantItem(profile, category, id)
	if category == "Skin" then
		profile.OwnedSkins[id] = true
	else
		profile.OwnedGear[id] = true
	end
end

local function handlePurchase(player, itemId)
	if type(itemId) ~= "string" then
		return
	end

	local profile = DataService.Get(player)
	if not profile then
		return
	end

	local item, category = ShopData.findAny(itemId)
	if not item then
		return
	end

	if ownsItem(profile, category, itemId) then
		return -- already owned, nothing to do
	end

	if profile.Coins < item.price then
		return -- not enough coins, silently ignore (client shows the price up front)
	end

	profile.Coins -= item.price
	grantItem(profile, category, itemId)
	DataService.Push(player)
end

local function handleEquipSkin(player, skinId)
	if type(skinId) ~= "string" then
		return
	end

	local profile = DataService.Get(player)
	if not profile then
		return
	end

	if not profile.OwnedSkins[skinId] then
		return -- can't equip what you don't own
	end

	profile.EquippedSkin = skinId
	DataService.Push(player)

	local character = player.Character
	if character then
		LizardBuilder.ApplySkin(character, skinId)
	end
end

-- Sums every owned gear item's bonus fields into one flat table, e.g.
-- { climbSpeed = 6, sprintSpeed = 5, coinMultiplier = 0.25 }.
function ShopService.GetBonuses(player)
	local profile = DataService.Get(player)
	local bonuses = {}
	if not profile then
		return bonuses
	end

	for gearId in pairs(profile.OwnedGear) do
		local gear = ShopData.findGear(gearId)
		if gear then
			for key, value in pairs(gear.bonus) do
				bonuses[key] = (bonuses[key] or 0) + value
			end
		end
	end

	return bonuses
end

function ShopService.Init(remotes)
	remotes.PurchaseItem.OnServerEvent:Connect(handlePurchase)
	remotes.EquipSkin.OnServerEvent:Connect(handleEquipSkin)
end

return ShopService
