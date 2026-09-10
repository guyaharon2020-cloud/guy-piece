-- Builds an actual creature-shaped body for the player, distinct per
-- species (see Config.Species) and evolution tier, instead of just fins
-- bolted onto the default human silhouette. Built entirely from primitive
-- Parts — no custom mesh/asset upload is needed (and none is available
-- from here).
--
-- How it works: the default character's own body parts (Head, Torso/arms/
-- legs) are made fully invisible but left physically in place — they still
-- drive movement, swimming, and collision exactly as before, nothing about
-- gameplay changes. A separate "FishBody" model, welded to the (now
-- invisible) torso, is what's actually seen. Two body styles:
--   "streamlined"  elongated body, pointed snout, forked tail (Fish, Dolphin)
--   "serpentine"   upright body, forward snout, coronet, curled tail (Sea Horse)
-- It's rebuilt fresh on every call, so it always matches the player's
-- current species, evolution tier, and size.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)
local PlayerSpecies = require(script.Parent.PlayerSpecies)

local CreatureAppearance = {}

local function getTorso(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local function lighten(color, amount)
	return Color3.new(
		math.clamp(color.R + amount, 0, 1),
		math.clamp(color.G + amount, 0, 1),
		math.clamp(color.B + amount, 0, 1)
	)
end

-- Welds `part` to `anchor` at `offset` (an anchor-local CFrame) and parents
-- it under `character`. Returns `part` so callers can chain `.Parent = folder`.
local function attachPart(character, anchor, part, offset)
	part.CFrame = anchor.CFrame * offset
	part.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function attachFin(character, anchor, name, size, color, offset, material)
	local fin = Instance.new("WedgePart")
	fin.Name = name
	fin.Size = size
	fin.Color = color
	fin.Material = material
	fin.CanCollide = false
	fin.CanQuery = false
	fin.Massless = true
	return attachPart(character, anchor, fin, offset)
end

-- Like attachFin, but joined with a Motor6D instead of a WeldConstraint.
-- WeldConstraint bakes in a fixed relative transform and fights any script
-- that tries to move the constrained part afterward; Motor6D is the joint
-- type Roblox's own character animations use precisely because its C0 can
-- be updated live, smoothly, every frame with no jitter. CreatureAnimator
-- .client.lua finds these by name ("SwimMotor") and wiggles their C0 for a
-- swimming tail-wag / dorsal-sway.
local function attachAnimatedFin(character, anchor, name, size, color, offset, material)
	local fin = Instance.new("WedgePart")
	fin.Name = name
	fin.Size = size
	fin.Color = color
	fin.Material = material
	fin.CanCollide = false
	fin.CanQuery = false
	fin.Massless = true
	fin.CFrame = anchor.CFrame * offset
	fin.Parent = character

	local motor = Instance.new("Motor6D")
	motor.Name = "SwimMotor"
	motor.Part0 = anchor
	motor.Part1 = fin
	motor.C0 = offset
	motor:SetAttribute("BaseC0", offset)
	motor.Parent = fin

	return fin
end

local function attachEye(character, anchor, offset, folder)
	local eyeWhite = Instance.new("Part")
	eyeWhite.Name = "Eye"
	eyeWhite.Shape = Enum.PartType.Ball
	eyeWhite.Size = Vector3.new(0.5, 0.5, 0.5)
	eyeWhite.Color = Color3.fromRGB(255, 255, 255)
	eyeWhite.Material = Enum.Material.SmoothPlastic
	eyeWhite.CanCollide = false
	eyeWhite.CanQuery = false
	eyeWhite.Massless = true
	attachPart(character, anchor, eyeWhite, offset).Parent = folder

	local pupil = Instance.new("Part")
	pupil.Name = "Pupil"
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.22, 0.22, 0.22)
	pupil.Color = Color3.fromRGB(20, 20, 20)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.CanCollide = false
	pupil.CanQuery = false
	pupil.Massless = true
	attachPart(character, anchor, pupil, offset * CFrame.new(0, 0, -0.2)).Parent = folder
end

--============================================================
-- "streamlined" body style: Fish, Dolphin
--============================================================

-- A pointed snout: a WedgePart's taper runs along its own local Z by
-- default (full height at -Z, a point at +Z). Rotating 180° about Y sends
-- that point toward world -Z — the character's forward direction — with
-- the flat, full-height base blending back into the body.
local function attachSnoutWedge(character, anchor, size, offset, color)
	local snout = Instance.new("WedgePart")
	snout.Name = "FishSnout"
	snout.Size = size
	snout.Color = color
	snout.Material = Enum.Material.SmoothPlastic
	snout.CanCollide = false
	snout.CanQuery = false
	snout.Massless = true
	return attachPart(character, anchor, snout, offset)
end

