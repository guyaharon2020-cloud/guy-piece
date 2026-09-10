-- UpgradesPanel.lua
-- Laboratory upgrades: Part Generator, Storage, Luck, Pet Slots, DNA
-- Multiplier, Coin Multiplier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeDefs = require(Shared:WaitForChild("UpgradeDefs"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local UpgradesPanel = {}

function UpgradesPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Lab Upgrades", UDim2.new(0, 480, 0, 520))
	local panel = { base = base }

	function panel.refresh(state)
		base:clear()
		local upgrades = state.Upgrades or {}

		for order, key in ipairs(UpgradeDefs.Order) do
			local def = UpgradeDefs.Definitions[key]
			local level = upgrades[key] or 1
			local maxed = level >= def.maxLevel

			local row = Theme.frame({
				Size = UDim2.new(1, 0, 0, 78),
				BackgroundColor3 = Theme.Colors.PanelLight,
				LayoutOrder = order,
			})
			Theme.corner(row, 10)
			Theme.padding(row, 8)
			row.Parent = base.body

			local nameLabel = Theme.label({
				Text = ("%s -- Level %d/%d"):format(def.name, level, def.maxLevel),
				Size = UDim2.new(1, -110, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 16,
			})
			nameLabel.Parent = row

			local descLabel = Theme.label({
				Text = def.description,
				Size = UDim2.new(1, -110, 0, 36),
				Position = UDim2.new(0, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				TextColor3 = Theme.Colors.SubText,
				TextSize = 13,
			})
			descLabel.Parent = row

			local buyButton = Theme.button({
				Text = maxed and "MAX" or (UpgradeDefs.costFor(key, level) .. " Coins"),
				Size = UDim2.new(0, 100, 0, 44),
				Position = UDim2.new(1, -100, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = maxed and Theme.Colors.SubText or Theme.Colors.Good,
				TextSize = 14,
			})
			buyButton.Parent = row
			if not maxed then
				buyButton.MouseButton1Click:Connect(function()
					Remotes.Event.BuyUpgrade:FireServer(key)
				end)
			end
		end
	end

	return panel
end

return UpgradesPanel
