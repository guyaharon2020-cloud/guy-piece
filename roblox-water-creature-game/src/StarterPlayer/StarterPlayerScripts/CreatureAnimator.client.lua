-- Gives every player's fish body a gentle swimming animation: the tail (or,
-- on sea horses, the dorsal fin) wags side to side via a sine wave. Runs
-- for every character in the server, not just the local player, so
-- everyone's creature looks alive, not just your own.
--
-- Targets Motor6D joints named "SwimMotor" (see CreatureAppearance.lua's
-- attachAnimatedFin) rather than the WeldConstraints used everywhere else
-- on the fish body — WeldConstraint bakes in a fixed relative transform and
-- fights any script that tries to move the constrained part afterward;
-- Motor6D is built for exactly this kind of live, per-frame update.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WAG_SPEED = 4.5 -- radians/sec
local WAG_AMOUNT = math.rad(18)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local wiggle = math.sin(t * WAG_SPEED) * WAG_AMOUNT

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local fishBody = character and character:FindFirstChild("FishBody")
		if fishBody then
			for _, part in ipairs(fishBody:GetChildren()) do
				local motor = part:FindFirstChild("SwimMotor")
				if motor then
					local baseC0 = motor:GetAttribute("BaseC0")
					if baseC0 then
						motor.C0 = baseC0 * CFrame.Angles(0, wiggle, 0)
					end
				end
			end
		end
	end
end)
