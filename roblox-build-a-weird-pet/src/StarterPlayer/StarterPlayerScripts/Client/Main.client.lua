-- Main.client.lua
-- Boots the whole client: fetches the initial profile snapshot, builds the
-- HUD + every panel, wires world stations/portals to actions, and keeps
-- everything in sync with ProfileUpdated pushes from the server.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent:WaitForChild("UI")
local Toast = require(UI:WaitForChild("Toast"))
local HUD = require(UI:WaitForChild("HUD"))
local GeneratorPanel = require(UI:WaitForChild("GeneratorPanel"))
local InventoryPanel = require(UI:WaitForChild("InventoryPanel"))
local CollectionPanel = require(UI:WaitForChild("CollectionPanel"))
local ShopPanel = require(UI:WaitForChild("ShopPanel"))
local UpgradesPanel = require(UI:WaitForChild("UpgradesPanel"))

local CosmeticsController = require(script.Parent:WaitForChild("CosmeticsController"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BuildAWeirdPetUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = player:WaitForChild("PlayerGui")

Toast.init(screenGui)

local state = Remotes.Function.GetInitialProfile:InvokeServer() or {}

local panels = {}

local hud = HUD.new(screenGui, function(panelKey)
	local panel = panels[panelKey]
	if panel then
		panel.base:toggle()
	end
end)

panels.Generator = GeneratorPanel.new(screenGui)
panels.Inventory = InventoryPanel.new(screenGui)
panels.Collection = CollectionPanel.new(screenGui)
panels.Shop = ShopPanel.new(screenGui)
panels.Upgrades = UpgradesPanel.new(screenGui)

local function refreshAll()
	hud:update(state)
	for _, panel in pairs(panels) do
		panel.refresh(state)
	end
end

refreshAll()
CosmeticsController.update(state.EquippedCosmetics)

Remotes.Event.ProfileUpdated.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	for key, value in pairs(payload) do
		if key ~= "Error" then
			state[key] = value
		end
	end
	refreshAll()

	if payload.EquippedCosmetics then
		CosmeticsController.update(payload.EquippedCosmetics)
	end
	if payload.Error then
		Toast.show(payload.Error, "bad")
	end
	if payload.NewPet then
		local pet = payload.NewPet
		Toast.show(("New pet: %s [%s]"):format(pet.name, pet.rarity), "good")
	end
end)

Remotes.Event.PetDiscovered.OnClientEvent:Connect(function(petRecord, isNewDiscovery, milestone)
	if isNewDiscovery then
		Toast.show("First discovery: " .. petRecord.name .. "!", "good")
	end
	if milestone then
		Toast.show(("Milestone reached: %d discoveries!"):format(milestone), "good", 5)
	end
end)

Remotes.Event.SecretPetAnnouncement.OnClientEvent:Connect(function(playerName, petName)
	Toast.show(("★ %s discovered the SECRET pet \"%s\"! ★"):format(playerName, petName), "secret", 6)
end)

Remotes.Event.ChallengeResult.OnClientEvent:Connect(function(challengeId, score, rewardCoins, rewardDNA)
	Toast.show(("%s complete! Score %d -- +%d Coins, +%d DNA"):format(challengeId, score, rewardCoins, rewardDNA), "info")
end)

-- Generic station handler: every interactive part in the world is tagged
-- with attributes (see LabBuilder.lua) so one listener covers all of them.
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then
		return
	end
	local host = prompt.Parent
	if not host then
		return
	end

	local uiPanel = host:GetAttribute("UIPanel")
	if uiPanel and panels[uiPanel] then
		panels[uiPanel].base:toggle()
	end

	local worldId = host:GetAttribute("WorldId")
	if worldId then
		Remotes.Event.UnlockWorld:FireServer(worldId)
	end

	local challengeId = host:GetAttribute("ChallengeId")
	if challengeId then
		Remotes.Event.StartChallenge:FireServer(challengeId)
	end
end)
