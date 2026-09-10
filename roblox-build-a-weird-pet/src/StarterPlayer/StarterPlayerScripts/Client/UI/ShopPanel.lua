-- ShopPanel.lua
-- Cosmetic shop: trails, name colors, emotes. Everything here is optional
-- flair paid for with in-game currency -- no Robux required to progress.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopItems = require(Shared:WaitForChild("ShopItems"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local ShopPanel = {}

function ShopPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Shop", UDim2.new(0, 480, 0, 520))
	local panel = { base = base }

	function panel.refresh(state)
		base:clear()
		local owned = state.ShopItemsOwned or {}
		local equipped = state.EquippedCosmetics or {}

		for order, item in ipairs(ShopItems.List) do
			local row = Theme.frame({
				Size = UDim2.new(1, 0, 0, 64),
				BackgroundColor3 = Theme.Colors.PanelLight,
				LayoutOrder = order,
			})
			Theme.corner(row, 10)
			Theme.padding(row, 8)
			row.Parent = base.body

			local nameLabel = Theme.label({
				Text = item.name .. " (" .. item.type .. ")",
				Size = UDim2.new(1, -110, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 16,
			})
			nameLabel.Parent = row

			local priceLabel = Theme.label({
				Text = item.price .. " " .. item.currency,
				Size = UDim2.new(1, -110, 0, 18),
				Position = UDim2.new(0, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Colors.SubText,
				TextSize = 13,
			})
			priceLabel.Parent = row

			local isOwned = owned[item.id]
			local isEquipped = equipped[item.type] == item.id
			local buttonText = isEquipped and "Equipped" or (isOwned and "Equip" or "Buy")

			local buyButton = Theme.button({
				Text = buttonText,
				Size = UDim2.new(0, 96, 0, 40),
				Position = UDim2.new(1, -96, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = isEquipped and Theme.Colors.Good or Theme.Colors.Accent,
				TextSize = 14,
			})
			buyButton.Parent = row
			buyButton.MouseButton1Click:Connect(function()
				if not isEquipped then
					Remotes.Event.BuyShopItem:FireServer(item.id)
				end
			end)
		end
	end

	return panel
end

return ShopPanel
