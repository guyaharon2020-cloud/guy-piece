-- CollectionPanel.lua
-- The Collection Book: every discovered part-combination, milestone
-- progress, and rewards.

local Theme = require(script.Parent:WaitForChild("Theme"))
local PanelBase = require(script.Parent:WaitForChild("PanelBase"))

local MILESTONES = { 10, 25, 50, 100 }

local CollectionPanel = {}

function CollectionPanel.new(screenGui)
	local base = PanelBase.new(screenGui, "Collection Book", UDim2.new(0, 460, 0, 520))
	local panel = { base = base }

	function panel.refresh(state)
		base:clear()

		local discovered = state.DiscoveredCombinations or {}
		local count = state.DiscoveredCount or 0
		local claimed = state.MilestonesClaimed or {}

		local header = Theme.label({
			Text = ("Discovered: %d combinations"):format(count),
			Size = UDim2.new(1, 0, 0, 28),
			TextSize = 18,
			LayoutOrder = 1,
		})
		header.Parent = base.body

		local milestoneRow = Theme.frame({
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		})
		milestoneRow.Parent = base.body
		local milestoneLayout = Theme.listLayout(milestoneRow, Enum.FillDirection.Horizontal, 8)
		milestoneLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

		for _, milestone in ipairs(MILESTONES) do
			local isClaimed = claimed[tostring(milestone)]
			local pill = Theme.frame({
				Size = UDim2.new(0, 96, 1, 0),
				BackgroundColor3 = isClaimed and Theme.Colors.Good or Theme.Colors.PanelLight,
			})
			Theme.corner(pill, 8)
			pill.Parent = milestoneRow
			local text = Theme.label({
				Text = milestone .. (isClaimed and " done!" or ""),
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = 14,
			})
			text.Parent = pill
		end

		local listHeader = Theme.label({
			Text = "Discoveries:",
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = Theme.Colors.SubText,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 3,
		})
		listHeader.Parent = base.body

		local order = 4
		local names = {}
		for comboId, name in pairs(discovered) do
			table.insert(names, { comboId = comboId, name = name })
		end
		table.sort(names, function(a, b)
			return a.name < b.name
		end)

		for _, entry in ipairs(names) do
			local row = Theme.label({
				Text = "• " .. entry.name,
				Size = UDim2.new(1, 0, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				LayoutOrder = order,
			})
			row.Parent = base.body
			order += 1
		end

		if #names == 0 then
			local empty = Theme.label({
				Text = "Nothing discovered yet -- go create some pets!",
				Size = UDim2.new(1, 0, 0, 30),
				TextColor3 = Theme.Colors.SubText,
				TextSize = 15,
				LayoutOrder = order,
			})
			empty.Parent = base.body
		end
	end

	return panel
end

return CollectionPanel
