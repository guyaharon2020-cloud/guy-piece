-- Server side of all three shop tabs:
--  - Upgrades (Money): validates and applies purchases requested by
--    UpgradeShop.client.lua.
--  - Creatures (Money): buys permanent access to a non-starter species
--    (see PlayerSpecies.lua) — doesn't select it, just unlocks it for the
--    portal/species-select panel.
--  - Robux Shop: prompts the real-money purchase dialog and wires up
--    MarketplaceService.ProcessReceipt (see RobuxShop.lua for what's granted
--    and its persistence caveat).
-- The client never sets a tier, spends money, or grants itself a power or
-- species directly — it only asks, and this script decides.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)
local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)
local RobuxShop = require(ServerScriptService.Modules.RobuxShop)
local PlayerSpecies = require(ServerScriptService.Modules.PlayerSpecies)

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

local PurchaseSpeciesEvent = Remotes:FindFirstChild("PurchaseSpecies")
if not PurchaseSpeciesEvent then
	PurchaseSpeciesEvent = Instance.new("RemoteEvent")
	PurchaseSpeciesEvent.Name = "PurchaseSpecies"
	PurchaseSpeciesEvent.Parent = Remotes
end

local SpeciesResultEvent = Remotes:FindFirstChild("SpeciesResult")
if not SpeciesResultEvent then
	SpeciesResultEvent = Instance.new("RemoteEvent")
	SpeciesResultEvent.Name = "SpeciesResult"
	SpeciesResultEvent.Parent = Remotes
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

PurchaseSpeciesEvent.OnServerEvent:Connect(function(player, speciesKey)
	if typeof(speciesKey) ~= "string" then
		return
	end

	local success, resultOrReason = PlayerSpecies.Purchase(player, speciesKey)
	SpeciesResultEvent:FireClient(player, success, success and nil or resultOrReason)
end)
