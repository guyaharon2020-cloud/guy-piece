-- Wires up leaderstats and turns every spawned character into a lizard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local DataService = require(script.Parent.DataService)
local LizardBuilder = require(script.Parent.LizardBuilder)
local AbilityService = require(script.Parent.AbilityService)

local CharacterService = {}

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	leaderstats.Parent = player
end

-- Profile loading in DataService happens on the same PlayerAdded event, but
-- we don't want to depend on connection ordering, so poll briefly.
local function waitForProfile(player)
	local profile = DataService.Get(player)
	local attempts = 0
	while not profile and player.Parent and attempts < 100 do
		task.wait(0.1)
		profile = DataService.Get(player)
		attempts += 1
	end
	return profile
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = Constants.BASE_WALKSPEED

	local profile = waitForProfile(player)
	local skinId = profile and profile.EquippedSkin or "classic_green"

	LizardBuilder.Build(character, skinId)
	AbilityService.OnCharacterAdded(player, character)
end

local function onPlayerAdded(player)
	createLeaderstats(player)

	task.spawn(function()
		local profile = waitForProfile(player)
		if profile then
			DataService.Push(player)
		end
	end)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

function CharacterService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return CharacterService
