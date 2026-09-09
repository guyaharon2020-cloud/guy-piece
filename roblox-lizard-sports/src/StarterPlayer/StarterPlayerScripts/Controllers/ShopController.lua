-- Builds the shop UI (hidden until the kiosk's ProximityPrompt fires) and
-- lists every skin/gear item from the shared ShopData catalog with a
-- Buy/Equip/Owned button whose state follows the player's live profile.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShopData = require(ReplicatedStorage.Shared.ShopData)

local ShopController = {}

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function buildRow(scrolling, item, category, order, remotes, PlayerState)
	local row = create("Frame", {
		Name = item.id,
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = Color3.fromRGB(40, 40, 46),
		LayoutOrder = order,
	}, scrolling)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)

	create("TextLabel", {
		Size = UDim2.new(0.55, 0, 0, 24),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = item.name,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	create("TextLabel", {
		Size = UDim2.new(0.55, 0, 0, 32),
		Position = UDim2.new(0, 10, 0, 30),
		BackgroundTransparency = 1,
		Text = item.description,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(190, 190, 190),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, row)

	local actionButton = create("TextButton", {
		Size = UDim2.new(0, 120, 0, 40),
		Position = UDim2.new(1, -130, 0.5, -20),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}, row)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, actionButton)

	local function ownsItem(profile)
		if category == "Skin" then
			return profile.OwnedSkins[item.id] == true
		end
		return profile.OwnedGear[item.id] == true
	end

	local function refresh(profile)
		profile = profile or PlayerState.GetProfile()
		if not profile then
			return
		end
		local owned = ownsItem(profile)

		if category == "Skin" and owned and profile.EquippedSkin == item.id then
			actionButton.Text = "Equipped"
			actionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
			actionButton.Active = false
		elseif category == "Skin" and owned then
			actionButton.Text = "Equip"
			actionButton.BackgroundColor3 = Color3.fromRGB(70, 140, 220)
			actionButton.Active = true
		elseif owned then
			actionButton.Text = "Owned"
			actionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
			actionButton.Active = false
		else
			actionButton.Text = item.price .. " coins"
			actionButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
			actionButton.Active = true
		end
	end

	actionButton.MouseButton1Click:Connect(function()
		local profile = PlayerState.GetProfile()
		if not profile then
			return
		end
		if ownsItem(profile) then
			if category == "Skin" then
				remotes.EquipSkin:FireServer(item.id)
			end
		else
			remotes.PurchaseItem:FireServer(item.id)
		end
	end)

	PlayerState.OnProfileChanged(refresh)
	refresh()
end

function ShopController.Init(remotes, PlayerState)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = create("ScreenGui", {
		Name = "LizardShop",
		ResetOnSpawn = false,
		Enabled = false,
	}, playerGui)

	local frame = create("Frame", {
		Name = "ShopFrame",
		Size = UDim2.new(0, 480, 0, 420),
		Position = UDim2.new(0.5, -240, 0.5, -210),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, frame)

	create("TextLabel", {
		Size = UDim2.new(1, -60, 0, 40),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = "Lizard Shop",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	local closeButton = create("TextButton", {
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -42, 0, 8),
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(180, 60, 60),
	}, frame)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, closeButton)
	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	local scrolling = create("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -60),
		Position = UDim2.new(0, 10, 0, 52),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
	}, frame)

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scrolling)

	local order = 0
	for _, item in ipairs(ShopData.Skins) do
		order += 1
		buildRow(scrolling, item, "Skin", order, remotes, PlayerState)
	end
	for _, item in ipairs(ShopData.Gear) do
		order += 1
		buildRow(scrolling, item, "Gear", order, remotes, PlayerState)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "ShopPrompt" then
			screenGui.Enabled = true
		end
	end)
end

return ShopController
