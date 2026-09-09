-- Ships tagged "Cannon" (Frigates and Galleons — see ShipSpawner) periodically
-- fire a cannonball at the nearest player within their short CannonRange.
-- The ball travels in a straight line at fire-time toward the target (not
-- homing) and deals damage on contact, reduced by Armor/Golden Scales.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)

local CANNONBALL_SPEED = 90

local function findNearestTarget(position, range)
	local nearestPlayer, nearestDistance

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and humanoid.Health > 0 and rootPart then
			local distance = (rootPart.Position - position).Magnitude
			if distance <= range and (not nearestDistance or distance < nearestDistance) then
				nearestPlayer, nearestDistance = player, distance
			end
		end
	end

	return nearestPlayer
end

local function fireCannonball(ship, hull, target)
	local rootPart = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local damage = ship:GetAttribute("CannonDamage") or 10
	local muzzle = hull.Position + Vector3.new(0, 3, 0)
	local direction = (rootPart.Position - muzzle).Unit

	local ball = Instance.new("Part")
	ball.Name = "Cannonball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.4, 1.4, 1.4)
	ball.Color = Color3.fromRGB(35, 35, 38)
	ball.Material = Enum.Material.Slate
	ball.CanCollide = false
	ball.CFrame = CFrame.new(muzzle)
	ball.Parent = Workspace

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Velocity = direction * CANNONBALL_SPEED
	bodyVelocity.Parent = ball

	local connection
	connection = ball.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(PlayerUpgrades.ReduceIncomingDamage(player, damage))
		end

		if connection then
			connection:Disconnect()
		end
		ball:Destroy()
	end)

	Debris:AddItem(ball, 3)
end

local function onCannonShipTagged(hull)
	local ship = hull.Parent
	if not ship then
		return
	end

	task.spawn(function()
		while hull.Parent do
			local cooldown = ship:GetAttribute("CannonCooldown") or 5
			task.wait(cooldown)

			if not hull.Parent then
				break
			end

			local range = ship:GetAttribute("CannonRange") or 50
			local target = findNearestTarget(hull.Position, range)
			if target then
				fireCannonball(ship, hull, target)
			end
		end
	end)
end

CollectionService:GetInstanceAddedSignal("Cannon"):Connect(onCannonShipTagged)

for _, hull in ipairs(CollectionService:GetTagged("Cannon")) do
	onCannonShipTagged(hull)
end
