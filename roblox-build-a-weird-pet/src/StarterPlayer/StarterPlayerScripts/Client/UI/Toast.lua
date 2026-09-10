-- Toast.lua
-- Small floating notifications stacked in the top-right corner: pet
-- discoveries, milestone rewards, secret pet announcements, challenge
-- results, and error messages from the server.

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent:WaitForChild("Theme"))

local Toast = {}

local COLOR_BY_KIND = {
	info = Theme.Colors.Accent,
	good = Theme.Colors.Good,
	bad = Theme.Colors.Bad,
	secret = Color3.fromRGB(255, 215, 60),
}

function Toast.init(screenGui)
	local holder = Instance.new("Frame")
	holder.Name = "ToastHolder"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, 360, 1, -20)
	holder.Position = UDim2.new(1, -370, 0, 10)
	holder.ZIndex = 50
	holder.Parent = screenGui

	local layout = Theme.listLayout(holder, Enum.FillDirection.Vertical, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	Toast.holder = holder
end

function Toast.show(text, kind, duration)
	if not Toast.holder then
		return
	end
	duration = duration or 3.5

	local card = Theme.frame({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0,
		ZIndex = 50,
	})
	Theme.corner(card, 10)
	Theme.stroke(card, COLOR_BY_KIND[kind] or Theme.Colors.Accent, 2)
	Theme.padding(card, 10)
	card.Parent = Toast.holder

	local label = Theme.label({
		Text = text,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextScaled = false,
		TextSize = 16,
		TextColor3 = COLOR_BY_KIND[kind] or Theme.Colors.Text,
		ZIndex = 50,
	})
	label.Parent = card

	task.delay(duration, function()
		local tween = TweenService:Create(card, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		tween:Play()
		if label then
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
		tween.Completed:Wait()
		card:Destroy()
	end)
end

return Toast
