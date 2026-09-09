-- The "Robux Shop": real-money super powers bought via MarketplaceService
-- Developer Products. See GameConfig.RobuxProducts — every ProductId there
-- is a placeholder (0) until you create the matching Developer Product in
-- Studio's Monetization tab (requires a published place) and paste its real
-- ID in.
--
-- NOTE ON PERSISTENCE: this project has no DataStore layer yet (see
-- README), so everything granted here — Depth Charges, Golden Scales, Money/
-- XP boosts — lives only for the current server session. Before shipping
-- this with real purchases, add DataStore-backed saving AND record
-- processed receipts in it, so a retried receipt after a crash/restart is
-- never silently dropped or double-granted.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local CreatureAppearance = require(script.Parent.CreatureAppearance)

local RobuxShop = {}

-- Temporary Money/XP boosts, kept in memory only (see note above).
local activeBoosts = {}

function RobuxShop.Init(player)
	if player:FindFirstChild("Consumables") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Consumables"

	local depthCharges = Instance.new("IntValue")
	depthCharges.Name = "DepthCharges"
	depthCharges.Value = 0
	depthCharges.Parent = folder

	local goldenScales = Instance.new("BoolValue")
	goldenScales.Name = "GoldenScales"
	goldenScales.Value = false
	goldenScales.Parent = folder

	folder.Parent = player
end

function RobuxShop.GetActiveMultiplier(player, boostType)
	local boosts = activeBoosts[player]
	local boost = boosts and boosts[boostType]
	if not boost then
		return 1
	end

	if os.clock() > boost.expiresAt then
		boosts[boostType] = nil
		return 1
	end

	return boost.multiplier
end

function RobuxShop.ConsumeDepthCharge(player)
	local consumables = player:FindFirstChild("Consumables")
	local depthCharges = consumables and consumables:FindFirstChild("DepthCharges")
	if not depthCharges or depthCharges.Value <= 0 then
		return false
	end

	depthCharges.Value -= 1
	return true
end

local function findProductByProductId(productId)
	for _, product in ipairs(Config.RobuxProducts) do
		if product.ProductId == productId then
			return product
		end
	end
	return nil
end

function RobuxShop.FindProductByKey(key)
	for _, product in ipairs(Config.RobuxProducts) do
		if product.Key == key then
			return product
		end
	end
	return nil
end

local function grantProduct(player, product)
	local consumables = player:FindFirstChild("Consumables")
	if not consumables then
		return
	end

	if product.Kind == "Boost" then
		activeBoosts[player] = activeBoosts[player] or {}
		activeBoosts[player][product.BoostType] = {
			multiplier = product.Multiplier,
			expiresAt = os.clock() + product.DurationSeconds,
		}
	elseif product.Kind == "Consumable" then
		consumables.DepthCharges.Value += product.Charges
	elseif product.Kind == "Permanent" then
		consumables.GoldenScales.Value = true
		CreatureAppearance.Apply(player)
	end
end

function RobuxShop.PromptPurchase(player, productKey)
	local product = RobuxShop.FindProductByKey(productKey)
	if not product then
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.ProductId)
end

function RobuxShop.SetupReceiptProcessing()
	Players.PlayerRemoving:Connect(function(player)
		activeBoosts[player] = nil
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Player isn't in the game (e.g. left mid-purchase). Ask Roblox
			-- to retry later rather than losing the receipt.
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local product = findProductByProductId(receiptInfo.ProductId)
		if not product then
			warn("RobuxShop: purchase for an unconfigured ProductId " .. tostring(receiptInfo.ProductId))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		grantProduct(player, product)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return RobuxShop
