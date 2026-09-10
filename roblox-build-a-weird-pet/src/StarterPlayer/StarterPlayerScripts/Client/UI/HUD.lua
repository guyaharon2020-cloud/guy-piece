-- HUD.lua
-- Always-visible top currency bar + bottom navigation row. The nav buttons
-- are a convenience mirror of the in-world stations (so players don't have
-- to run back to the lab every time), which matters most on mobile.

local Theme = require(script.Parent:WaitForChild("Theme"))

local HUD = {}

local CURRENCIES = {
	{ key = "Coins", icon = "Coins", color = Theme.Colors.Coins },
	{ key = "DNA", icon = "DNA", color = Theme.Colors.DNA },
	{ key = "Mutations", icon = "Mutations", color = Theme.Colors.Mutations },
}

local NAV_BUTTONS = {
	{ key = "Generator", text = "Generator" },
	{ key = "Inventory", text = "Pets" },
	{ key = "Collection", text = "Collection" },
	{ key = "Shop", text = "Shop" },
	{ key = "Upgrades", text = "Upgrades" },
}

function HUD.new(screenGui, onNavClick)
	local hud = {}

	-- Top currency bar.
	local topBar = Theme.frame({
		Name = "TopBar",
		Size = UDim2.new(0, 420, 0, 56),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Colors.Background,
		BackgroundTransparency = 0.1,
	})
	Theme.corner(topBar, 14)
	Theme.stroke(topBar, Theme.Colors.Accent, 2)
	topBar.Parent = screenGui

	local barLayout = Theme.listLayout(topBar, Enum.FillDirection.Horizontal, 4)
	barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	Theme.padding(topBar, 8)

	hud.currencyLabels = {}
	for _, currency in ipairs(CURRENCIES) do
		local pill = Theme.frame({
			Size = UDim2.new(0, 128, 1, 0),
			BackgroundColor3 = Theme.Colors.Panel,
		})
		Theme.corner(pill, 10)
		pill.Parent = topBar

		local text = Theme.label({
			Text = currency.key .. ": 0",
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 4, 0, 0),
			TextColor3 = currency.color,
			TextScaled = false,
			TextSize = 18,
		})
		text.Parent = pill
		hud.currencyLabels[currency.key] = text
	end

	local worldLabel = Theme.label({
		Text = "Backyard",
		Size = UDim2.new(0, 420, 0, 24),
		Position = UDim2.new(0.5, 0, 0, 70),
		AnchorPoint = Vector2.new(0.5, 0),
		TextColor3 = Theme.Colors.SubText,
		TextSize = 16,
	})
	worldLabel.Parent = screenGui
	hud.worldLabel = worldLabel

	-- Bottom nav row.
	local navBar = Theme.frame({
		Name = "NavBar",
		Size = UDim2.new(0, 520, 0, 56),
		Position = UDim2.new(0.5, 0, 1, -14),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Theme.Colors.Background,
		BackgroundTransparency = 0.1,
	})
	Theme.corner(navBar, 14)
	Theme.stroke(navBar, Theme.Colors.Accent, 2)
	navBar.Parent = screenGui

	local navLayout = Theme.listLayout(navBar, Enum.FillDirection.Horizontal, 6)
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	Theme.padding(navBar, 6)

	for _, nav in ipairs(NAV_BUTTONS) do
		local button = Theme.button({
			Text = nav.text,
			Size = UDim2.new(0, 96, 1, 0),
			TextSize = 16,
		})
		button.Parent = navBar
		button.MouseButton1Click:Connect(function()
			onNavClick(nav.key)
		end)
	end

	function hud:update(state)
		for _, currency in ipairs(CURRENCIES) do
			self.currencyLabels[currency.key].Text = currency.key .. ": " .. tostring(state[currency.key] or 0)
		end
		if state.CurrentWorld then
			self.worldLabel.Text = "World: " .. state.CurrentWorld
		end
	end

	return hud
end

return HUD
