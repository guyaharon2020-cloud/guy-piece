-- Theme.lua
-- Small shared style + widget-factory helpers so every panel script stays
-- short instead of re-typing UICorner/UIStroke boilerplate everywhere.

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(30, 24, 45),
	Panel = Color3.fromRGB(45, 34, 66),
	PanelLight = Color3.fromRGB(60, 46, 86),
	Accent = Color3.fromRGB(255, 140, 220),
	AccentDark = Color3.fromRGB(200, 90, 170),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(210, 200, 225),
	Good = Color3.fromRGB(110, 230, 130),
	Bad = Color3.fromRGB(240, 90, 90),
	Coins = Color3.fromRGB(255, 215, 80),
	DNA = Color3.fromRGB(120, 230, 160),
	Mutations = Color3.fromRGB(255, 100, 220),
}

function Theme.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

function Theme.stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Accent
	s.Thickness = thickness or 2
	s.Parent = parent
	return s
end

function Theme.padding(parent, amount)
	local p = Instance.new("UIPadding")
	amount = amount or 8
	p.PaddingTop = UDim.new(0, amount)
	p.PaddingBottom = UDim.new(0, amount)
	p.PaddingLeft = UDim.new(0, amount)
	p.PaddingRight = UDim.new(0, amount)
	p.Parent = parent
	return p
end

function Theme.listLayout(parent, direction, gap)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, gap or 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function Theme.frame(props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.Colors.Panel
	f.BorderSizePixel = 0
	for k, v in pairs(props or {}) do
		f[k] = v
	end
	return f
end

function Theme.label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Theme.Colors.Text
	l.TextScaled = true
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

-- Buttons are always at least 44px tall -- comfortable minimum touch target
-- for mobile, per the brief's "optimized for PC and mobile" requirement.
function Theme.button(props)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = Theme.Colors.Accent
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	b.Size = UDim2.new(1, 0, 0, 44)
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	Theme.corner(b, 10)
	return b
end

function Theme.rarityColor(Rarity, rarityName)
	return Rarity.Info[rarityName] and Rarity.Info[rarityName].color or Color3.new(1, 1, 1)
end

return Theme
