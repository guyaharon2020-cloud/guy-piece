-- Owns each player's leaderstats (Level, Money, XP) and the reward/level-up math.
-- Server-authoritative: only server scripts call into this, never the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

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

	leaderstats.Parent = player
end

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
	humanoid.WalkSpeed = Config.BaseWalkSpeed + (level - 1) * Config.WalkSpeedPerLevel

	local scale = 1 + (level - 1) * Config.SizePerLevel
	pcall(function()
		character:ScaleTo(scale)
	end)
end

-- Called when a player's creature destroys a raft. humanCount is how many
-- humans were on that raft — money and XP both scale with it directly.
function PlayerProgress.AwardRaftDestruction(player, humanCount)
	if humanCount <= 0 then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local moneyEarned = humanCount * Config.MoneyPerHuman
	local xpEarned = humanCount * Config.XPPerHuman

	leaderstats.Money.Value += moneyEarned

	local levelValue = leaderstats.Level
	local xpValue = leaderstats.XP
	local leveledUp = false

	xpValue.Value += xpEarned

	while levelValue.Value < Config.MaxLevel and xpValue.Value >= Config.XPForLevel(levelValue.Value) do
		xpValue.Value -= Config.XPForLevel(levelValue.Value)
		levelValue.Value += 1
		leveledUp = true
	end

	if leveledUp then
		PlayerProgress.ApplyLevelStats(player)
	end

	NotifyEvent:FireClient(player, {
		humans = humanCount,
		money = moneyEarned,
		xp = xpEarned,
		leveledUp = leveledUp,
		level = levelValue.Value,
	})
end

return PlayerProgress
