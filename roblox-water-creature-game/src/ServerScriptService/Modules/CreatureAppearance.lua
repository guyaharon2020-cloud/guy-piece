-- Makes the player's default Roblox character look like a fish: strips
-- normal clothing/accessories, recolors the body (countershaded — darker on
-- top, lighter belly, like most fish) per evolution tier, adds simple
-- side-mounted eyes, and welds on a forked tail + dorsal + pectoral fins.
-- Runs entirely with primitive Parts — no custom mesh/asset upload is
-- needed (and none is available from here).
--
-- IMPORTANT: this assumes an R15 rig (UpperTorso/LowerTorso, and
-- Model:ScaleTo support). WorldSetup.server.lua forces
-- StarterPlayer.AvatarType = R15 so this is reliable for every player —
-- without that, an R6 avatar would silently skip scaling and the fins would
-- sit at odd proportions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

local CreatureAppearance = {}

local function getTorso(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local function getHead(character)
	return character:FindFirstChild("Head")
end

local function lighten(color, amount)
	return Color3.new(
		math.clamp(color.R + amount, 0, 1),
		math.clamp(color.G + amount, 0, 1),
		math.clamp(color.B + amount, 0, 1)
	)
end

local function attachPart(character, anchor, part, offset)
	part.CFrame = anchor.CFrame * offset
	part.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function attachFin(character, torso, name, size, color, offset, material)
	local fin = Instance.new("WedgePart")
	fin.Name = name
	fin.Size = size
	fin.Color = color
	fin.Material = material
	fin.CanCollide = false
	fin.CanQuery = false
	fin.Massless = true
	return attachPart(character, torso, fin, offset)
end

local function attachEye(character, head, side)
	local eyeWhite = Instance.new("Part")
	eyeWhite.Name = "Eye"
	eyeWhite.Shape = Enum.PartType.Ball
	eyeWhite.Size = Vector3.new(0.5, 0.5, 0.5)
	eyeWhite.Color = Color3.fromRGB(255, 255, 255)
	eyeWhite.Material = Enum.Material.SmoothPlastic
	eyeWhite.CanCollide = false
	eyeWhite.CanQuery = false
	eyeWhite.Massless = true
	attachPart(character, head, eyeWhite, CFrame.new(side * 0.55, 0, -0.35))

	local pupil = Instance.new("Part")
	pupil.Name = "Pupil"
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.22, 0.22, 0.22)
	pupil.Color = Color3.fromRGB(20, 20, 20)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.CanCollide = false
	pupil.CanQuery = false
	pupil.Massless = true
	attachPart(character, head, pupil, CFrame.new(side * 0.55, 0, -0.55))

	return eyeWhite, pupil
end

function CreatureAppearance.Apply(player)
	local character = player.Character
	if not character then
		return
	end

	local torso = getTorso(character)
	local head = getHead(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not torso or not head or not humanoid then
		return
	end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
			item:Destroy()
		end
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local tierIndex = (leaderstats and leaderstats.Evolution.Value or 0) + 1
	local isMaxTier = tierIndex >= #Config.EvolutionTiers
	local tier = Config.EvolutionTiers[math.clamp(tierIndex, 1, #Config.EvolutionTiers)]

	local consumables = player:FindFirstChild("Consumables")
	local goldenScales = consumables and consumables:FindFirstChild("GoldenScales")
	local isGolden = goldenScales and goldenScales.Value

	local topColor = isGolden and Color3.fromRGB(230, 190, 60) or tier.Color
	local bellyColor = isGolden and Color3.fromRGB(255, 224, 130) or lighten(tier.Color, 0.3)

	local bodyColors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bodyColors.HeadColor3 = topColor
	bodyColors.TorsoColor3 = topColor
	bodyColors.LeftArmColor3 = topColor
	bodyColors.RightArmColor3 = topColor
	bodyColors.LeftLegColor3 = bellyColor
	bodyColors.RightLegColor3 = bellyColor
	bodyColors.Parent = character

	local existingCosmetics = character:FindFirstChild("CreatureCosmetics")
	if existingCosmetics then
		existingCosmetics:Destroy()
	end

	local cosmeticsFolder = Instance.new("Folder")
	cosmeticsFolder.Name = "CreatureCosmetics"

	local finColor = isGolden and Color3.fromRGB(255, 235, 150) or tier.FinColor
	local finMaterial = isMaxTier and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local s = tier.FinScale

	-- Forked tail: two wedges angled outward from the spine for a proper
	-- fish-tail silhouette instead of a single flat fin.
	attachFin(character, torso, "TailFinUp", Vector3.new(0.4, 2 * s, 2.6 * s), finColor,
		CFrame.new(0, 0.3, 1.3) * CFrame.Angles(0, math.rad(180), math.rad(24)), finMaterial).Parent = cosmeticsFolder
	attachFin(character, torso, "TailFinDown", Vector3.new(0.4, 2 * s, 2.6 * s), finColor,
		CFrame.new(0, -0.9, 1.3) * CFrame.Angles(0, math.rad(180), math.rad(-24)), finMaterial).Parent = cosmeticsFolder

	attachFin(character, torso, "DorsalFin", Vector3.new(0.4, 1.6 * s, 1.6 * s), finColor,
		CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), finMaterial).Parent = cosmeticsFolder

	attachFin(character, torso, "LeftFin", Vector3.new(1.4 * s, 0.3, 1 * s), finColor,
		CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(20)), finMaterial).Parent = cosmeticsFolder
	attachFin(character, torso, "RightFin", Vector3.new(1.4 * s, 0.3, 1 * s), finColor,
		CFrame.new(1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(-20)), finMaterial).Parent = cosmeticsFolder

	local leftEye, leftPupil = attachEye(character, head, -1)
	leftEye.Parent = cosmeticsFolder
	leftPupil.Parent = cosmeticsFolder
	local rightEye, rightPupil = attachEye(character, head, 1)
	rightEye.Parent = cosmeticsFolder
	rightPupil.Parent = cosmeticsFolder

	if isMaxTier or isGolden then
		-- Parented to the torso itself (not cosmeticsFolder) so it isn't
		-- wiped by the "existingCosmetics:Destroy()" cleanup on next Apply.
		local existingGlow = torso:FindFirstChild("CreatureGlow")
		if existingGlow then
			existingGlow:Destroy()
		end

		local glow = Instance.new("PointLight")
		glow.Name = "CreatureGlow"
		glow.Color = isGolden and Color3.fromRGB(255, 220, 130) or Color3.fromRGB(120, 255, 220)
		glow.Range = 12
		glow.Brightness = 1.5
		glow.Parent = torso
	end

	cosmeticsFolder.Parent = character

	local scale = 1 + ((leaderstats and leaderstats.Level.Value or 1) - 1) * Config.SizePerLevel + tier.SizeBonus
	local ok, err = pcall(function()
		character:ScaleTo(scale)
	end)
	if not ok then
		warn("CreatureAppearance: ScaleTo failed for " .. player.Name .. " — " .. tostring(err))
	end
end

return CreatureAppearance
