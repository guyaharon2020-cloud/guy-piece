-- PetFollowService.lua
-- Server-authoritative: spawns/despawns physical pet models as players
-- equip/unequip, and makes each player's equipped pets trail behind them
-- in a fanned-out arc. Also drives the per-frame Rainbow/Glitch mutation
-- visuals set up by PetBuilder.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local PetBuilder = require(Shared:WaitForChild("PetBuilder"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local PetFollowService = {}

local petsFolder = Workspace:FindFirstChild("Pets")
if not petsFolder then
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = Workspace
end

local activeModels = {} -- [userId] = { [petId] = Model }

local function resolveParts(record)
	local parts = {}
	for slot, partId in pairs(record.parts) do
		parts[slot] = Worlds.PartById[partId]
	end
	return parts
end

local function buildModelForRecord(record)
	local parts = resolveParts(record)
	local mutation = Mutations.get(record.mutationId)
	local model = PetBuilder.build(parts, mutation, record.name, record.rarity)
	model.Parent = petsFolder
	return model
end

-- Rebuilds the set of physical models for a player to match their currently
-- equipped pet ids. Called on join and whenever equip state changes.
local function syncPlayer(player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end

	activeModels[player.UserId] = activeModels[player.UserId] or {}
	local current = activeModels[player.UserId]

	local equippedSet = {}
	for _, petId in ipairs(profile.EquippedPetIds) do
		equippedSet[petId] = true
	end

	for petId, model in pairs(current) do
		if not equippedSet[petId] or not profile.Inventory[petId] then
			model:Destroy()
			current[petId] = nil
		end
	end

	for _, petId in ipairs(profile.EquippedPetIds) do
		if not current[petId] then
			local record = profile.Inventory[petId]
			if record then
				current[petId] = buildModelForRecord(record)
			end
		end
	end
end

local function snapToOwner(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local current = activeModels[player.UserId]
	if not hrp or not current then
		return
	end
	for _, model in pairs(current) do
		if model.PrimaryPart then
			model:PivotTo(hrp.CFrame * CFrame.new(0, 0, 4))
		end
	end
end

function PetFollowService.onPlayerAdded(player)
	syncPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		snapToOwner(player)
	end)
end

function PetFollowService.onPlayerRemoving(player)
	local current = activeModels[player.UserId]
	if current then
		for _, model in pairs(current) do
			model:Destroy()
		end
	end
	activeModels[player.UserId] = nil
end

InventoryService.EquipChanged.Event:Connect(syncPlayer)

local hue = 0
RunService.Heartbeat:Connect(function(dt)
	hue = (hue + dt * 0.4) % 1

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local profile = DataService.Get(player)
		local current = activeModels[player.UserId]
		if hrp and profile and current then
			for index, petId in ipairs(profile.EquippedPetIds) do
				local model = current[petId]
				if model and model.PrimaryPart then
					local behindDistance = 4 + math.floor((index - 1) / 2) * 3
					local side = (index % 2 == 0) and 2.5 or -2.5
					if index == 1 then
						side = 0
					end
					local bob = math.sin(os.clock() * 3 + index) * 0.25
					local target = hrp.CFrame * CFrame.new(side, bob, behindDistance)

					local newCFrame = model:GetPivot():Lerp(target, math.clamp(dt * 5, 0, 1))
					model:PivotTo(newCFrame)

					if model:GetAttribute("MutationRainbow") then
						local color = Color3.fromHSV(hue, 0.85, 1)
						for _, descendant in ipairs(model:GetDescendants()) do
							if descendant:IsA("BasePart") and descendant.Name ~= "Eye" then
								descendant.Color = color
							end
						end
					elseif model:GetAttribute("MutationGlitch") and math.random() < 0.02 then
						local jitter = Color3.new(math.random(), math.random(), math.random())
						for _, descendant in ipairs(model:GetDescendants()) do
							if descendant:IsA("BasePart") and descendant.Name ~= "Eye" then
								descendant.Color = jitter
							end
						end
					end
				end
			end
		end
	end
end)

function PetFollowService.init() end

return PetFollowService
