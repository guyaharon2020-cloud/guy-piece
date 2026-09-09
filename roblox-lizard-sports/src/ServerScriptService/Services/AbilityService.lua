-- Server-authoritative implementation of every real-lizard mechanic:
-- sprinting on a stamina budget, basking in the sun to recharge it,
-- gecko-style wall climbing, chameleon tongue-catching, camouflage,
-- and tail autotomy (drop the tail to escape, it grows back later).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local DataService = require(script.Parent.DataService)
local LizardBuilder = require(script.Parent.LizardBuilder)
local ShopService = require(script.Parent.ShopService)

local AbilityService = {}

-- Fired as (player, catchableInstance) whenever a tongue shot lands on
-- something tagged "Catchable". Sport event modules (e.g. BugHuntEvent)
-- listen here instead of AbilityService knowing anything about scoring.
AbilityService.BugCaught = Instance.new("BindableEvent")

local Remotes
local states = {} -- [player] = { stamina, staminaMax, sprinting, climbing, climbMove, tongueCooldownUntil, camoActive, camoCooldownUntil, tailRegrowAt }

-- Generic "is any part of this player's character touching a tagged part"
-- tracker. Refcounts per player because multiple limbs can be touching the
-- same part (or several tagged parts) at once, and listens for parts tagged
-- after startup so build order vs. MapBuilder never matters.
local function makeTouchTracker(tag)
	local counts = {}

	local function bind(part)
		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			counts[player] = (counts[player] or 0) + 1
		end)
		part.TouchEnded:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			counts[player] = math.max(0, (counts[player] or 0) - 1)
		end)
	end

	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		bind(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(bind)

	Players.PlayerRemoving:Connect(function(player)
		counts[player] = nil
	end)

	return function(player)
		return (counts[player] or 0) > 0
	end
end

local isBasking
local isOnClimbable

local function playTongueEffect(origin, hitPosition)
	local distance = (hitPosition - origin).Magnitude
	if distance <= 0.05 then
		return
	end
	local tongue = Instance.new("Part")
	tongue.Name = "TongueEffect"
	tongue.Anchored = true
	tongue.CanCollide = false
	tongue.CastShadow = false
	tongue.Material = Enum.Material.Neon
	tongue.Color = Color3.fromRGB(255, 90, 140)
	tongue.Size = Vector3.new(0.3, 0.3, distance)
	tongue.CFrame = CFrame.new(origin, hitPosition) * CFrame.new(0, 0, -distance / 2)
	tongue.Parent = workspace
	Debris:AddItem(tongue, 0.15)
end

local function triggerTailDrop(player)
	local character = player.Character
	local state = states[player]
	if not character or not state then
		return
	end
	if not LizardBuilder.HasTail(character) then
		return
	end

	LizardBuilder.DropTail(character)
	local bonuses = ShopService.GetBonuses(player)
	local regrowTime = math.max(5, Constants.BASE_TAIL_REGROW_TIME - (bonuses.tailRegrowReduction or 0))
	state.tailRegrowAt = os.clock() + regrowTime

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local escapeBoost = Instance.new("BodyVelocity")
		escapeBoost.Velocity = rootPart.CFrame.LookVector * 25 + Vector3.new(0, 15, 0)
		escapeBoost.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		escapeBoost.Parent = rootPart
		Debris:AddItem(escapeBoost, 0.3)
	end

	-- A small "close call" reward keeps losing a tail from feeling purely punishing.
	DataService.AddCoins(player, 5)
end

function AbilityService.OnCharacterAdded(player, _character)
	local bonuses = ShopService.GetBonuses(player)
	local staminaMax = Constants.BASE_STAMINA + (bonuses.staminaMax or 0)
	states[player] = {
		stamina = staminaMax,
		staminaMax = staminaMax,
		sprinting = false,
		climbing = false,
		climbMove = Vector2.new(),
		tongueCooldownUntil = 0,
		camoActive = false,
		camoCooldownUntil = 0,
		tailRegrowAt = 0,
	}
end

local function onRequestSprint(player, wantsSprint)
	local state = states[player]
	if not state then
		return
	end
	state.sprinting = (wantsSprint == true) and state.stamina > Constants.MIN_STAMINA_TO_SPRINT
end

local function onClimbState(player, active, moveVector)
	local state = states[player]
	if not state then
		return
	end
	state.climbing = active == true
	if typeof(moveVector) == "Vector2" then
		state.climbMove = moveVector.Magnitude > 1 and moveVector.Unit or moveVector
	else
		state.climbMove = Vector2.new()
	end
end

local function onTongueFire(player, direction)
	local state = states[player]
	local character = player.Character
	if not state or not character then
		return
	end
	if os.clock() < state.tongueCooldownUntil then
		return
	end
	if typeof(direction) ~= "Vector3" or direction.Magnitude == 0 then
		return
	end
	direction = direction.Unit

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	state.tongueCooldownUntil = os.clock() + Constants.TONGUE_COOLDOWN
	local bonuses = ShopService.GetBonuses(player)
	local range = Constants.BASE_TONGUE_RANGE + (bonuses.tongueRange or 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local origin = head.Position
	local result = workspace:Raycast(origin, direction * range, raycastParams)
	playTongueEffect(origin, result and result.Position or (origin + direction * range))

	if result and CollectionService:HasTag(result.Instance, "Catchable") then
		AbilityService.BugCaught:Fire(player, result.Instance)
	end
end

local function onToggleCamo(player)
	local state = states[player]
	local character = player.Character
	if not state or not character then
		return
	end
	if state.camoActive or os.clock() < state.camoCooldownUntil then
		return
	end

	local bonuses = ShopService.GetBonuses(player)
	local duration = Constants.BASE_CAMO_DURATION + (bonuses.camoDuration or 0)
	local cooldown = math.max(3, Constants.BASE_CAMO_COOLDOWN - (bonuses.camoCooldownReduction or 0))

	state.camoActive = true
	state.camoCooldownUntil = os.clock() + duration + cooldown
	LizardBuilder.SetCamo(character, true)

	task.delay(duration, function()
		state.camoActive = false
		if player.Character == character then
			LizardBuilder.SetCamo(character, false)
		end
	end)
end

local function bindPredatorPart(part)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			triggerTailDrop(player)
		end
	end)
end

local function stepPlayer(player, state, dt, statsAccumulatorElapsed)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not rootPart then
		return
	end

	local bonuses = ShopService.GetBonuses(player)
	state.staminaMax = Constants.BASE_STAMINA + (bonuses.staminaMax or 0)
	local hasTail = LizardBuilder.HasTail(character)
	local tailPenalty = hasTail and 1 or Constants.TAIL_DETACHED_SPEED_PENALTY
	local basking = isBasking(player)

	-- Sprint: burns stamina, boosts WalkSpeed; refuses to start once empty.
	if state.sprinting and state.stamina > 0 then
		state.stamina = math.max(0, state.stamina - Constants.STAMINA_DRAIN_PER_SEC * dt)
		humanoid.WalkSpeed = (Constants.BASE_WALKSPEED * Constants.SPRINT_SPEED_MULTIPLIER + (bonuses.sprintSpeed or 0))
			* tailPenalty
		if state.stamina <= 0 then
			state.sprinting = false
		end
	else
		state.sprinting = false
		local regenMultiplier = basking and (Constants.BASKING_REGEN_MULTIPLIER + (bonuses.baskingRate or 0)) or 1
		state.stamina = math.min(state.staminaMax, state.stamina + Constants.STAMINA_REGEN_PER_SEC * regenMultiplier * dt)
		humanoid.WalkSpeed = Constants.BASE_WALKSPEED
	end

	-- Wall climbing: only while actually overlapping a Climbable-tagged part.
	local wantsClimb = state.climbing and isOnClimbable(player)
	if wantsClimb then
		humanoid.AutoRotate = false
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)

		local speed = (Constants.BASE_CLIMB_SPEED + (bonuses.climbSpeed or 0)) * tailPenalty
		local moveVector = state.climbMove or Vector2.new()
		local rightVector = rootPart.CFrame.RightVector
		local upVector = Vector3.new(0, 1, 0)
		local velocity = rightVector * moveVector.X * speed + upVector * moveVector.Y * speed

		local climbVelocity = rootPart:FindFirstChild("ClimbVelocity")
		if not climbVelocity then
			climbVelocity = Instance.new("BodyVelocity")
			climbVelocity.Name = "ClimbVelocity"
			climbVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			climbVelocity.P = 1e4
			climbVelocity.Parent = rootPart
		end
		climbVelocity.Velocity = velocity
	else
		humanoid.AutoRotate = true
		local climbVelocity = rootPart:FindFirstChild("ClimbVelocity")
		if climbVelocity then
			climbVelocity:Destroy()
		end
	end

	-- Tail regrowth timer.
	if state.tailRegrowAt > 0 and os.clock() >= state.tailRegrowAt then
		LizardBuilder.RegrowTail(character)
		state.tailRegrowAt = 0
	end

	if statsAccumulatorElapsed and Remotes then
		Remotes.StatsUpdated:FireClient(player, {
			stamina = state.stamina,
			staminaMax = state.staminaMax,
			basking = basking,
			tailAttached = hasTail,
			tailRegrowRemaining = state.tailRegrowAt > 0 and math.max(0, state.tailRegrowAt - os.clock()) or 0,
			camoCooldownRemaining = math.max(0, state.camoCooldownUntil - os.clock()),
			tongueCooldownRemaining = math.max(0, state.tongueCooldownUntil - os.clock()),
		})
	end
end

function AbilityService.Init(remotes)
	Remotes = remotes
	isBasking = makeTouchTracker("SunSpot")
	isOnClimbable = makeTouchTracker("Climbable")

	for _, part in ipairs(CollectionService:GetTagged("Predator")) do
		bindPredatorPart(part)
	end
	CollectionService:GetInstanceAddedSignal("Predator"):Connect(bindPredatorPart)

	Remotes.RequestSprint.OnServerEvent:Connect(onRequestSprint)
	Remotes.ClimbState.OnServerEvent:Connect(onClimbState)
	Remotes.TongueFire.OnServerEvent:Connect(onTongueFire)
	Remotes.ToggleCamo.OnServerEvent:Connect(onToggleCamo)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	local statsAccumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		statsAccumulator += dt
		local pushStats = statsAccumulator >= Constants.STATS_UPDATE_INTERVAL
		if pushStats then
			statsAccumulator = 0
		end

		for player, state in pairs(states) do
			stepPlayer(player, state, dt, pushStats)
		end
	end)
end

return AbilityService
