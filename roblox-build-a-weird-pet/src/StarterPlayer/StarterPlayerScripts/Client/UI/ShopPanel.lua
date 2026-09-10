-- ShopPanel.lua
-- Two sections: the cosmetic shop (trails, name colors, emotes -- optional
-- flair, no Robux required to progress) and Animal Parts, where players can
-- buy a specific part outright with DNA instead of leaving it to the Part
-- Generator's random roll. Animal Parts only lists the current world's
-- pool (same pool the generator rolls from) and never includes Secret-tier
-- parts -- those stay generator-only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopItems = require(Shared:WaitForChild("ShopItems"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local PetStats = require(Shared:WaitForChild("PetStats"))
local PartShop = require(Shared:WaitForChild("PartShop"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local ShopPanel = {}

local function sectionHeader(text, order)
	return Theme.label({
		Text = text,
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.Accent,
		TextSize = 18,
		LayoutOrder = order,
	})
end

function ShopPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Shop", UDim2.new(0, 480, 0, 560))
	local panel = { base = base }

	function panel.refresh(state)
		base:clear()
		local owned = state.ShopItemsOwned or {}
		local equipped = state.EquippedCosmetics or {}
		local order = 1

		local cosmeticsHeader = sectionHeader("Cosmetics", order)
		cosmeticsHeader.Parent = base.body
		order += 1

		for _, item in ipairs(ShopItems.List) do
			local row = Theme.frame({
				Size = UDim2.new(1, 0, 0, 64),
				BackgroundColor3 = Theme.Colors.PanelLight,
				LayoutOrder = order,
			})
			Theme.corner(row, 10)
			Theme.padding(row, 8)
			row.Parent = base.body
			order += 1

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

		local world = Worlds.get(state.CurrentWorld) or Worlds.List[1]
		local partsHeader = sectionHeader("Animal Parts -- " .. world.name, order)
		partsHeader.Parent = base.body
		order += 1

		local hintLabel = Theme.label({
			Text = "Buy a specific part with DNA to lock it in for your next pet. Travel to a different world portal to shop its parts.",
			Size = UDim2.new(1, 0, 0, 32),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Colors.SubText,
			TextSize = 12,
			LayoutOrder = order,
		})
		hintLabel.Parent = base.body
		order += 1

		for _, slot in ipairs(PetStats.Slots) do
			for _, def in ipairs(world.parts[slot]) do
				if PartShop.isPurchasable(def) then
					local row = Theme.frame({
						Size = UDim2.new(1, 0, 0, 56),
						BackgroundColor3 = Theme.Colors.PanelLight,
						LayoutOrder = order,
					})
					Theme.corner(row, 10)
					Theme.padding(row, 8)
					row.Parent = base.body
					order += 1

					local nameLabel = Theme.label({
						Text = ("%s [%s] -- %s"):format(def.name, def.rarity, slot),
						Size = UDim2.new(1, -100, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = Theme.rarityColor(Rarity, def.rarity),
						TextSize = 15,
					})
					nameLabel.Parent = row

					local buyButton = Theme.button({
						Text = PartShop.priceFor(def) .. " DNA",
						Size = UDim2.new(0, 90, 0, 40),
						Position = UDim2.new(1, -90, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						TextSize = 13,
					})
					buyButton.Parent = row
					buyButton.MouseButton1Click:Connect(function()
						Remotes.Event.BuyPart:FireServer(def.id)
					end)
				end
			end
		end
	end

	return panel
end

return ShopPanel
