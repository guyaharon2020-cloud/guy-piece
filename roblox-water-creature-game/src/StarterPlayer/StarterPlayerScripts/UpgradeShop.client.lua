-- A small toggleable shop panel listing the three upgrades (Bite Power,
-- Armor, Fins). Costs/tiers are read directly off the replicated Upgrades
-- folder + leaderstats and computed with the same GameConfig.UpgradeCost
-- formula the server uses, so the UI always matches what a purchase will
-- actually cost. Buying just fires a request at the server — this script
-- never changes money or tiers itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PurchaseUpgradeEvent = Remotes:WaitForChild("PurchaseUpgrade")
local UpgradeResultEvent = Remotes:WaitForChild("UpgradeResult")

local UPGRADE_ORDER = { "AttackPower", "Armor", "SwimSpeed" }

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShop"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ShopToggle"
toggleButton.Size = UDim2.new(0, 110, 0, 40)
toggleButton.Position = UDim2.new(1, -130, 1, -60)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.Text = "Shop"
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 90, 140)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = screenGui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.Size = UDim2.new(0, 360, 0, 250)
frame.Position = UDim2.new(1, -380, 1, -320)
frame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "Upgrades"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

local rowsHolder = Instance.new("Frame")
rowsHolder.Size = UDim2.new(1, -20, 1, -40)
rowsHolder.Position = UDim2.new(0, 10, 0, 36)
rowsHolder.BackgroundTransparency = 1
rowsHolder.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = rowsHolder

toggleButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

local rows = {}

for i, key in ipairs(UPGRADE_ORDER) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 62)
	row.BackgroundColor3 = Color3.fromRGB(35, 48, 68)
	row.LayoutOrder = i
	row.Parent = rowsHolder
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.65, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 10, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.65, 0, 0, 32)
	descLabel.Position = UDim2.new(0, 10, 0, 24)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
	descLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 90, 0, 34)
	buyButton.Position = UDim2.new(1, -100, 0.5, -17)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 15
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
	buyButton.Parent = row
	Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 6)

	buyButton.MouseButton1Click:Connect(function()
		PurchaseUpgradeEvent:FireServer(key)
	end)

	rows[key] = { name = nameLabel, desc = descLabel, buy = buyButton }
end

local upgradesFolder = player:WaitForChild("Upgrades")
local leaderstats = player:WaitForChild("leaderstats")

local function refreshRow(key)
	local upgradeConfig = Config.Upgrades[key]
	local tier = upgradesFolder[key].Value
	local maxed = tier >= upgradeConfig.MaxTier

	local row = rows[key]
	row.name.Text = string.format("%s (Tier %d/%d)", upgradeConfig.Name, tier, upgradeConfig.MaxTier)
	row.desc.Text = upgradeConfig.Description

	if maxed then
		row.buy.Text = "MAXED"
		row.buy.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	else
		local cost = Config.UpgradeCost(key, tier)
		row.buy.Text = "$" .. cost
		local affordable = leaderstats.Money.Value >= cost
		row.buy.BackgroundColor3 = affordable and Color3.fromRGB(40, 140, 80) or Color3.fromRGB(120, 60, 60)
	end
end

local function refreshAll()
	for _, key in ipairs(UPGRADE_ORDER) do
		refreshRow(key)
	end
end

for _, key in ipairs(UPGRADE_ORDER) do
	upgradesFolder[key]:GetPropertyChangedSignal("Value"):Connect(refreshAll)
end
leaderstats.Money:GetPropertyChangedSignal("Value"):Connect(refreshAll)

refreshAll()

UpgradeResultEvent.OnClientEvent:Connect(function(success, reason)
	if success then
		return
	end
	local original = toggleButton.Text
	toggleButton.Text = reason or "Can't buy"
	task.delay(1.2, function()
		toggleButton.Text = original
	end)
end)
