-- A toggleable shop panel with three tabs:
--  - "Upgrades": the six Money-based stat upgrades. Costs/tiers are read
--    directly off the replicated Upgrades folder + leaderstats and computed
--    with the same GameConfig.UpgradeCost formula the server uses, so the
--    UI always matches what a purchase will actually cost.
--  - "Creatures": buy permanent access to non-starter species (Dolphin
--    etc.) with Money. Doesn't select the species — that happens at the
--    sky-spawn portal (see SpeciesSelect.client.lua) — this just unlocks it.
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
local PurchaseSpeciesEvent = Remotes:WaitForChild("PurchaseSpecies")
local SpeciesResultEvent = Remotes:WaitForChild("SpeciesResult")

local UPGRADE_ICONS = {
	AttackPower = "⚔️",
	Vitality = "❤️",
	Armor = "🛡️",
	SwimSpeed = "🐟",
	MoneyBoost = "💰",
	XPBoost = "✨",
}

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShop"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ShopToggle"
toggleButton.Size = UDim2.new(0, 120, 0, 44)
toggleButton.Position = UDim2.new(1, -140, 1, -64)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.Text = "🛒 Shop"
toggleButton.BackgroundColor3 = Color3.fromRGB(25, 100, 150)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.AutoButtonColor = false
toggleButton.Parent = screenGui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 10)

local toggleGradient = Instance.new("UIGradient")
toggleGradient.Color = ColorSequence.new(Color3.fromRGB(40, 130, 190), Color3.fromRGB(20, 80, 130))
toggleGradient.Rotation = 90
toggleGradient.Parent = toggleButton

toggleButton.MouseEnter:Connect(function()
	toggleButton.BackgroundColor3 = Color3.fromRGB(35, 120, 175)
end)
toggleButton.MouseLeave:Connect(function()
	toggleButton.BackgroundColor3 = Color3.fromRGB(25, 100, 150)
end)

local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.Size = UDim2.new(0, 420, 0, 470)
frame.Position = UDim2.new(1, -440, 1, -540)
frame.BackgroundColor3 = Color3.fromRGB(16, 26, 40)
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(60, 110, 150)
frameStroke.Thickness = 1.5
frameStroke.Transparency = 0.3
frameStroke.Parent = frame

toggleButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- Header: title + live Money readout.
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(22, 38, 58)
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerFix = Instance.new("Frame") -- covers the bottom corners so only the top is rounded
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = Color3.fromRGB(22, 38, 58)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Shop"
titleLabel.Parent = header

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.4, -16, 1, 0)
moneyLabel.Position = UDim2.new(0.6, 0, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextSize = 18
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
moneyLabel.TextColor3 = Color3.fromRGB(120, 230, 150)
moneyLabel.Text = "$0"
moneyLabel.Parent = header

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 58)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabBar

local TAB_NAMES = { "Upgrades", "Creatures", "Robux" }
local tabButtons = {}

for _, tabName in ipairs(TAB_NAMES) do
	local tabButton = Instance.new("TextButton")
	tabButton.Size = UDim2.new(0, 128, 1, 0)
	tabButton.Font = Enum.Font.GothamBold
	tabButton.TextSize = 15
	tabButton.Text = tabName
	tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabButton.AutoButtonColor = false
	tabButton.Parent = tabBar
	Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)
	tabButtons[tabName] = tabButton
end

-- Pages
local function createPage()
	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -20, 1, -106)
	page.Position = UDim2.new(0, 10, 0, 100)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 6
	page.ScrollBarImageColor3 = Color3.fromRGB(80, 140, 180)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	return page
end

local upgradesPage = createPage()
local creaturesPage = createPage()
local robuxPage = createPage()
local pages = { Upgrades = upgradesPage, Creatures = creaturesPage, Robux = robuxPage }

local function setActiveTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = tabName == name
	end
	for tabName, button in pairs(tabButtons) do
		button.BackgroundColor3 = tabName == name and Color3.fromRGB(30, 110, 165) or Color3.fromRGB(35, 48, 68)
	end
end

for tabName, button in pairs(tabButtons) do
	button.MouseButton1Click:Connect(function()
		setActiveTab(tabName)
	end)
end
setActiveTab("Upgrades")

-- Generic "card row" builder shared by all three tabs: an icon/swatch, a
-- title + description, and a buy/status button on the right.
local function createCard(parent, layoutOrder, accentColor)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 64)
	card.BackgroundColor3 = Color3.fromRGB(26, 42, 62)
	card.LayoutOrder = layoutOrder
	card.Parent = parent
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, -16)
	accent.Position = UDim2.new(0, 0, 0, 8)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.62, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 16, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.62, 0, 0, 32)
	descLabel.Position = UDim2.new(0, 16, 0, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(190, 205, 220)
	descLabel.Parent = card

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 96, 0, 36)
	buyButton.Position = UDim2.new(1, -108, 0.5, -18)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 14
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.AutoButtonColor = false
	buyButton.Parent = card
	Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 8)

	return card, nameLabel, descLabel, buyButton
