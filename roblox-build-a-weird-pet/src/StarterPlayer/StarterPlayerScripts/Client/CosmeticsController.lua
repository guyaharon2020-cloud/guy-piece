-- CosmeticsController.lua
-- Renders whatever cosmetics the player currently has equipped (Shop
-- purchases): a Trail on the character, and a colored name tag. Re-applies
-- on every respawn since Trails/Attachments live on the character model.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopItems = require(Shared:WaitForChild("ShopItems"))

local player = Players.LocalPlayer

local CosmeticsController = {}

local RAINBOW_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
	ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
	ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

local currentCosmetics = {}

local function applyTrail(character, itemId)
	local existing = character:FindFirstChild("CosmeticTrail", true)
	if existing then
		existing.Parent:Destroy()
	end
	if not itemId then
		return
	end

	local item = ShopItems.ById[itemId]
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not item or not hrp then
		return
	end

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, 0.6)
	a0.Parent = hrp

	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -0.6)
	a1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "CosmeticTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.7
	trail.WidthScale = NumberSequence.new(1, 0)
	if item.rainbow then
		trail.Color = RAINBOW_SEQUENCE
	else
		trail.Color = ColorSequence.new(item.color or Color3.new(1, 1, 1))
	end
	trail.Parent = a0
end

local function applyNameColor(character, itemId)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("CosmeticNameTag")
	if existing then
		existing:Destroy()
	end
	if not itemId then
		return
	end

	local item = ShopItems.ById[itemId]
	if not item then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CosmeticNameTag"
	billboard.Size = UDim2.new(4, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = player.DisplayName
	label.TextColor3 = item.color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = billboard
end

local function applyAll()
	local character = player.Character
	if not character then
		return
	end
	applyTrail(character, currentCosmetics.Trail)
	applyNameColor(character, currentCosmetics.NameColor)
end

function CosmeticsController.update(equippedCosmetics)
	if not equippedCosmetics then
		return
	end
	currentCosmetics = equippedCosmetics
	applyAll()
end

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyAll()
end)

return CosmeticsController
