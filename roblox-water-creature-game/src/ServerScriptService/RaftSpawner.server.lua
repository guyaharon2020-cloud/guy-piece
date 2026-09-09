-- Periodically spawns rafts carrying a random number of humans, scattered
-- around the water. Each raft is tagged "Raft" so RaftDestruction.server.lua
-- can find and wire it up without the two scripts needing direct references.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Modules.GameConfig)

local raftsFolder = Workspace:FindFirstChild("Rafts")
if not raftsFolder then
	raftsFolder = Instance.new("Folder")
	raftsFolder.Name = "Rafts"
	raftsFolder.Parent = Workspace
end

local function createHuman(position)
	local human = Instance.new("Model")
	human.Name = "Human"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1, 2, 1)
	body.CFrame = CFrame.new(position)
	body.Anchored = true
	body.CanCollide = false
	body.Color = Color3.fromRGB(240, 200, 160)
	body.Parent = human

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.8, 0.8, 0.8)
	head.CFrame = CFrame.new(position + Vector3.new(0, 1.4, 0))
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(255, 224, 189)
	head.Parent = human

	human.PrimaryPart = body
	return human
end

local function spawnRaft()
	if #raftsFolder:GetChildren() >= Config.MaxRafts then
		return
	end

	local angle = math.random() * math.pi * 2
	local distance = math.random(50, Config.SpawnRadius)
	local x = Config.WaterCenter.X + math.cos(angle) * distance
	local z = Config.WaterCenter.Z + math.sin(angle) * distance
	local y = Config.WaterCenter.Y + Config.WaterSize.Y / 2 + 1 -- float on the surface

	local raft = Instance.new("Model")
	raft.Name = "Raft"

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(10, 1, 10)
	hitbox.CFrame = CFrame.new(x, y, z)
	hitbox.Anchored = true
	hitbox.Color = Color3.fromRGB(133, 94, 66)
	hitbox.Material = Enum.Material.Wood
	hitbox.Parent = raft

	raft.PrimaryPart = hitbox

	local humanCount = math.random(Config.HumansPerRaftMin, Config.HumansPerRaftMax)
	for _ = 1, humanCount do
		local offset = Vector3.new(math.random(-30, 30) / 10, 1, math.random(-30, 30) / 10)
		local human = createHuman(hitbox.Position + offset)
		human.Parent = raft
	end

	raft:SetAttribute("HumanCount", humanCount)
	CollectionService:AddTag(hitbox, "Raft")
	raft.Parent = raftsFolder
end

while true do
	spawnRaft()
	task.wait(Config.RaftSpawnInterval)
end
