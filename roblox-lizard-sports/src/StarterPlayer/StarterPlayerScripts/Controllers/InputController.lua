-- Keybinds -> ability remotes. The server re-validates everything (range,
-- cooldowns, whether you're actually touching a climbable surface), so
-- this side only has to feel responsive, not be trustworthy.
--
-- Shift: sprint | Space (+WASD): climb | F: tongue catch | C: camouflage

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CLIMB_SEND_INTERVAL = 1 / 15

local InputController = {}

local heldKeys = {}

local function isHeld(keyCode)
	return heldKeys[keyCode] == true
end

function InputController.Init(remotes)
	local player = Players.LocalPlayer

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		heldKeys[input.KeyCode] = true

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			remotes.RequestSprint:FireServer(true)
		elseif input.KeyCode == Enum.KeyCode.F then
			local character = player.Character
			local camera = workspace.CurrentCamera
			if character and camera then
				-- Aim from the camera, not the head: on a third-person camera the
				-- head is offset from what's on screen, so a head-origin ray would
				-- miss anything the reticle looks lined up with.
				remotes.TongueFire:FireServer(camera.CFrame.LookVector, camera.CFrame.Position)
			end
		elseif input.KeyCode == Enum.KeyCode.C then
			remotes.ToggleCamo:FireServer()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		heldKeys[input.KeyCode] = nil

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			remotes.RequestSprint:FireServer(false)
		elseif input.KeyCode == Enum.KeyCode.Space then
			remotes.ClimbState:FireServer(false, Vector2.new())
		end
	end)

	local sendAccumulator = 0
	local wasClimbing = false
	RunService.Heartbeat:Connect(function(dt)
		local climbing = isHeld(Enum.KeyCode.Space)
		sendAccumulator += dt

		if climbing then
			if sendAccumulator >= CLIMB_SEND_INTERVAL then
				sendAccumulator = 0
				local x = (isHeld(Enum.KeyCode.D) and 1 or 0) - (isHeld(Enum.KeyCode.A) and 1 or 0)
				local y = (isHeld(Enum.KeyCode.W) and 1 or 0) - (isHeld(Enum.KeyCode.S) and 1 or 0)
				remotes.ClimbState:FireServer(true, Vector2.new(x, y))
			end
		elseif wasClimbing then
			remotes.ClimbState:FireServer(false, Vector2.new())
		end
		wasClimbing = climbing
	end)
end

return InputController
