-- Builds the whole HUD purely from code: coins/wins, a stamina bar, tail
-- status, ability cooldowns, and a banner for sport-event countdowns/results.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HUDController = {}

local EVENT_NAMES = {
	BugHunt = "Bug Hunt",
	SprintDash = "Sprint Dash",
	ClimbTower = "Climb Tower",
}

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

function HUDController.Init(remotes, PlayerState)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = create("ScreenGui", { Name = "LizardHUD", ResetOnSpawnBehavior = Enum.ResetOnSpawnBehavior.Keep }, playerGui)

	-- Top-left: coins / wins.
	local topBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(0, 220, 0, 70),
		Position = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.25,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, topBar)

	local coinsLabel = create("TextLabel", {
		Name = "Coins",
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = "Coins: 0",
		TextColor3 = Color3.fromRGB(255, 220, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
	}, topBar)

	local winsLabel = create("TextLabel", {
		Name = "Wins",
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.new(0, 10, 0, 36),
		BackgroundTransparency = 1,
		Text = "Wins: 0",
		TextColor3 = Color3.fromRGB(200, 255, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 15,
	}, topBar)

	-- Bottom-center: stamina bar + status line.
	local bottomBar = create("Frame", {
		Name = "BottomBar",
		Size = UDim2.new(0, 320, 0, 62),
		Position = UDim2.new(0.5, -160, 1, -80),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.25,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, bottomBar)

	local staminaBack = create("Frame", {
		Name = "StaminaBack",
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromRGB(50, 50, 55),
	}, bottomBar)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, staminaBack)

	local staminaFill = create("Frame", {
		Name = "StaminaFill",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 200, 60),
	}, staminaBack)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, staminaFill)

	local statusLabel = create("TextLabel", {
		Name = "Status",
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 30),
		BackgroundTransparency = 1,
		Text = "Tail: OK | Camo ready | Tongue ready",
		TextColor3 = Color3.fromRGB(230, 230, 230),
		Font = Enum.Font.Gotham,
		TextSize = 13,
	}, bottomBar)

	-- Top-center: sport event banner, hidden until something is happening.
	local banner = create("Frame", {
		Name = "EventBanner",
		Size = UDim2.new(0, 360, 0, 50),
		Position = UDim2.new(0.5, -180, 0, 16),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.15,
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, banner)

	local bannerLabel = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextWrapped = true,
	}, banner)

	local bannerHideAt = 0

	local function showBanner(text, holdSeconds)
		bannerLabel.Text = text
		banner.Visible = true
		bannerHideAt = os.clock() + holdSeconds
	end

	remotes.EventStatus.OnClientEvent:Connect(function(data)
		local eventName = EVENT_NAMES[data.event] or data.event

		if data.state == "Starting" then
			showBanner(("%s starting in %ds..."):format(eventName, data.countdown or 3), (data.countdown or 3) + 1)
		elseif data.state == "Running" then
			if data.score ~= nil then
				showBanner(("%s: %d caught!"):format(eventName, data.score), 2)
			else
				showBanner(("%s: go!"):format(eventName), 2)
			end
		elseif data.state == "Finished" then
			if data.time then
				showBanner(("%s finished in %.1fs (+%d coins)"):format(eventName, data.time, data.reward or 0), 4)
			else
				showBanner(("%s finished! Score %d (+%d coins)"):format(eventName, data.score or 0, data.reward or 0), 4)
			end
		end
	end)

	PlayerState.OnProfileChanged(function(profile)
		coinsLabel.Text = "Coins: " .. tostring(profile.Coins)
		winsLabel.Text = "Wins: " .. tostring(profile.Wins)
	end)

	RunService.Heartbeat:Connect(function()
		local stats = PlayerState.GetStats()
		if stats then
			local ratio = stats.staminaMax > 0 and math.clamp(stats.stamina / stats.staminaMax, 0, 1) or 0
			staminaFill.Size = UDim2.new(ratio, 0, 1, 0)
			staminaFill.BackgroundColor3 = stats.basking and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(255, 200, 60)

			local tailText = stats.tailAttached and "Tail: OK" or ("Tail: regrowing (%ds)"):format(math.ceil(stats.tailRegrowRemaining))
			local camoText = stats.camoCooldownRemaining > 0 and ("Camo %ds"):format(math.ceil(stats.camoCooldownRemaining)) or "Camo ready"
			local tongueText = stats.tongueCooldownRemaining > 0 and "Tongue..." or "Tongue ready"
			statusLabel.Text = string.format("%s | %s | %s", tailText, camoText, tongueText)
		end

		if banner.Visible and os.clock() > bannerHideAt then
			banner.Visible = false
		end
	end)
end

return HUDController
