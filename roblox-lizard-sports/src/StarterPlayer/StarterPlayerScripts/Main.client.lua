-- Client bootstrap: wires up shared state and every controller, then runs
-- a small shared cosmetic loop that wags every visible lizard's tail
-- (everyone's, not just your own -- it's purely visual, so no need to
-- involve the server at all).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent.PlayerState)
local Controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(Controllers.InputController)
local HUDController = require(Controllers.HUDController)
local ShopController = require(Controllers.ShopController)

PlayerState.Init(Remotes)
InputController.Init(Remotes)
HUDController.Init(Remotes, PlayerState)
ShopController.Init(Remotes, PlayerState)

RunService.Heartbeat:Connect(function()
	local tailParts = CollectionService:GetTagged(Constants.TAG_TAIL_PART)
	if #tailParts == 0 then
		return
	end

	local t = os.clock()
	for _, segment in ipairs(tailParts) do
		local motor = segment:FindFirstChildWhichIsA("Motor6D")
		if motor then
			local index = segment:GetAttribute("TailIndex") or 1
			local angle = math.sin(t * 2.5 - index * 0.6) * math.rad(10)
			motor.Transform = CFrame.Angles(0, angle, 0)
		end
	end
end)
