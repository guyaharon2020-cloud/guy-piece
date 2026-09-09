-- Minimal HUD: pops up "+$X, +Y XP" (and a level-up banner) whenever the
-- local player's creature destroys a raft. Roblox's built-in leaderstats
-- panel already shows Level/Money/XP in the player list, so this just adds
-- the transient feedback, plus a health bar and current-attack name (PvP
-- damage matters now, and evolving swaps your attack).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyEvent = Remotes:WaitForChild("Notify")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CreatureHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Health bar + current attack name (bottom-left), tracking whichever
-- character is currently alive.
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 220, 0, 50)
statusFrame.Position = UDim2.new(0, 20, 1, -70)
statusFrame.BackgroundTransparency = 1
statusFrame.Parent = screenGui

local healthBack = Instance.new("Frame")
healthBack.Size = UDim2.new(1, 0, 0, 16)
healthBack.Position = UDim2.new(0, 0, 0, 0)
healthBack.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
healthBack.BorderSizePixel = 0
healthBack.Parent = statusFrame
Instance.new("UICorner", healthBack).CornerRadius = UDim.new(0, 6)

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 6)

local attackLabel = Instance.new("TextLabel")
attackLabel.Size = UDim2.new(1, 0, 0, 24)
attackLabel.Position = UDim2.new(0, 0, 0, 20)
attackLabel.BackgroundTransparency = 1
attackLabel.Font = Enum.Font.GothamBold
attackLabel.TextSize = 15
attackLabel.TextXAlignment = Enum.TextXAlignment.Left
attackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
attackLabel.TextStrokeTransparency = 0.4
attackLabel.Text = ""
attackLabel.Parent = statusFrame

local function bindToCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	local function refreshHealth()
		local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
		healthFill.Size = UDim2.new(ratio, 0, 1, 0)
		healthFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(80, 220, 100)
			or ratio > 0.25 and Color3.fromRGB(230, 200, 60)
			or Color3.fromRGB(220, 70, 70)
	end

	humanoid.HealthChanged:Connect(refreshHealth)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refreshHealth)
	refreshHealth()
end

local leaderstats = player:WaitForChild("leaderstats")
local evolutionValue = leaderstats:WaitForChild("Evolution")

local function refreshAttackLabel()
	local tierIndex = math.clamp(evolutionValue.Value + 1, 1, #Config.EvolutionTiers)
	local tier = Config.EvolutionTiers[tierIndex]
	attackLabel.Text = "Attack (F): " .. tier.Attack.Name
end

evolutionValue:GetPropertyChangedSignal("Value"):Connect(refreshAttackLabel)
refreshAttackLabel()

if player.Character then
	bindToCharacter(player.Character)
end
player.CharacterAdded:Connect(bindToCharacter)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 500, 0, 40)
label.Position = UDim2.new(0.5, -250, 0, 20)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0.4
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = ""
label.TextTransparency = 1
label.TextStrokeTransparency = 1
label.Parent = screenGui

NotifyEvent.OnClientEvent:Connect(function(data)
	local text = string.format("+$%d  •  +%d XP  (%d humans)", data.money, data.xp, data.humans)
	if data.evolved then
		text = string.format("🐟 EVOLVED into a %s! Stats reset — level up again.", data.evolutionName)
	elseif data.leveledUp then
		text ..= string.format("   LEVEL UP! Now level %d", data.level)
	end
	label.Text = text
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.4

	local displaySeconds = data.evolved and 4 or 2.5
	task.delay(displaySeconds, function()
		TweenService:Create(label, TweenInfo.new(1), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end)

-- Small "Depth Charges: N" indicator, only shown once you own at least one
-- (a Robux consumable — see RobuxShop.lua).
local consumables = player:WaitForChild("Consumables")
local depthCharges = consumables:WaitForChild("DepthCharges")

local depthChargeLabel = Instance.new("TextLabel")
depthChargeLabel.Size = UDim2.new(0, 220, 0, 24)
depthChargeLabel.Position = UDim2.new(0.5, -110, 0, 64)
depthChargeLabel.BackgroundTransparency = 1
depthChargeLabel.Font = Enum.Font.GothamBold
depthChargeLabel.TextSize = 16
depthChargeLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
depthChargeLabel.TextStrokeTransparency = 0.5
depthChargeLabel.Visible = false
depthChargeLabel.Parent = screenGui

local function refreshDepthChargeLabel()
	depthChargeLabel.Visible = depthCharges.Value > 0
	depthChargeLabel.Text = "💣 Depth Charges: " .. depthCharges.Value
end

depthCharges:GetPropertyChangedSignal("Value"):Connect(refreshDepthChargeLabel)
refreshDepthChargeLabel()
