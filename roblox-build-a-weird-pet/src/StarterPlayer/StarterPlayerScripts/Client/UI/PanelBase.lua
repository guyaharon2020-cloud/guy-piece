-- PanelBase.lua
-- Builds the common "titled scrollable panel" shell every UI panel uses:
-- a centered frame with a title bar + close button and a ScrollingFrame
-- body. Panels only need to fill in the body content.

local Theme = require(script.Parent:WaitForChild("Theme"))

local PanelBase = {}

function PanelBase.new(screenGui, title, sizeUDim)
	local root = Theme.frame({
		Name = title .. "Panel",
		Size = sizeUDim or UDim2.new(0, 560, 0, 460),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Colors.Background,
		Visible = false,
		ZIndex = 10,
	})
	Theme.corner(root, 16)
	Theme.stroke(root, Theme.Colors.Accent, 3)
	root.Parent = screenGui

	local titleBar = Theme.frame({
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Theme.Colors.Panel,
		ZIndex = 11,
	})
	Theme.corner(titleBar, 16)
	titleBar.Parent = root

	local titleLabel = Theme.label({
		Text = title,
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 22,
		ZIndex = 11,
	})
	titleLabel.Parent = titleBar

	local closeButton = Theme.button({
		Text = "X",
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -44, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Colors.Bad,
		ZIndex = 11,
	})
	closeButton.Parent = titleBar

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -20, 1, -64)
	body.Position = UDim2.new(0, 10, 0, 56)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 6
	body.ScrollBarImageColor3 = Theme.Colors.Accent
	body.CanvasSize = UDim2.new(0, 0, 0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ZIndex = 10
	body.Parent = root

	Theme.listLayout(body, Enum.FillDirection.Vertical, 8)

	closeButton.MouseButton1Click:Connect(function()
		root.Visible = false
	end)

	local panel = { root = root, body = body }

	function panel:setOpen(open)
		root.Visible = open
	end

	function panel:toggle()
		root.Visible = not root.Visible
	end

	function panel:clear()
		for _, child in ipairs(body:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	return panel
end

return PanelBase
