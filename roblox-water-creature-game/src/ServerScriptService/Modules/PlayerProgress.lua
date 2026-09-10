-- Owns each player's leaderstats (Level, Money, XP, Evolution), the
-- reward/level-up/evolution math, and applying combined stats to the
-- character. Server-authoritative: only server scripts call into this,
-- never the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerUpgrades = require(script.Parent.PlayerUpgrades)
local RobuxShop = require(script.Parent.RobuxShop)
local CreatureAppearance = require(script.Parent.CreatureAppearance)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local NotifyEvent = Remotes:FindFirstChild("Notify")
if not NotifyEvent then
	NotifyEvent = Instance.new("RemoteEvent")
	NotifyEvent.Name = "Notify"
	NotifyEvent.Parent = Remotes
end

local PlayerProgress = {}

function PlayerProgress.Init(player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = leaderstats

	local evolution = Instance.new("IntValue")
	evolution.Name = "Evolution"
	evolution.Value = 0
	evolution.Parent = leaderstats

	leaderstats.Parent = player
end

-- Recomputes the creature's Humanoid stats from scratch (evolution tier +
-- level + shop upgrades combined) and applies them, and rebuilds the fish
-- body to match (CreatureAppearance.Apply computes its own scale the same
-- way, so it always stays in sync with whatever this just set). Call this
-- after a level-up, evolution, or shop purchase — it's cheap and
-- idempotent, so no need to track deltas.
function PlayerProgress.ApplyLevelStats(player)
	local character = player.Character
	local leaderstats = player:FindFirstChild("leaderstats")
	if not character or not leaderstats then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local level = leaderstats.Level.Value
	local tier = Config.EvolutionTiers[math.clamp(leaderstats.Evolution.Value + 1, 1, #Config.EvolutionTiers)]

	local levelSpeedBonus = (level - 1) * Config.WalkSpeedPerLevel
	humanoid.WalkSpeed = Config.BaseWalkSpeed + levelSpeedBonus + tier.SpeedBonus + PlayerUpgrades.GetExtraWalkSpeed(player)

	local previousMaxHealth = humanoid.MaxHealth
	local newMaxHealth = 100 + PlayerUpgrades.GetExtraMaxHealth(player)
	humanoid.MaxHealth = newMaxHealth
	humanoid.Health = math.min(newMaxHealth, humanoid.Health + math.max(0, newMaxHealth - previousMaxHealth))

	CreatureAppearance.Apply(player)
end

-- Called when a player's creature destroys a raft or sinks a ship.
-- humanCount is how many humans were aboard — money and XP both scale with
-- it directly (plus shop/Robux multipliers).
function PlayerProgress.AwardHumansDestroyed(player, humanCount)
	if humanCount <= 0 then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local moneyMultiplier = PlayerUpgrades.GetMoneyMultiplier(player) * RobuxShop.GetActiveMultiplier(player, "Money")
	local xpMultiplier = PlayerUpgrades.GetXPMultiplier(player) * RobuxShop.GetActiveMultiplier(player, "XP")

	local moneyEarned = math.floor(humanCount * Config.MoneyPerHuman * moneyMultiplier)
	local xpEarned = math.floor(humanCount * Config.XPPerHuman * xpMultiplier)

	leaderstats.Money.Value += moneyEarned

	local levelValue = leaderstats.Level
	local xpValue = leaderstats.XP
	local evolutionValue = leaderstats.Evolution
	local leveledUp = false
	local evolved = false
	local evolutionName = nil

	xpValue.Value += xpEarned

	while xpValue.Value >= Config.XPForLevel(levelValue.Value)
		and (levelValue.Value < Config.MaxLevel or evolutionValue.Value < Config.MaxEvolutionTier) do
		xpValue.Value -= Config.XPForLevel(levelValue.Value)

		-- Evolve as part of THIS transition (the one that would otherwise
		-- take you to LevelsPerEvolution), using the same normal per-level
		-- cost as any other level-up. Evolving only once you're ALREADY AT
		-- LevelsPerEvolution and earn a full extra level's worth of XP on
		-- top (the biggest single chunk in the whole curve) made evolution
		-- look broken — you'd sit at level 12 with no feedback for a long,
		-- silent stretch before anything happened.
		local nextLevel = levelValue.Value + 1
		if nextLevel >= Config.LevelsPerEvolution and evolutionValue.Value < Config.MaxEvolutionTier then
			evolutionValue.Value += 1
			levelValue.Value = 1
			xpValue.Value = 0
			evolved = true
			evolutionName = Config.EvolutionTiers[evolutionValue.Value + 1].Name
		else
			levelValue.Value = math.min(nextLevel, Config.MaxLevel)
		end

		leveledUp = true
	end

	if leveledUp then
		-- Also rebuilds the fish body (see ApplyLevelStats), covering the
		-- evolved case too — evolving always sets leveledUp as well.
		PlayerProgress.ApplyLevelStats(player)
	end

	NotifyEvent:FireClient(player, {
		humans = humanCount,
		money = moneyEarned,
		xp = xpEarned,
		leveledUp = leveledUp,
		level = levelValue.Value,
		evolved = evolved,
		evolutionName = evolutionName,
	})
end

return PlayerProgress
