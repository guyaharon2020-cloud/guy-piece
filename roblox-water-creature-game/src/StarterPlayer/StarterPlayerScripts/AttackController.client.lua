-- Attack input: press F to attack. The server (PlayerCombat.server.lua)
-- decides everything — which attack, cooldown, who it hits, damage — this
-- script only sends the request and plays a simple visual effect
-- (an expanding ring) wherever the server says an attack happened.

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackEvent = Remotes:WaitForChild("Attack")
local AttackFXEvent = Remotes:WaitForChild("AttackFX")

local ATTACK_KEY = Enum.KeyCode.F

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if input.KeyCode == ATTACK_KEY then
		AttackEvent:FireServer()
	end
end)

AttackFXEvent.OnClientEvent:Connect(function(position, radius, color)
	local ring = Instance.new("Part")
	ring.Name = "AttackFX"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	local tween = TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Size = Vector3.new(0.2, radius * 2, radius * 2),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(ring, 0.5)
end)
