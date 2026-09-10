-- Player-vs-player combat. Each evolution tier grants a different attack
-- (Config.TierProgression[i].Attack, shared by every species) — this
-- script always reads the attacker's CURRENT Evolution tier live, off their
-- leaderstats, every time they attack. There's no cached "equipped attack"
-- anywhere, so evolving swaps your moveset on the very next attack with no
-- extra bookkeeping.
--
-- Fully server-authoritative: the client only ever requests an attack (no
-- payload), and this script decides cooldown, targets, and damage. Damage
-- taken is reduced by the target's Armor/Golden Scales, same as ship
-- combat.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)
local PlayerSpecies = require(ServerScriptService.Modules.PlayerSpecies)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local AttackEvent = Remotes:FindFirstChild("Attack")
if not AttackEvent then
	AttackEvent = Instance.new("RemoteEvent")
	AttackEvent.Name = "Attack"
	AttackEvent.Parent = Remotes
end

local AttackFXEvent = Remotes:FindFirstChild("AttackFX")
if not AttackFXEvent then
	AttackFXEvent = Instance.new("RemoteEvent")
	AttackFXEvent.Name = "AttackFX"
	AttackFXEvent.Parent = Remotes
end

local lastAttackAt = {}

local function isInSafeZone(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return rootPart and rootPart.Position.Y > Config.PvPSafeZoneY
end

local function getAttackForPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local tierIndex = math.clamp((leaderstats and leaderstats.Evolution.Value or 0) + 1, 1, #Config.TierProgression)
	local attack = Config.TierProgression[tierIndex].Attack

	local species = Config.Species[PlayerSpecies.GetSelected(player)]
	local finColor = species.Tiers[tierIndex].FinColor

	return attack, finColor
end

AttackEvent.OnServerEvent:Connect(function(attackerPlayer)
	local attackerCharacter = attackerPlayer.Character
	local attackerRoot = attackerCharacter and attackerCharacter:FindFirstChild("HumanoidRootPart")
	local attackerHumanoid = attackerCharacter and attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not attackerRoot or not attackerHumanoid or attackerHumanoid.Health <= 0 then
		return
	end

	if isInSafeZone(attackerCharacter) then
		return
	end

	local attack, finColor = getAttackForPlayer(attackerPlayer)
	if not attack then
		return
	end

	local now = os.clock()
	if lastAttackAt[attackerPlayer] and now - lastAttackAt[attackerPlayer] < attack.Cooldown then
		return
	end
	lastAttackAt[attackerPlayer] = now

	if attack.Type == "dash" and attack.DashSpeed then
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
		bodyVelocity.Velocity = attackerRoot.CFrame.LookVector * attack.DashSpeed
		bodyVelocity.Parent = attackerRoot
		Debris:AddItem(bodyVelocity, 0.3)
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= attackerPlayer then
			local targetCharacter = targetPlayer.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

			if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and not isInSafeZone(targetCharacter) then
				local offset = targetRoot.Position - attackerRoot.Position
				local distance = offset.Magnitude
				local inRange = distance <= attack.Range

				local inCone = true
				if attack.Type == "melee" or attack.Type == "dash" then
					if distance > 0.01 then
						local toTarget = offset.Unit
						local facing = attackerRoot.CFrame.LookVector
						local angle = math.deg(math.acos(math.clamp(facing:Dot(toTarget), -1, 1)))
						inCone = angle <= (attack.ConeAngle or 180) / 2
					end
				end

				if inRange and inCone then
					local damage = PlayerUpgrades.ReduceIncomingDamage(targetPlayer, attack.Damage)
					targetHumanoid:TakeDamage(damage)
				end
			end
		end
	end

	AttackFXEvent:FireAllClients(attackerRoot.Position, attack.Range, finColor)
end)

Players.PlayerRemoving:Connect(function(player)
	lastAttackAt[player] = nil
end)
