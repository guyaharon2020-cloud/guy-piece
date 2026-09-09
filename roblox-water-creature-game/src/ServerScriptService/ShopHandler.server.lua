-- Server side of both shops:
--  - the Money-based upgrade shop: validates and applies purchases requested
--    by UpgradeShop.client.lua.
--  - the Robux shop: prompts the real-money purchase dialog and wires up
--    MarketplaceService.ProcessReceipt (see RobuxShop.lua for what's granted
--    and its persistence caveat).
-- The client never sets a tier, spends money, or grants itself a power
-- directly — it only asks, and this script decides.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)
local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)
local RobuxShop = require(ServerScriptService.Modules.RobuxShop)

RobuxShop.SetupReceiptProcessing()

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local PurchaseUpgradeEvent = Remotes:FindFirstChild("PurchaseUpgrade")
if not PurchaseUpgradeEvent then
	PurchaseUpgradeEvent = Instance.new("RemoteEvent")
	PurchaseUpgradeEvent.Name = "PurchaseUpgrade"
	PurchaseUpgradeEvent.Parent = Remotes
end

local UpgradeResultEvent = Remotes:FindFirstChild("UpgradeResult")
if not UpgradeResultEvent then
	UpgradeResultEvent = Instance.new("RemoteEvent")
	UpgradeResultEvent.Name = "UpgradeResult"
	UpgradeResultEvent.Parent = Remotes
end

local PromptRobuxPurchaseEvent = Remotes:FindFirstChild("PromptRobuxPurchase")
if not PromptRobuxPurchaseEvent then
	PromptRobuxPurchaseEvent = Instance.new("RemoteEvent")
	PromptRobuxPurchaseEvent.Name = "PromptRobuxPurchase"
	PromptRobuxPurchaseEvent.Parent = Remotes
end

PurchaseUpgradeEvent.OnServerEvent:Connect(function(player, upgradeKey)
	if typeof(upgradeKey) ~= "string" then
		return
	end

	local success, resultOrReason = PlayerUpgrades.Purchase(player, upgradeKey)
	if success then
		PlayerProgress.ApplyLevelStats(player)
		UpgradeResultEvent:FireClient(player, true)
	else
		UpgradeResultEvent:FireClient(player, false, resultOrReason)
	end
end)

PromptRobuxPurchaseEvent.OnServerEvent:Connect(function(player, productKey)
	if typeof(productKey) ~= "string" then
		return
	end

	RobuxShop.PromptPurchase(player, productKey)
end)
