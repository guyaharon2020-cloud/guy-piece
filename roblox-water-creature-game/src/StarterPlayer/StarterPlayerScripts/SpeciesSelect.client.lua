-- The species-choice panel shown when you touch the sky-spawn portal.
-- Lists every species in Config.SpeciesOrder; owned ones (always the free
-- starters, plus anything bought in the shop's Creatures tab) get a
-- "Choose" button, locked ones show their shop cost instead. Choosing just
-- fires a request at the server — SkySpawn.server.lua validates ownership
-- and does the actual teleport.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PromptSpeciesSelectEvent = Remotes:WaitForChild("PromptSpeciesSelect")
local SelectSpeciesEvent = Remotes:WaitForChild("SelectSpecies")

local speciesFolder = player:WaitForChild("Species")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeciesSelect"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.45
backdrop.Visible = false
backdrop.Parent = screenGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 560, 0, 260)
panel.Position = UDim2.new(0.5, -280, 0.5, -130)
panel.BackgroundColor3 = Color3.fromRGB(15, 30, 48)
panel.Parent = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 170, 220)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 14)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Choose your creature"
title.Parent = panel

local cardsHolder = Instance.new("Frame")
cardsHolder.Size = UDim2.new(1, -32, 1, -70)
cardsHolder.Position = UDim2.new(0, 16, 0, 58)
cardsHolder.BackgroundTransparency = 1
cardsHolder.Parent = panel

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.Padding = UDim.new(0, 14)
cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardsLayout.Parent = cardsHolder

local cardWidth = (560 - 32 - 14 * (#Config.SpeciesOrder - 1)) / #Config.SpeciesOrder

for _, key in ipairs(Config.SpeciesOrder) do
	local species = Config.Species[key]
	local previewColor = species.Tiers[1].Color

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, cardWidth, 1, 0)
	card.BackgroundColor3 = Color3.fromRGB(25, 45, 68)
	card.Parent = cardsHolder
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 44, 0, 44)
	swatch.Position = UDim2.new(0.5, -22, 0, 14)
	swatch.BackgroundColor3 = previewColor
	swatch.Parent = card
	Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 0, 64)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = species.Name
	nameLabel.Parent = card

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 32)
	button.Position = UDim2.new(0, 10, 1, -44)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = card
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	local ownedValue = speciesFolder:FindFirstChild(key)

	local function refreshButton()
		local owned = ownedValue and ownedValue.Value
		if owned then
			button.Text = "Choose"
			button.BackgroundColor3 = Color3.fromRGB(50, 150, 90)
		else
			button.Text = "Locked ($" .. species.ShopCost .. ")"
			button.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
		end
	end

	if ownedValue then
		ownedValue:GetPropertyChangedSignal("Value"):Connect(refreshButton)
	end
	refreshButton()

	button.MouseButton1Click:Connect(function()
		if ownedValue and ownedValue.Value then
			SelectSpeciesEvent:FireServer(key)
			backdrop.Visible = false
		end
	end)
end

PromptSpeciesSelectEvent.OnClientEvent:Connect(function()
	backdrop.Visible = true
end)
