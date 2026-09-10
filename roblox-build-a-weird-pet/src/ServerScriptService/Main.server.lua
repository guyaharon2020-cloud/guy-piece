-- Main.server.lua
-- Bootstraps the whole server side of Build a Weird Pet: builds the map,
-- initializes every service in dependency order, and wires player
-- join/leave to data loading and pet-follow spawning.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local LabBuilder = require(script.Parent:WaitForChild("World"):WaitForChild("LabBuilder"))
LabBuilder.build()

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local CollectionService = require(Services:WaitForChild("CollectionService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local PetGenerationService = require(Services:WaitForChild("PetGenerationService"))
local PetFollowService = require(Services:WaitForChild("PetFollowService"))
local UpgradeService = require(Services:WaitForChild("UpgradeService"))
local WorldService = require(Services:WaitForChild("WorldService"))
local ShopService = require(Services:WaitForChild("ShopService"))
local ChallengeService = require(Services:WaitForChild("ChallengeService"))

CollectionService.init()
InventoryService.init()
PetGenerationService.init()
PetFollowService.init()
UpgradeService.init()
WorldService.init()
ShopService.init()
ChallengeService.init()

Remotes.Function.GetInitialProfile.OnServerInvoke = function(player)
	local profile = DataService.WaitFor(player)
	return profile
end

Players.PlayerAdded:Connect(function(player)
	DataService.Load(player)
	PetFollowService.onPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PetFollowService.onPlayerRemoving(player)
	DataService.Release(player)
end)

-- Players who joined before this script ran (e.g. Studio "Run" with the
-- server script already live) still need to be picked up.
for _, player in ipairs(Players:GetPlayers()) do
	if not DataService.Get(player) then
		DataService.Load(player)
		PetFollowService.onPlayerAdded(player)
	end
end

print("[BuildAWeirdPet] Server initialized.")
