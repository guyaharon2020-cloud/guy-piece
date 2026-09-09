-- Extra visual polish layered on top of the core world: post-processing for
-- a punchier, more vibrant look, small islands ringing the outer play area
-- for visual variety, and ambient underwater bubbles. All built from
-- Roblox's own primitives/effects/built-in particle texture — no uploaded
-- assets needed (or available from here).
--
-- Deliberately kept in its own script, independent of WorldSetup.server.lua:
-- every step below is wrapped in `safely()` so if any one of them is wrong
-- (an outdated API, a typo'd enum), it's skipped with a warning instead of
-- crashing — and even a full failure here can never take down the core
-- water/terrain generation in WorldSetup, since that's a separate script.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)

if Workspace:GetAttribute("GraphicsPolishApplied") then
	return
end

local function safely(label, fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("GraphicsPolish: '" .. label .. "' failed and was skipped — " .. tostring(err))
	end
end

safely("color grading", function()
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "GraphicsPolishColor"
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = 0.3
	colorCorrection.TintColor = Color3.fromRGB(255, 250, 240)
	colorCorrection.Parent = Lighting
end)

safely("bloom", function()
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "GraphicsPolishBloom"
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
end)

safely("sun rays", function()
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "GraphicsPolishSunRays"
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end)

safely("islands", function()
	local terrain = Workspace.Terrain
	local waterSurfaceY = Config.WaterCenter.Y + Config.WaterSize.Y / 2

	for _ = 1, Config.IslandCount do
		local angle = math.random() * math.pi * 2
		local distance = math.random(Config.SpawnRadius * 0.75, Config.SpawnRadius * 0.95)
		local x = Config.WaterCenter.X + math.cos(angle) * distance
		local z = Config.WaterCenter.Z + math.sin(angle) * distance

		local radius = math.random(20, 40)
		local peakHeight = math.random(8, 18)
		local topY = waterSurfaceY + peakHeight
		local baseY = Config.SeabedY
		local bodyHeight = topY - baseY

		terrain:FillCylinder(CFrame.new(x, baseY + bodyHeight / 2, z), bodyHeight, radius, Enum.Material.Rock)
		terrain:FillCylinder(CFrame.new(x, waterSurfaceY + 1, z), 6, radius * 1.1, Enum.Material.Sand)
		terrain:FillCylinder(CFrame.new(x, topY - 2, z), 6, radius * 0.55, Enum.Material.Grass)
	end
end)

safely("underwater bubbles", function()
	local holder = Instance.new("Part")
	holder.Name = "BubbleField"
	holder.Size = Vector3.new(Config.SpawnRadius * 2, 1, Config.SpawnRadius * 2)
	holder.CFrame = CFrame.new(Config.WaterCenter.X, Config.SeabedY + 2, Config.WaterCenter.Z)
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(6, 10)
	emitter.Rate = 8
	emitter.Speed = NumberRange.new(4, 7)
	emitter.SpreadAngle = Vector2.new(6, 6)
	emitter.Acceleration = Vector3.new(0, 6, 0)
	emitter.Parent = holder
end)

Workspace:SetAttribute("GraphicsPolishApplied", true)
