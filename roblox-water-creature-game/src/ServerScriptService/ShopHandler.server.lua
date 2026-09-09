-- Server side of the upgrade shop: validates and applies purchases requested
-- by UpgradeShop.client.lua. The client never sets a tier or spends money
-- itself — it only asks, and this script decides.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)
local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)

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