end

-- Upgrades tab
local upgradeRows = {}

for i, key in ipairs(Config.UpgradeOrder) do
	local upgradeConfig = Config.Upgrades[key]
	local _, nameLabel, descLabel, buyButton = createCard(upgradesPage, i, Color3.fromRGB(70, 160, 210))
	descLabel.Text = upgradeConfig.Description

	buyButton.MouseButton1Click:Connect(function()
		PurchaseUpgradeEvent:FireServer(key)
	end)

	upgradeRows[key] = { name = nameLabel, buy = buyButton }
end

local upgradesFolder = player:WaitForChild("Upgrades")
local leaderstats = player:WaitForChild("leaderstats")

local function refreshUpgradeRow(key)
	local upgradeConfig = Config.Upgrades[key]
	local tier = upgradesFolder[key].Value
	local maxed = tier >= upgradeConfig.MaxTier

	local row = upgradeRows[key]
	local icon = UPGRADE_ICONS[key] or ""
	row.name.Text = string.format("%s %s  (Tier %d/%d)", icon, upgradeConfig.Name, tier, upgradeConfig.MaxTier)

	if maxed then
		row.buy.Text = "MAXED"
		row.buy.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
	else
		local cost = Config.UpgradeCost(key, tier)
		row.buy.Text = "$" .. cost
		local affordable = leaderstats.Money.Value >= cost
		row.buy.BackgroundColor3 = affordable and Color3.fromRGB(45, 155, 95) or Color3.fromRGB(130, 65, 65)
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

-- Creatures tab
local speciesFolder = player:WaitForChild("Species")
local creatureRows = {}

local layoutOrder = 0
for _, key in ipairs(Config.SpeciesOrder) do
	local species = Config.Species[key]
	if species.ShopCost > 0 then
		layoutOrder += 1
		local previewColor = species.Tiers[1].Color
		local _, nameLabel, descLabel, buyButton = createCard(creaturesPage, layoutOrder, previewColor)
		nameLabel.Text = "🐬 " .. species.Name
		descLabel.Text = "Unlock a whole new creature line to pick at the portal."

		buyButton.MouseButton1Click:Connect(function()
			PurchaseSpeciesEvent:FireServer(key)
		end)

		creatureRows[key] = { buy = buyButton }
	end
end

local function refreshCreatureRow(key)
	local species = Config.Species[key]
	local row = creatureRows[key]
	if not row then
		return
	end

	local ownedValue = speciesFolder:FindFirstChild(key)
	local owned = ownedValue and ownedValue.Value

	if owned then
		row.buy.Text = "Owned"
		row.buy.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
	else
		row.buy.Text = "$" .. species.ShopCost
		local affordable = leaderstats.Money.Value >= species.ShopCost
		row.buy.BackgroundColor3 = affordable and Color3.fromRGB(45, 155, 95) or Color3.fromRGB(130, 65, 65)
	end
end

local function refreshAllCreatureRows()
	for key in pairs(creatureRows) do
		refreshCreatureRow(key)
	end
end

for key in pairs(creatureRows) do
	local ownedValue = speciesFolder:FindFirstChild(key)
	if ownedValue then
		ownedValue:GetPropertyChangedSignal("Value"):Connect(refreshAllCreatureRows)
	end
end

leaderstats.Money:GetPropertyChangedSignal("Value"):Connect(function()
	refreshAllUpgradeRows()
	refreshAllCreatureRows()
	moneyLabel.Text = "$" .. leaderstats.Money.Value
end)

refreshAllUpgradeRows()
refreshAllCreatureRows()
moneyLabel.Text = "$" .. leaderstats.Money.Value

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

SpeciesResultEvent.OnClientEvent:Connect(function(success, reason)
	if success then
		return
	end
	local original = toggleButton.Text
	toggleButton.Text = reason or "Can't buy"
	task.delay(1.2, function()
		toggleButton.Text = original
	end)
end)

-- Robux tab
for i, product in ipairs(Config.RobuxProducts) do
	local _, nameLabel, descLabel, buyButton = createCard(robuxPage, i, Color3.fromRGB(220, 180, 60))
	nameLabel.Text = product.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 225, 150)
	descLabel.Text = product.Description
	buyButton.Text = product.DisplayPriceHint or "Buy"
	buyButton.BackgroundColor3 = Color3.fromRGB(150, 110, 20)

	buyButton.MouseButton1Click:Connect(function()
		PromptRobuxPurchaseEvent:FireServer(product.Key)
	end)
end
