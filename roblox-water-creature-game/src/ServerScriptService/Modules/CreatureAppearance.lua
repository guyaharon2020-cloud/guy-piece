-- Builds an actual fish-shaped body for the player, distinct per evolution
-- tier (see Config.EvolutionTiers[i].Body), instead of just fins bolted
-- onto the default human silhouette. Built entirely from primitive Parts —
-- no custom mesh/asset upload is needed (and none is available from here).
--
-- How it works: the default character's own body parts (Head, Torso/arms/
-- legs) are made fully invisible but left physically in place — they still
-- drive movement, swimming, and collision exactly as before, nothing about
-- gameplay changes. A separate "FishBody" model, welded to the (now
-- invisible) torso, is what's actually seen: an elongated body, a pointed
-- snout, a forked tail, dorsal/pectoral fins, eyes, and (on the bigger
-- tiers) teeth or back spikes. It's rebuilt fresh on every call, so it
-- always matches the player's current evolution tier and size.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

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

-- A pointed snout: a WedgePart's taper runs along its own local Z by
-- default (full height at -Z, a point at +Z). Rotating 180° about Y sends
-- that point toward world -Z — the character's forward direction — with
-- the flat, full-height base blending back into the body.
local function attachSnout(character, anchor, bodySpec, color)
	local snout = Instance.new("WedgePart")
	snout.Name = "FishSnout"
	snout.Size = Vector3.new(bodySpec.Width * 0.55, bodySpec.Height * 0.55, bodySpec.SnoutLength)
	snout.Color = color
	snout.Material = Enum.Material.SmoothPlastic
	snout.CanCollide = false
	snout.CanQuery = false
	snout.Massless = true
	local offset = CFrame.new(0, 0, -(bodySpec.Length / 2 + bodySpec.SnoutLength / 2)) * CFrame.Angles(0, math.rad(180), 0)
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

local function attachEye(character, anchor, bodySpec, side, folder)
	local eyeOffset = CFrame.new(side * bodySpec.Width * 0.32, bodySpec.Height * 0.18, -bodySpec.Length * 0.35)

	local eyeWhite = Instance.new("Part")
	eyeWhite.Name = "Eye"
	eyeWhite.Shape = Enum.PartType.Ball
	eyeWhite.Size = Vector3.new(0.5, 0.5, 0.5)
	eyeWhite.Color = Color3.fromRGB(255, 255, 255)
	eyeWhite.Material = Enum.Material.SmoothPlastic
	eyeWhite.CanCollide = false
	eyeWhite.CanQuery = false
	eyeWhite.Massless = true
	attachPart(character, anchor, eyeWhite, eyeOffset).Parent = folder

	local pupil = Instance.new("Part")
	pupil.Name = "Pupil"
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.22, 0.22, 0.22)
	pupil.Color = Color3.fromRGB(20, 20, 20)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.CanCollide = false
	pupil.CanQuery = false
	pupil.Massless = true
	attachPart(character, anchor, pupil, eyeOffset * CFrame.new(0, 0, -0.2)).Parent = folder
end

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
	local tierIndex = (leaderstats and leaderstats.Evolution.Value or 0) + 1
	local isMaxTier = tierIndex >= #Config.EvolutionTiers
	local tier = Config.EvolutionTiers[math.clamp(tierIndex, 1, #Config.EvolutionTiers)]
	local level = leaderstats and leaderstats.Level.Value or 1
	local scale = 1 + (level - 1) * Config.SizePerLevel + tier.SizeBonus

	local consumables = player:FindFirstChild("Consumables")
	local goldenScales = consumables and consumables:FindFirstChild("GoldenScales")
	local isGolden = goldenScales and goldenScales.Value

	local topColor = isGolden and Color3.fromRGB(230, 190, 60) or tier.Color
	local bellyColor = isGolden and Color3.fromRGB(255, 224, 130) or lighten(tier.Color, 0.3)
	local finColor = isGolden and Color3.fromRGB(255, 235, 150) or tier.FinColor
	local finMaterial = isMaxTier and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local folder = Instance.new("Folder")
	folder.Name = "FishBody"

	local bodySpec = {
		Length = tier.Body.Length * scale,
		Width = tier.Body.Width * scale,
		Height = tier.Body.Height * scale,
		SnoutLength = tier.Body.SnoutLength * scale,
	}
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

	attachSnout(character, torso, bodySpec, topColor).Parent = folder

	if tier.Body.HasTeeth then
		attachTeeth(character, torso, bodySpec, folder)
	end
	if tier.Body.HasSpikes then
		attachSpikes(character, torso, bodySpec, finColor, finMaterial, folder)
	end

	local s = tier.FinScale
	attachFin(character, torso, "TailFinUp", Vector3.new(0.4, H * 0.9 * s, L * 0.35 * s), finColor,
		CFrame.new(0, H * 0.15, L / 2 + L * 0.15) * CFrame.Angles(0, math.rad(180), math.rad(24)), finMaterial).Parent = folder
	attachFin(character, torso, "TailFinDown", Vector3.new(0.4, H * 0.9 * s, L * 0.35 * s), finColor,
		CFrame.new(0, -H * 0.4, L / 2 + L * 0.15) * CFrame.Angles(0, math.rad(180), math.rad(-24)), finMaterial).Parent = folder
	attachFin(character, torso, "DorsalFin", Vector3.new(0.4, H * 0.9 * s, H * 0.9 * s), finColor,
		CFrame.new(0, H * 0.5, L * 0.05) * CFrame.Angles(0, 0, math.rad(90)), finMaterial).Parent = folder
	attachFin(character, torso, "LeftFin", Vector3.new(W * 0.9 * s, 0.3, L * 0.3 * s), finColor,
		CFrame.new(-W / 2, -H * 0.1, -L * 0.1) * CFrame.Angles(0, 0, math.rad(20)), finMaterial).Parent = folder
	attachFin(character, torso, "RightFin", Vector3.new(W * 0.9 * s, 0.3, L * 0.3 * s), finColor,
		CFrame.new(W / 2, -H * 0.1, -L * 0.1) * CFrame.Angles(0, 0, math.rad(-20)), finMaterial).Parent = folder

	attachEye(character, torso, bodySpec, -1, folder)
	attachEye(character, torso, bodySpec, 1, folder)

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
