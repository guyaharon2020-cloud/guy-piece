-- Watches every part tagged "Ship" (see ShipSpawner) and handles ramming
-- combat: each hit reduces the ship's Health by the attacking player's
-- AttackPower upgrade, and the ship hits back for contact damage (reduced
-- by the player's Armor upgrade). The ship sinks and pays out once Health
-- reaches 0.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)
local PlayerUpgrades = require(ServerScriptService.Modules.PlayerUpgrades)

local lastHitAt = {}

local function onShipTagged(hull)
	local ship = hull.Parent
	if not ship then
		return
	end

	local connection
	connection = hull.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		if lastHitAt[hull] and now - lastHitAt[hull] < Config.ShipTouchCooldown then
			return
		end
		lastHitAt[hull] = now

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(PlayerUpgrades.GetShipDamageTaken(player))
		end

		local remainingHealth = (ship:GetAttribute("Health") or 0) - PlayerUpgrades.GetAttackPower(player)
		ship:SetAttribute("Health", remainingHealth)

		if remainingHealth <= 0 then
			connection:Disconnect()
			lastHitAt[hull] = nil

			local humanCount = ship:GetAttribute("HumanCount") or 0
			PlayerProgress.AwardHumansDestroyed(player, humanCount)

			ship:Destroy()
		end
	end)

	hull.AncestryChanged:Connect(function(_, parent)
		if not parent then
			lastHitAt[hull] = nil
		end
	end)
end

CollectionService:GetInstanceAddedSignal("Ship"):Connect(onShipTagged)

for _, hull in ipairs(CollectionService:GetTagged("Ship")) do
	onShipTagged(hull)
end
