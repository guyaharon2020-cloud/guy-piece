-- InventoryPanel.lua
-- Lists every owned pet: thumbnail-less card with name, rarity, mutation,
-- stats and equip status, per the brief's "Pet Inventory" spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local PetStats = require(Shared:WaitForChild("PetStats"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local InventoryPanel = {}

local function statsLine(stats)
	local parts = {}
	for _, key in ipairs(PetStats.StatKeys) do
		table.insert(parts, key .. " " .. tostring(stats[key]))
	end
	return table.concat(parts, "  |  ")
end

function InventoryPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Pet Inventory", UDim2.new(0, 560, 0, 520))
	local panel = { base = base }

	function panel.refresh(state)
		base:clear()
		local equippedSet = {}
		for _, id in ipairs(state.EquippedPetIds or {}) do
			equippedSet[id] = true
		end

		local count = 0
		local ids = {}
		for id in pairs(state.Inventory or {}) do
			table.insert(ids, id)
		end
		table.sort(ids, function(a, b)
			-- ids look like "pet_37"; compare the numeric suffix, newest first.
			local numA = tonumber(a:match("(%d+)$")) or 0
			local numB = tonumber(b:match("(%d+)$")) or 0
			return numA > numB
		end)

		for order, petId in ipairs(ids) do
			local record = state.Inventory[petId]
			count += 1

			local card = Theme.frame({
				Size = UDim2.new(1, 0, 0, 96),
				BackgroundColor3 = Theme.Colors.PanelLight,
				LayoutOrder = order,
			})
			Theme.corner(card, 10)
			Theme.padding(card, 8)
			card.Parent = base.body

			local nameLabel = Theme.label({
				Text = (record.isSecret and "★ " or "") .. record.name .. "  [" .. record.rarity .. "]",
				Size = UDim2.new(1, -100, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.rarityColor(Rarity, record.rarity),
				TextScaled = false,
				TextSize = 17,
			})
			nameLabel.Parent = card

			local statsLabel = Theme.label({
				Text = statsLine(record.stats),
				Size = UDim2.new(1, -100, 0, 20),
				Position = UDim2.new(0, 0, 0, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Colors.SubText,
				TextScaled = false,
				TextSize = 13,
			})
			statsLabel.Parent = card

			local valueLabel = Theme.label({
				Text = "Value: " .. record.value,
				Size = UDim2.new(1, -100, 0, 18),
				Position = UDim2.new(0, 0, 0, 48),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Colors.SubText,
				TextScaled = false,
				TextSize = 12,
			})
			valueLabel.Parent = card

			local equipped = equippedSet[petId]
			local equipButton = Theme.button({
				Text = equipped and "Unequip" or "Equip",
				Size = UDim2.new(0, 90, 0, 32),
				Position = UDim2.new(1, -90, 0, 4),
				BackgroundColor3 = equipped and Theme.Colors.Bad or Theme.Colors.Good,
				TextSize = 14,
			})
			equipButton.Parent = card
			equipButton.MouseButton1Click:Connect(function()
				if equipped then
					Remotes.Event.UnequipPet:FireServer(petId)
				else
					Remotes.Event.EquipPet:FireServer(petId)
				end
			end)

			local releaseButton = Theme.button({
				Text = "Release",
				Size = UDim2.new(0, 90, 0, 32),
				Position = UDim2.new(1, -90, 0, 40),
				BackgroundColor3 = Theme.Colors.PanelLight,
				TextSize = 14,
			})
			Theme.stroke(releaseButton, Theme.Colors.Bad, 1)
			releaseButton.Parent = card
			releaseButton.MouseButton1Click:Connect(function()
				Remotes.Event.ReleasePet:FireServer(petId)
			end)
		end

		if count == 0 then
			local empty = Theme.label({
				Text = "No pets yet -- visit the Part Generator!",
				Size = UDim2.new(1, 0, 0, 40),
				TextColor3 = Theme.Colors.SubText,
				TextSize = 16,
			})
			empty.Parent = base.body
		end
	end

	return panel
end

return InventoryPanel
