-- ChallengeService.lua
-- Server-authoritative scoring for the five pet minigames. Each challenge
-- reads a relevant stat off the player's best equipped pet, rolls a bit of
-- randomness on top, and pays out Coins/DNA scaled by lab multipliers.
--
-- NOTE: this owns the reward *economy* for challenges (validation,
-- cooldowns, payout math) but not physical minigame courses (an actual
-- race track/obstacle course with checkpoints). Wire real course scripts
-- to fire RequestChallengeComplete-style logic into this same scoring path
-- when they're built -- the payout/anti-exploit plumbing here doesn't change.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local UpgradeService = require(script.Parent:WaitForChild("UpgradeService"))

local ChallengeService = {}

local CHALLENGES = {
	Race = { stat = "Speed" },
	Jump = { stat = "Jump" },
	Obstacle = { stat = "Speed", secondaryStat = "Jump" },
	Strength = { stat = "Strength" },
	Weirdness = { stat = "Weirdness" },
}

local COOLDOWN_SECONDS = 8
local lastRunAt = {} -- [userId] = { [challengeId] = os.clock() }

local function bestEquippedStat(profile, statKey)
	local best = 1
	for _, petId in ipairs(profile.EquippedPetIds) do
		local record = profile.Inventory[petId]
		if record and record.stats[statKey] and record.stats[statKey] > best then
			best = record.stats[statKey]
		end
	end
	return best
end

local function pushProfile(player, extra)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local payload = { Coins = profile.Coins, DNA = profile.DNA }
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Remotes.Event.ProfileUpdated:FireClient(player, payload)
end

local function onStartChallenge(player, challengeId)
	local profile = DataService.Get(player)
	local challenge = CHALLENGES[challengeId]
	if not profile or not challenge then
		return
	end

	if #profile.EquippedPetIds == 0 then
		pushProfile(player, { Error = "Equip a pet before competing" })
		return
	end

	lastRunAt[player.UserId] = lastRunAt[player.UserId] or {}
	local last = lastRunAt[player.UserId][challengeId]
	if last and os.clock() - last < COOLDOWN_SECONDS then
		return -- silently ignore spam; client also disables the button
	end
	lastRunAt[player.UserId][challengeId] = os.clock()

	local statValue = bestEquippedStat(profile, challenge.stat)
	if challenge.secondaryStat then
		statValue = (statValue + bestEquippedStat(profile, challenge.secondaryStat)) / 2
	end

	local roll = 0.8 + math.random() * 0.4 -- 0.8x - 1.2x
	local score = math.round(statValue * roll)

	local rewardCoins = math.round((10 + score * 0.5) * UpgradeService.coinMultiplier(profile))
	local rewardDNA = math.round((2 + score * 0.1) * UpgradeService.dnaMultiplier(profile))

	profile.Coins += rewardCoins
	profile.DNA += rewardDNA

	Remotes.Event.ChallengeResult:FireClient(player, challengeId, score, rewardCoins, rewardDNA)
	pushProfile(player)
end

function ChallengeService.init()
	Remotes.Event.StartChallenge.OnServerEvent:Connect(onStartChallenge)
end

return ChallengeService
