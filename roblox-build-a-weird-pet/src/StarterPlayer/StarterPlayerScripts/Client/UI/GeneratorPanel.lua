-- GeneratorPanel.lua
-- "Open the Part Generator, receive random creature parts, combine them
-- into a pet." This panel is the heart of the game loop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local PetStats = require(Shared:WaitForChild("PetStats"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local GeneratorPanel = {}

function GeneratorPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Part Generator", UDim2.new(0, 460, 0, 520))
	local panel = { base = base }

	local slotRows = {}
	for _, slot in ipairs(PetStats.Slots) do
		local row = Theme.frame({
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = Theme.Colors.PanelLight,
			LayoutOrder = #slotRows + 1,
		})
		Theme.corner(row, 8)
		Theme.padding(row, 8)
		row.Parent = base.body

		local slotLabel = Theme.label({
			Text = slot,
			Size = UDim2.new(0.35, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Colors.SubText,
			TextScaled = false,
			TextSize = 16,
		})
		slotLabel.Parent = row

		local valueLabel = Theme.label({
			Text = "???",
			Size = UDim2.new(0.65, 0, 1, 0),
			Position = UDim2.new(0.35, 0, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextScaled = false,
			TextSize = 16,
		})
		valueLabel.Parent = row

		slotRows[slot] = valueLabel
	end

	local costLabel = Theme.label({
		Text = "Roll cost: 5 DNA",
		Size = UDim2.new(1, 0, 0, 24),
		TextColor3 = Theme.Colors.SubText,
		TextSize = 15,
		LayoutOrder = 10,
	})
	costLabel.Parent = base.body

	local rollButton = Theme.button({ Text = "Roll Parts", LayoutOrder = 11, Size = UDim2.new(1, 0, 0, 52) })
	rollButton.Parent = base.body
	rollButton.MouseButton1Click:Connect(function()
		Remotes.Event.RequestPartRoll:FireServer()
	end)

	local createButton = Theme.button({
		Text = "Create Pet!",
		LayoutOrder = 12,
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Theme.Colors.Good,
	})
	createButton.Parent = base.body
	createButton.MouseButton1Click:Connect(function()
		Remotes.Event.CreatePet:FireServer()
	end)

	function panel.refresh(state)
		local world = Worlds.get(state.CurrentWorld) or Worlds.List[1]
		local pending = state.PendingParts

		for _, slot in ipairs(PetStats.Slots) do
			local label = slotRows[slot]
			local partId = pending and pending[slot]
			local def = partId and Worlds.PartById[partId]
			if def then
				label.Text = def.name .. " (" .. def.rarity .. ")"
				label.TextColor3 = Theme.rarityColor(Rarity, def.rarity)
			else
				label.Text = "???"
				label.TextColor3 = Theme.Colors.SubText
			end
		end

		local level = state.Upgrades and state.Upgrades.PartGenerator or 1
		local cost = math.max(1, 5 - (level - 1))
		costLabel.Text = ("Roll cost: %d DNA -- current world: %s"):format(cost, world.name)
	end

	return panel
end

return GeneratorPanel