-- Small teeth just under the snout — a tiny Pyramid-meshed nub, guarded
-- because MeshType.Pyramid is an easy enum name to get wrong; if it is,
-- the tooth just stays a small white block instead of breaking appearance
-- entirely.
local function attachTeeth(character, anchor, bodySpec, folder)
	for _, side in ipairs({ -1, 1 }) do
		local tooth = Instance.new("Part")
		tooth.Name = "Tooth"
		tooth.Size = Vector3.new(0.35, 0.6, 0.35)
		tooth.Color = Color3.fromRGB(250, 250, 245)
		tooth.Material = Enum.Material.SmoothPlastic
		tooth.CanCollide = false
		tooth.CanQuery = false
		tooth.Massless = true
		local offset = CFrame.new(side * bodySpec.Width * 0.22, -bodySpec.Height * 0.22, -(bodySpec.Length / 2 + bodySpec.SnoutLength * 0.5))
		attachPart(character, anchor, tooth, offset).Parent = folder

		pcall(function()
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Pyramid
			mesh.Parent = tooth
		end)
	end
end

-- Spikes along the spine: a WedgePart rotated -90° about X sends its point
-- toward world +Y (straight up), flat base blending down into the body.
local function attachSpikes(character, anchor, bodySpec, color, material, folder)
	local spikeCount = 4
	for i = 1, spikeCount do
		local t = (i - 0.5) / spikeCount
		local zOffset = -bodySpec.Length * 0.3 + t * bodySpec.Length * 0.6

		local spike = Instance.new("WedgePart")
		spike.Name = "BackSpike"
		spike.Size = Vector3.new(0.5, 1.4, 0.9)
		spike.Color = color
		spike.Material = material
		spike.CanCollide = false
		spike.CanQuery = false
		spike.Massless = true
		local offset = CFrame.new(0, bodySpec.Height * 0.45, zOffset) * CFrame.Angles(math.rad(-90), 0, 0)
		attachPart(character, anchor, spike, offset).Parent = folder
	end
end

local function buildStreamlinedBody(character, torso, bodySpec, tierData, finColor, finMaterial, topColor, bellyColor, folder)
	local L, W, H = bodySpec.Length, bodySpec.Width, bodySpec.Height

	local body = Instance.new("Part")
	body.Name = "FishTorso"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(W, H, L)
	body.Color = topColor
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.CanQuery = false
	body.Massless = true
	attachPart(character, torso, body, CFrame.new()).Parent = folder

	local belly = Instance.new("Part")
	belly.Name = "FishBelly"
	belly.Shape = Enum.PartType.Ball
	belly.Size = Vector3.new(W * 0.75, H * 0.55, L * 0.8)
	belly.Color = bellyColor
	belly.Material = Enum.Material.SmoothPlastic
	belly.CanCollide = false
	belly.CanQuery = false
	belly.Massless = true
	attachPart(character, torso, belly, CFrame.new(0, -H * 0.3, 0)).Parent = folder

	local snoutSize = Vector3.new(W * 0.55, H * 0.55, bodySpec.SnoutLength)
	local snoutOffset = CFrame.new(0, 0, -(L / 2 + bodySpec.SnoutLength / 2)) * CFrame.Angles(0, math.rad(180), 0)
	attachSnoutWedge(character, torso, snoutSize, snoutOffset, topColor).Parent = folder

	if bodySpec.HasTeeth then
		attachTeeth(character, torso, bodySpec, folder)
	end
	if bodySpec.HasSpikes then
		attachSpikes(character, torso, bodySpec, finColor, finMaterial, folder)
	end

	local s = tierData.FinScale
	attachAnimatedFin(character, torso, "TailFinUp", Vector3.new(0.4, H * 0.9 * s, L * 0.35 * s), finColor,
		CFrame.new(0, H * 0.15, L / 2 + L * 0.15) * CFrame.Angles(0, math.rad(180), math.rad(24)), finMaterial).Parent = folder
	attachAnimatedFin(character, torso, "TailFinDown", Vector3.new(0.4, H * 0.9 * s, L * 0.35 * s), finColor,
		CFrame.new(0, -H * 0.4, L / 2 + L * 0.15) * CFrame.Angles(0, math.rad(180), math.rad(-24)), finMaterial).Parent = folder
	attachFin(character, torso, "DorsalFin", Vector3.new(0.4, H * 0.9 * s, H * 0.9 * s), finColor,
		CFrame.new(0, H * 0.5, L * 0.05) * CFrame.Angles(0, 0, math.rad(90)), finMaterial).Parent = folder
	attachFin(character, torso, "LeftFin", Vector3.new(W * 0.9 * s, 0.3, L * 0.3 * s), finColor,
		CFrame.new(-W / 2, -H * 0.1, -L * 0.1) * CFrame.Angles(0, 0, math.rad(20)), finMaterial).Parent = folder
	attachFin(character, torso, "RightFin", Vector3.new(W * 0.9 * s, 0.3, L * 0.3 * s), finColor,
		CFrame.new(W / 2, -H * 0.1, -L * 0.1) * CFrame.Angles(0, 0, math.rad(-20)), finMaterial).Parent = folder

	attachEye(character, torso, CFrame.new(-W * 0.32, H * 0.18, -L * 0.35), folder)
	attachEye(character, torso, CFrame.new(W * 0.32, H * 0.18, -L * 0.35), folder)
