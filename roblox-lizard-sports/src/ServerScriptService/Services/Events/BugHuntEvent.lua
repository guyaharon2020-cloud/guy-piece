-- "Bug Hunt": a solo 45-second time attack. Step on the start pad, catch as
-- many bugs as you can with your tongue (see AbilityService.onTongueFire)
-- before time runs out.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DataService = require(script.Parent.Parent.DataService)
local AbilityService = require(script.Parent.Parent.AbilityService)

local ROUND_DURATION = 45
local BUG_COUNT = 12
local WIN_SCORE = 6
local COUNTDOWN_SECONDS = 3
local HOP_INTERVAL_MIN = 1
local HOP_INTERVAL_MAX = 2
local HOP_HEIGHT = 3
local HOP_RISE_TIME = 0.3
local HOP_FALL_TIME = 0.15

local BugHuntEvent = {}

local Remotes
local activeRounds = {} -- [player] = { bugs = {Part...}, score = number }

local function randomPointInBounds(bounds)
	local half = bounds.Size / 2
	local localPoint = Vector3.new(
		(math.random() * 2 - 1) * half.X,
		0,
		(math.random() * 2 - 1) * half.Z
	)
	return (bounds.CFrame * CFrame.new(localPoint)).Position
end

-- Keeps the bug hopping to a new random spot every second or two, so
-- catching it takes real aim/timing instead of walking up and firing.
local function startHopping(bug, bounds)
	task.spawn(function()
		while bug.Parent do
			task.wait(HOP_INTERVAL_MIN + math.random() * (HOP_INTERVAL_MAX - HOP_INTERVAL_MIN))
			if not bug.Parent then
				return
			end

			local landingPoint = randomPointInBounds(bounds)
			local peakTween = TweenService:Create(
				bug,
				TweenInfo.new(HOP_RISE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = landingPoint + Vector3.new(0, HOP_HEIGHT, 0) }
			)
			peakTween:Play()
			peakTween.Completed:Wait()
			if not bug.Parent then
				return
			end

			local landTween = TweenService:Create(
				bug,
				TweenInfo.new(HOP_FALL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = landingPoint }
			)
			landTween:Play()
		end
	end)
end

local function spawnBug(owner, bounds)
	local bug = Instance.new("Part")
	bug.Name = "Bug"
	bug.Shape = Enum.PartType.Ball
	bug.Size = Vector3.new(1.2, 1.2, 1.6)
	bug.Color = Color3.fromRGB(45, 32, 20)
	bug.Material = Enum.Material.SmoothPlastic
	bug.CanCollide = false
	bug.Anchored = true
	bug.Position = randomPointInBounds(bounds)
	bug:SetAttribute("OwnerUserId", owner.UserId)
	CollectionService:AddTag(bug, "Catchable")
	bug.Parent = workspace
	startHopping(bug, bounds)
	return bug
end

local function endRound(player)
	local round = activeRounds[player]
	if not round then
		return
	end
	activeRounds[player] = nil

	for _, bug in ipairs(round.bugs) do
		if bug.Parent then
			bug:Destroy()
		end
	end

	local reward = round.score * 10
	if reward > 0 then
		DataService.AddCoins(player, reward)
	end
	if round.score >= WIN_SCORE then
		DataService.AddWin(player)
	end

	if Remotes then
		Remotes.EventStatus:FireClient(player, {
			event = "BugHunt",
			state = "Finished",
			score = round.score,
			reward = reward,
		})
	end
end

local function startRound(player, bounds)
	if activeRounds[player] then
		return
	end
	activeRounds[player] = { bugs = {}, score = 0 }

	if Remotes then
		Remotes.EventStatus:FireClient(player, { event = "BugHunt", state = "Starting", countdown = COUNTDOWN_SECONDS })
	end
	task.wait(COUNTDOWN_SECONDS)

	local round = activeRounds[player]
	if not round then
		return -- player left (or left the game) during the countdown
	end

	for _ = 1, BUG_COUNT do
		table.insert(round.bugs, spawnBug(player, bounds))
	end

	if Remotes then
		Remotes.EventStatus:FireClient(player, { event = "BugHunt", state = "Running", duration = ROUND_DURATION, score = 0 })
	end

	task.delay(ROUND_DURATION, function()
		endRound(player)
	end)
end

local function onBugCaught(player, instance)
	local round = activeRounds[player]
	if not round then
		return
	end
	if instance:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	for index, bug in ipairs(round.bugs) do
		if bug == instance then
			table.remove(round.bugs, index)
			break
		end
	end

	instance:Destroy()
	round.score += 1

	if Remotes then
		Remotes.EventStatus:FireClient(player, { event = "BugHunt", state = "Running", score = round.score })
	end
end

local function bindStartPad(part)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local bounds = CollectionService:GetTagged("BugHuntBounds")[1]
		if not bounds then
			return
		end
		task.spawn(startRound, player, bounds)
	end)
end

function BugHuntEvent.Init(remotes)
	Remotes = remotes
	AbilityService.BugCaught.Event:Connect(onBugCaught)

	for _, part in ipairs(CollectionService:GetTagged("BugHuntStart")) do
		bindStartPad(part)
	end
	CollectionService:GetInstanceAddedSignal("BugHuntStart"):Connect(bindStartPad)

	Players.PlayerRemoving:Connect(function(player)
		local round = activeRounds[player]
		if round then
			for _, bug in ipairs(round.bugs) do
				if bug.Parent then
					bug:Destroy()
				end
			end
			activeRounds[player] = nil
		end
	end)
end

return BugHuntEvent
