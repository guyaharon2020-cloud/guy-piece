-- Watches every part tagged "Raft" (see RaftSpawner) and destroys the raft
-- as soon as a player's creature touches it, paying that player based on how
-- many humans were riding it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProgress = require(ServerScriptService.Modules.PlayerProgress)

local debounced = {}

local function onRaftTagged(hitbox)
	local raft = hitbox.Parent
	if not raft then
		return
	end

	local connection
	connection = hitbox.Touched:Connect(function(otherPart)
		if debounced[hitbox] then
			return
		end

		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		debounced[hitbox] = true
		connection:Disconnect()

		local humanCount = raft:GetAttribute("HumanCount") or 0
		PlayerProgress.AwardRaftDestruction(player, humanCount)

		raft:Destroy()
	end)

	hitbox.AncestryChanged:Connect(function(_, parent)
		if not parent then
			debounced[hitbox] = nil
		end
	end)
end

CollectionService:GetInstanceAddedSignal("Raft"):Connect(onRaftTagged)

for _, hitbox in ipairs(CollectionService:GetTagged("Raft")) do
	onRaftTagged(hitbox)
end
