-- Minimal HUD: pops up "+$X, +Y XP" (and a level-up banner) whenever the
-- local player's creature destroys a raft. Roblox's built-in leaderstats
-- panel already shows Level/Money/XP in the player list, so this just adds
-- the transient feedback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyEvent = Remotes:WaitForChild("Notify")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CreatureHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

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
