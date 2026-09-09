-- A toggleable shop panel with two tabs:
--  - "Upgrades": the six Money-based upgrades. Costs/tiers are read
--    directly off the replicated Upgrades folder + leaderstats and computed
--    with the same GameConfig.UpgradeCost formula the server uses, so the
--    UI always matches what a purchase will actually cost.
--  - "Robux Shop": the four real-money super powers. Buying just fires a
--    request at the server, which prompts Roblox's own purchase dialog —
--    this script never grants anything itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PurchaseUpgradeEvent = Remotes:WaitForChild("PurchaseUpgrade")
local UpgradeResultEvent = Remotes:WaitForChild("UpgradeResult")
local PromptRobuxPurchaseEvent = Remotes:WaitForChild("PromptRobuxPurchase")

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
frame.Size = UDim2.new(0, 400, 0, 420)
frame.Position = UDim2.new(1, -420, 1, -490)
frame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

toggleButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 34)
tabBar.Position = UDim2.new(0, 10, 0, 8)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local upgradesTabButton = Instance.new("TextButton")
upgradesTabButton.Size = UDim2.new(0, 185, 1, 0)
upgradesTabButton.Font = Enum.Font.GothamBold
upgradesTabButton.TextSize = 16
upgradesTabButton.Text = "Upgrades"
upgradesTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradesTabButton.Parent = tabBar
Instance.new("UICorner", upgradesTabButton).CornerRadius = UDim.new(0, 6)

local robuxTabButton = Instance.new("TextButton")
robuxTabButton.Size = UDim2.new(0, 185, 1, 0)
robuxTabButton.Font = Enum.Font.GothamBold
robuxTabButton.TextSize = 16
robuxTabButton.Text = "Robux Shop"
robuxTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
robuxTabButton.Parent = tabBar
Instance.new("UICorner", robuxTabButton).CornerRadius = UDim.new(0, 6)

local upgradesPage = Instance.new("ScrollingFrame")
upgradesPage.Size = UDim2.new(1, -20, 1, -52)
upgradesPage.Position = UDim2.new(0, 10, 0, 48)
upgradesPage.BackgroundTransparency = 1
upgradesPage.BorderSizePixel = 0
upgradesPage.ScrollBarThickness = 6
upgradesPage.CanvasSize = UDim2.new(0, 0, 0, 0)
upgradesPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
upgradesPage.Parent = frame

local upgradesLayout = Instance.new("UIListLayout")
upgradesLayout.Padding = UDim.new(0, 8)
upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
upgradesLayout.Parent = upgradesPage

local robuxPage = Instance.new("ScrollingFrame")
robuxPage.Size = UDim2.new(1, -20, 1, -52)
robuxPage.Position = UDim2.new(0, 10, 0, 48)
robuxPage.BackgroundTransparency = 1
robuxPage.BorderSizePixel = 0
robuxPage.ScrollBarThickness = 6
robuxPage.CanvasSize = UDim2.new(0, 0, 0, 0)
robuxPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
robuxPage.Visible = false
robuxPage.Parent = frame

local robuxLayout = Instance.new("UIListLayout")
robuxLayout.Padding = UDim.new(0, 8)
robuxLayout.SortOrder = Enum.SortOrder.LayoutOrder
robuxLayout.Parent = robuxPage

local function setActiveTab(name)
	local upgradesActive = name == "Upgrades"
	upgradesPage.Visible = upgradesActive
	robuxPage.Visible = not upgradesActive
	upgradesTabButton.BackgroundColor3 = upgradesActive and Color3.fromRGB(30, 90, 140) or Color3.fromRGB(40, 48, 60)
	robuxTabButton.BackgroundColor3 = (not upgradesActive) and Color3.fromRGB(140, 100, 20) or Color3.fromRGB(40, 48, 60)
end

upgradesTabButton.MouseButton1Click:Connect(function()
	setActiveTab("Upgrades")
end)
robuxTabButton.MouseButton1Click:Connect(function()
	setActiveTab("Robux")
end)
setActiveTab("Upgrades")

-- Upgrade rows
local upgradeRows = {}

for i, key in ipairs(Config.UpgradeOrder) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 62)
	row.BackgroundColor3 = Color3.fromRGB(35, 48, 68)
	row.LayoutOrder = i
	row.Parent = upgradesPage
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

	upgradeRows[key] = { name = nameLabel, desc = descLabel, buy = buyButton }
end

local upgradesFolder = player:WaitForChild("Upgrades")
local leaderstats = player:WaitForChild("leaderstats")

local function refreshUpgradeRow(key)
	local upgradeConfig = Config.Upgrades[key]
	local tier = upgradesFolder[key].Value
	local maxed = tier >= upgradeConfig.MaxTier

	local row = upgradeRows[key]
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

local function refreshAllUpgradeRows()
	for _, key in ipairs(Config.UpgradeOrder) do
		refreshUpgradeRow(key)
	end
end

for _, key in ipairs(Config.UpgradeOrder) do
	upgradesFolder[key]:GetPropertyChangedSignal("Value"):Connect(refreshAllUpgradeRows)
end
leaderstats.Money:GetPropertyChangedSignal("Value"):Connect(refreshAllUpgradeRows)

refreshAllUpgradeRows()

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

-- Robux rows
for i, product in ipairs(Config.RobuxProducts) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 68)
	row.BackgroundColor3 = Color3.fromRGB(50, 42, 25)
	row.LayoutOrder = i
	row.Parent = robuxPage
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.65, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 10, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 130)
	nameLabel.Text = product.Name
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.65, 0, 0, 38)
	descLabel.Position = UDim2.new(0, 10, 0, 24)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(210, 205, 190)
	descLabel.Text = product.Description
	descLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 90, 0, 34)
	buyButton.Position = UDim2.new(1, -100, 0.5, -17)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 14
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.BackgroundColor3 = Color3.fromRGB(140, 100, 20)
	buyButton.Text = product.DisplayPriceHint or "Buy"
	buyButton.Parent = row
	Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 6)

	buyButton.MouseButton1Click:Connect(function()
		PromptRobuxPurchaseEvent:FireServer(product.Key)
	end)
end