end

--============================================================
-- "serpentine" body style: Sea Horse
--============================================================

-- A chain of tapering cylinder segments curling from under the body: each
-- segment's center is placed at the midpoint of its own span (so a 90°
-- roll to align the cylinder's length with that span is direction-agnostic
-- — same trick as the coral tower trunk / ship masts), and `cursor`
-- accumulates a pitch rotation each step so the chain curls backward/under
-- as it descends.
local function attachCurledTail(character, anchor, bodySpec, color, material, folder)
	local segments = bodySpec.TailSegments or 4
	local segLength = bodySpec.Height * 0.22
	local curlPerSegment = math.rad(28)

	local cursor = CFrame.new(0, -bodySpec.Height / 2, bodySpec.Width * 0.25)

	for i = 1, segments do
		cursor = cursor * CFrame.Angles(curlPerSegment, 0, 0)

		local radius = bodySpec.Width * 0.5 * (1 - (i - 1) / (segments + 1))
		local segment = Instance.new("Part")
		segment.Name = "TailSegment"
		segment.Shape = Enum.PartType.Cylinder
		segment.Size = Vector3.new(segLength, radius, radius)
		segment.Color = color
		segment.Material = material
		segment.CanCollide = false
		segment.CanQuery = false
		segment.Massless = true

		local segmentOffset = cursor * CFrame.new(0, -segLength / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
		attachPart(character, anchor, segment, segmentOffset).Parent = folder

		cursor = cursor * CFrame.new(0, -segLength, 0)
	end
end

local function buildSerpentineBody(character, torso, bodySpec, tierData, finColor, finMaterial, topColor, bellyColor, folder)
	local H, W = bodySpec.Height, bodySpec.Width

	local body = Instance.new("Part")
	body.Name = "FishTorso"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(W, H, W * 1.15)
	body.Color = topColor
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.CanQuery = false
	body.Massless = true
	attachPart(character, torso, body, CFrame.new()).Parent = folder

	local belly = Instance.new("Part")
	belly.Name = "FishBelly"
	belly.Shape = Enum.PartType.Ball
	belly.Size = Vector3.new(W * 0.7, H * 0.7, W * 0.85)
	belly.Color = bellyColor
	belly.Material = Enum.Material.SmoothPlastic
	belly.CanCollide = false
	belly.CanQuery = false
	belly.Massless = true
	attachPart(character, torso, belly, CFrame.new(0, 0, -W * 0.15)).Parent = folder

	-- Snout: a thin cylinder pointing forward from the top of the body.
	-- Rotating 90° about Y sends the cylinder's default length axis (local
	-- X) to world -Z (forward) — same family of rotation as the ship's
	-- cannon barrels.
	local snout = Instance.new("Part")
	snout.Name = "SeahorseSnout"
	snout.Shape = Enum.PartType.Cylinder
	snout.Size = Vector3.new(bodySpec.SnoutLength, W * 0.32, W * 0.32)
	snout.Color = topColor
	snout.Material = Enum.Material.SmoothPlastic
	snout.CanCollide = false
	snout.CanQuery = false
	snout.Massless = true
	local snoutOffset = CFrame.new(0, H * 0.35, -(W * 0.4 + bodySpec.SnoutLength / 2)) * CFrame.Angles(0, math.rad(90), 0)
	attachPart(character, torso, snout, snoutOffset).Parent = folder

	-- Coronet: a small crown spike on top of the head, same "point straight
	-- up" trick as the fish's back spikes.
	local coronet = Instance.new("WedgePart")
	coronet.Name = "Coronet"
	coronet.Size = Vector3.new(0.35, H * 0.22, H * 0.16)
	coronet.Color = finColor
	coronet.Material = finMaterial
	coronet.CanCollide = false
	coronet.CanQuery = false
	coronet.Massless = true
	local coronetOffset = CFrame.new(0, H * 0.5, -W * 0.2) * CFrame.Angles(math.rad(-90), 0, 0)
	attachPart(character, torso, coronet, coronetOffset).Parent = folder

	if bodySpec.HasSpines then
		attachSpikes(character, torso, { Height = H, Length = H * 0.6 }, finColor, finMaterial, folder)
	end

	-- Small dorsal fin along the back, and two tiny "neck" fins for a bit
	-- of silhouette variety.
	local s = tierData.FinScale
	attachAnimatedFin(character, torso, "DorsalFin", Vector3.new(0.35, H * 0.6 * s, H * 0.35 * s), finColor,
		CFrame.new(0, H * 0.15, W * 0.45) * CFrame.Angles(0, 0, math.rad(90)), finMaterial).Parent = folder
	attachFin(character, torso, "LeftFin", Vector3.new(W * 0.6 * s, 0.25, W * 0.6 * s), finColor,
		CFrame.new(-W * 0.45, H * 0.3, 0) * CFrame.Angles(0, 0, math.rad(25)), finMaterial).Parent = folder
	attachFin(character, torso, "RightFin", Vector3.new(W * 0.6 * s, 0.25, W * 0.6 * s), finColor,
		CFrame.new(W * 0.45, H * 0.3, 0) * CFrame.Angles(0, 0, math.rad(-25)), finMaterial).Parent = folder

	attachCurledTail(character, torso, bodySpec, topColor, Enum.Material.SmoothPlastic, folder)

	attachEye(character, torso, CFrame.new(-W * 0.28, H * 0.4, -W * 0.35), folder)
	attachEye(character, torso, CFrame.new(W * 0.28, H * 0.4, -W * 0.35), folder)
