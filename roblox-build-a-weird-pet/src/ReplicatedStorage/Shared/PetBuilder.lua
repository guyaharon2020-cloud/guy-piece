-- PetBuilder.lua
-- Assembles a physical Model out of primitive BasePart shapes for a given
-- part selection, so every one of the thousands of possible combinations is
-- actually visually distinct in-game without needing custom meshes.
--
-- The rig is rigid (no joints/physics): every part gets a fixed CFrame
-- offset from the Body at build time, and the whole thing is anchored.
-- Whatever moves the pet around (PetFollowService) just calls
-- model:PivotTo(cframe) every frame, which relocates all parts together.

local Rarity = require(script.Parent:WaitForChild("Rarity"))

local PetBuilder = {}

local SHAPE_TO_ENUM = {
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
	Block = Enum.PartType.Block,
}

local function makePart(name, shape, size, color, material)
	local p
	if shape == "Wedge" or shape == "CornerWedge" then
		p = Instance.new(shape)
	else
		p = Instance.new("Part")
		p.Shape = SHAPE_TO_ENUM[shape] or Enum.PartType.Block
	end
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

-- parts: table keyed by slot -> part definition (see Worlds.lua)
-- mutation: optional mutation definition (see Mutations.lua)
-- displayName: string shown on the floating nameplate
-- overallRarity: rarity string, used to color the nameplate
function PetBuilder.build(parts, mutation, displayName, overallRarity)
	local model = Instance.new("Model")
	model.Name = displayName or "Pet"

	local overrideColor = mutation and mutation.color
	local overrideMaterial = mutation and mutation.material

	-- Body: the anchor everything else is offset from.
	local bodyDef = parts.Body
	local body = makePart(
		"Body",
		bodyDef.shape,
		Vector3.new(2, 1.6, 3),
		overrideColor or bodyDef.color,
		overrideMaterial
	)
	body.CFrame = CFrame.new(0, 0, 0)
	body.Parent = model
	model.PrimaryPart = body

	-- Head: perched on the front-top of the body.
	local headDef = parts.Head
	local head = makePart("Head", headDef.shape, Vector3.new(1.4, 1.4, 1.4), overrideColor or headDef.color, overrideMaterial)
	head.CFrame = body.CFrame * CFrame.new(0, 1.35, -1.55)
	head.Parent = model

	-- Eyes: two small balls on the head, always keep their own color so the
	-- pet still reads as "alive" even under a solid-color mutation.
	local eyesDef = parts.Eyes
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", "Ball", Vector3.new(0.3, 0.3, 0.3), eyesDef.color)
		eye.Material = Enum.Material.Neon
		eye.CFrame = head.CFrame * CFrame.new(0.35 * side, 0.15, -0.65)
		eye.Parent = model
	end

	-- Legs: four small cylinders under the body corners.
	local legsDef = parts.Legs
	for _, offset in ipairs({
		Vector3.new(-0.7, -1.15, -1.1),
		Vector3.new(0.7, -1.15, -1.1),
		Vector3.new(-0.7, -1.15, 1.1),
		Vector3.new(0.7, -1.15, 1.1),
	}) do
		local leg = makePart("Leg", "Cylinder", Vector3.new(0.9, 0.4, 0.4), overrideColor or legsDef.color, overrideMaterial)
		leg.CFrame = body.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
		leg.Parent = model
	end

	-- Special: attached to the back/top of the body (wings, tail, antenna...).
	local specialDef = parts.Special
	local special = makePart(
		"Special",
		specialDef.shape,
		Vector3.new(1.2, 1.2, 0.6),
		overrideColor or specialDef.color,
		overrideMaterial
	)
	special.CFrame = body.CFrame * CFrame.new(0, 0.9, 1.4) * CFrame.Angles(0, math.rad(180), 0)
	special.Parent = model

	-- Ability: rendered as a small glowing orb that floats above the pet,
	-- since an "ability" isn't really a body part -- it's an aura/effect.
	local abilityDef = parts.Ability
	local ability = makePart("Ability", "Ball", Vector3.new(0.5, 0.5, 0.5), abilityDef.color, Enum.Material.Neon)
	ability.CFrame = body.CFrame * CFrame.new(0, 2.4, 0)
	ability.Parent = model

	local light = Instance.new("PointLight")
	light.Color = abilityDef.color
	light.Range = 8
	light.Brightness = 1.5
	light.Parent = ability

	if mutation then
		model:SetAttribute("MutationId", mutation.id)
		if mutation.rainbow then
			model:SetAttribute("MutationRainbow", true)
		end
		if mutation.glitch then
			model:SetAttribute("MutationGlitch", true)
		end
	end

	-- Nameplate.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Size = UDim2.new(6, 0, 1.6, 0)
	billboard.StudsOffset = Vector3.new(0, 2.1, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = displayName or "Weird Pet"
	label.TextColor3 = Rarity.Info[overallRarity or "Common"].color
	label.TextStrokeTransparency = 0.3
	label.Parent = billboard

	if mutation and mutation.scale and mutation.scale ~= 1 then
		model:ScaleTo(mutation.scale)
	end

	return model
end

return PetBuilder