end

--============================================================

-- Makes every existing body part (Head, torso, arms/legs — whatever the
-- rig has) fully invisible without touching CanCollide, Anchored, or
-- anything else: movement, swimming, and collision are completely
-- untouched, only what's rendered changes.
local function hideOriginalBody(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

function CreatureAppearance.Apply(player)
	local character = player.Character
	if not character then
		return
	end

	local torso = getTorso(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not torso or not humanoid then
		return
	end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
			item:Destroy()
		end
	end

	local existingFishBody = character:FindFirstChild("FishBody")
	if existingFishBody then
		existingFishBody:Destroy()
	end
	local existingGlow = torso:FindFirstChild("CreatureGlow")
	if existingGlow then
		existingGlow:Destroy()
	end

	hideOriginalBody(character)

	local leaderstats = player:FindFirstChild("leaderstats")
	local tierIndex = math.clamp((leaderstats and leaderstats.Evolution.Value or 0) + 1, 1, #Config.TierProgression)
	local isMaxTier = tierIndex >= #Config.TierProgression
	local progression = Config.TierProgression[tierIndex]

	local speciesKey = PlayerSpecies.GetSelected(player)
	local speciesData = Config.Species[speciesKey]
	local tierData = speciesData.Tiers[tierIndex]

	local level = leaderstats and leaderstats.Level.Value or 1
	local scale = 1 + (level - 1) * Config.SizePerLevel + progression.SizeBonus

	local consumables = player:FindFirstChild("Consumables")
	local goldenScales = consumables and consumables:FindFirstChild("GoldenScales")
	local isGolden = goldenScales and goldenScales.Value

	local topColor = isGolden and Color3.fromRGB(230, 190, 60) or tierData.Color
	local bellyColor = isGolden and Color3.fromRGB(255, 224, 130) or lighten(tierData.Color, 0.3)
	local finColor = isGolden and Color3.fromRGB(255, 235, 150) or tierData.FinColor
	local finMaterial = isMaxTier and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local folder = Instance.new("Folder")
	folder.Name = "FishBody"

	if speciesData.BodyStyle == "serpentine" then
		local bodySpec = {
			Height = tierData.Body.Height * scale,
			Width = tierData.Body.Width * scale,
			SnoutLength = tierData.Body.SnoutLength * scale,
			TailSegments = tierData.Body.TailSegments,
			HasSpines = tierData.Body.HasSpines,
		}
		buildSerpentineBody(character, torso, bodySpec, tierData, finColor, finMaterial, topColor, bellyColor, folder)
	else
		local bodySpec = {
			Length = tierData.Body.Length * scale,
			Width = tierData.Body.Width * scale,
			Height = tierData.Body.Height * scale,
			SnoutLength = tierData.Body.SnoutLength * scale,
			HasTeeth = tierData.Body.HasTeeth,
			HasSpikes = tierData.Body.HasSpikes,
		}
		buildStreamlinedBody(character, torso, bodySpec, tierData, finColor, finMaterial, topColor, bellyColor, folder)
	end

	if isMaxTier or isGolden then
		local glow = Instance.new("PointLight")
		glow.Name = "CreatureGlow"
		glow.Color = isGolden and Color3.fromRGB(255, 220, 130) or Color3.fromRGB(120, 255, 220)
		glow.Range = 12
		glow.Brightness = 1.5
		glow.Parent = torso
	end

	folder.Parent = character

	local ok, err = pcall(function()
		character:ScaleTo(scale)
	end)
	if not ok then
		warn("CreatureAppearance: ScaleTo failed for " .. player.Name .. " — " .. tostring(err))
	end
end

return CreatureAppearance
