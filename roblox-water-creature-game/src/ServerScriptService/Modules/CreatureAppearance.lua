-- Builds an actual creature-shaped body for the player, distinct per
-- species (see Config.Species) and evolution tier, instead of just fins
-- bolted onto the default human silhouette. Built from primitive Parts —
-- the Cubie Fish too, from a blueprint of its own 3D model — except that a
-- species with a `CustomModel` uses that imported mesh instead, if it's
-- been imported into the place.
--
-- How it works: the default character's own body parts (Head, Torso/arms/
-- legs) are made fully invisible but left physically in place — they still
-- drive movement, swimming, and collision exactly as before, nothing about
-- gameplay changes. A separate "FishBody" model, welded to the (now
-- invisible) torso, is what's actually seen. Two body styles:
--   "cubie"        the Cubie Fish's cube body + pixel skin + fins (Fish)
--   "streamlined"  elongated body, pointed snout, forked tail (Dolphin)
--   "serpentine"   upright body, forward snout, coronet, curled tail (Sea Horse)
-- It's rebuilt fresh on every call, so it always matches the player's
-- current species, evolution tier, and size.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
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
-- "streamlined" body style: Dolphin
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
-- "cubie" body style: the Cubie Fish, rebuilt from Parts
--============================================================

-- CubieFishBlueprint.lua is generated from the Cubie Fish's own 3D model
-- and texture (tools/generate_cubie_blueprint.py): the cube body's size and
-- color, every stripe/eye/teeth "pixel" of its skin as a rectangle on one of
-- the cube's faces, and its fin/tail measurements — all in units of the
-- whole fish's length. So it looks like the model with no mesh import.
local CubieBlueprint = require(script.Parent.CubieFishBlueprint)

local PIXEL_THICKNESS = 0.006 -- fraction of the fish's length
local FIN_THICKNESS = 0.02
local AXIS_VECTORS = { X = Vector3.new(1, 0, 0), Y = Vector3.new(0, 1, 0), Z = Vector3.new(0, 0, 1) }

local function newSkinPart(className, name, size, color, material)
	local part = Instance.new(className)
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	return part
end

-- A tail lobe hinged at the back of the body: Motor6D C0 is the hinge
-- point and C1 the lobe's offset from it, so CreatureAnimator's wag (which
-- rotates C0) swings the lobe around the hinge instead of its own center.
local function attachTailLobe(character, torso, lobe, joint, lobeOffset, folder)
	lobe.CFrame = torso.CFrame * joint * lobeOffset
	lobe.Parent = character

	local motor = Instance.new("Motor6D")
	motor.Name = "SwimMotor"
	motor.Part0 = torso
	motor.Part1 = lobe
	motor.C0 = joint
	motor.C1 = lobeOffset:Inverse()
	motor:SetAttribute("BaseC0", joint)
	motor.Parent = lobe

	lobe.Parent = folder
end

-- WedgePart geometry used below: the sloped face points toward local -Z,
-- so the wedge is zero-height at -Z and full height at +Z.
local function buildCubieBody(character, torso, fishLength, baseColorOverride, finColorOverride, finMaterial, folder)
	local bp = CubieBlueprint
	local k = fishLength
	local baseColor = baseColorOverride or bp.BaseColor
	local finColor = finColorOverride or bp.FinColor

	local body = newSkinPart("Part", "FishTorso", bp.BodySize * k, baseColor, Enum.Material.SmoothPlastic)
	attachPart(character, torso, body, CFrame.new()).Parent = folder

	-- Each pixel is a thin plate lying on its face of the cube, raised by
	-- half its thickness so it sits on top of the surface.
	local thickness = PIXEL_THICKNESS * k
	for _, pixel in ipairs(bp.Pixels) do
		local center, size, axis, colorIndex = pixel[1], pixel[2], pixel[3], pixel[4]
		local normal = AXIS_VECTORS[axis]
		local outward = center:Dot(normal) >= 0 and 1 or -1
		local plate = newSkinPart("Part", "SkinPixel", size * k + normal * thickness, bp.Palette[colorIndex], Enum.Material.SmoothPlastic)
		attachPart(character, torso, plate, CFrame.new(center * k + normal * (outward * thickness / 2))).Parent = folder
	end

	-- Dorsal fin: unrotated, so it ramps up from the front to a tall back
	-- edge, like a shark fin.
	local dorsal = newSkinPart("WedgePart", "DorsalFin", bp.DorsalFin.Size * k, finColor, finMaterial)
	attachPart(character, torso, dorsal, CFrame.new(bp.DorsalFin.Center * k)).Parent = folder

	-- Side fins: the blueprint gives each fin's bounding box (outward span
	-- in X, droop in Y). Rolling about Z by ±(90° + droop) turns the wedge's
	-- height axis (local Y) to point outward and down: for the left fin,
	-- local Y -> (-sin θ, cos θ) = (-cos droop, -sin droop).
	for _, finSpec in ipairs({ { bp.LeftFin, -1, "LeftFin" }, { bp.RightFin, 1, "RightFin" } }) do
		local spec, side, name = finSpec[1], finSpec[2], finSpec[3]
		local span = spec.Size * k
		local length = math.sqrt(span.X ^ 2 + span.Y ^ 2)
		local droop = math.atan2(span.Y, span.X)
		local fin = newSkinPart("WedgePart", name, Vector3.new(FIN_THICKNESS * k, length, span.Z), finColor, finMaterial)
		local offset = CFrame.new(spec.Center * k) * CFrame.Angles(0, 0, -side * (math.pi / 2 + droop))
		attachPart(character, torso, fin, offset).Parent = folder
	end

	-- Tail: an upper lobe ramping up toward the back, and a lower lobe (the
	-- same wedge rolled 180°) ramping down — together a fan that widens
	-- behind the hinge, both wagging around it.
	local tailSize = bp.Tail.Size * k
	local lobeSize = Vector3.new(tailSize.X, tailSize.Y / 2, tailSize.Z)
	local joint = CFrame.new(bp.Tail.Joint * k)
	attachTailLobe(character, torso, newSkinPart("WedgePart", "TailFinUp", lobeSize, finColor, finMaterial), joint,
		CFrame.new(0, lobeSize.Y / 2, lobeSize.Z / 2), folder)
	attachTailLobe(character, torso, newSkinPart("WedgePart", "TailFinDown", lobeSize, finColor, finMaterial), joint,
		CFrame.new(0, -lobeSize.Y / 2, lobeSize.Z / 2) * CFrame.Angles(0, 0, math.pi), folder)

	return body.Size
end

--============================================================
-- Imported mesh body (Config.Species[key].CustomModel)
--============================================================

local CUSTOM_MODEL_FOLDER = "CreatureModels"
local customModelCache = {}

-- Studio's Import 3D drops the model into Workspace, so the first lookup
-- moves it into ServerStorage — out of the world, but still clonable.
-- Accepts either the whole imported Model (named after the .fbx file) or,
-- failing that, its body MeshPart wherever the importer put it. Folders are
-- skipped in the fallback so the clones inside players' FishBody folders
-- are never mistaken for the original.
local function locateCustomModel(modelSpec)
	local folder = ServerStorage:FindFirstChild(CUSTOM_MODEL_FOLDER)
	local stored = folder and folder:FindFirstChild(modelSpec.Name)
	if stored then
		return stored
	end

	local found
	for _, root in ipairs({ Workspace, ReplicatedStorage, ServerStorage }) do
		found = root:FindFirstChild(modelSpec.Name, true)
		if found then
			break
		end
		local bodyPart = modelSpec.BodyPartName and root:FindFirstChild(modelSpec.BodyPartName, true)
		if bodyPart and bodyPart:IsA("BasePart") and not bodyPart:FindFirstAncestorOfClass("Folder") then
			local parentModel = bodyPart.Parent
			found = (parentModel:IsA("Model") and parentModel ~= Workspace) and parentModel or bodyPart
			break
		end
	end
	if not found then
		return nil
	end

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CUSTOM_MODEL_FOLDER
		folder.Parent = ServerStorage
	end
	found.Name = modelSpec.Name
	found.Parent = folder
	return found
end

local function findCustomModel(modelSpec)
	local cached = customModelCache[modelSpec.Name]
	if cached == nil then
		cached = locateCustomModel(modelSpec) or false
		customModelCache[modelSpec.Name] = cached
		if not cached then
			print("CreatureAppearance: '" .. modelSpec.Name .. "' mesh not imported, using the Part-built version. "
				.. "For the smoother mesh: Studio Import 3D -> assets/" .. modelSpec.Name .. ".fbx, then save.")
		end
	end
	return cached or nil
end

local function collectParts(root)
	local parts = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

-- World-axis bounding box of `parts` as they sit right now.
local function worldBounds(parts)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for _, part in ipairs(parts) do
		local half = part.Size / 2
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local corner = part.CFrame:PointToWorldSpace(Vector3.new(sx * half.X, sy * half.Y, sz * half.Z))
					minX, minY, minZ = math.min(minX, corner.X), math.min(minY, corner.Y), math.min(minZ, corner.Z)
					maxX, maxY, maxZ = math.max(maxX, corner.X), math.max(maxY, corner.Y), math.max(maxZ, corner.Z)
				end
			end
		end
	end
	local minV, maxV = Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
	return (minV + maxV) / 2, maxV - minV
end

-- Clones the imported model, scales it so its longest side is
-- `targetLength`, centers it on the torso (keeping the imported pose's
-- facing, plus YawDegrees), welds the body, and joins the tail with a
-- Motor6D "SwimMotor" pivoting at the tail's base so CreatureAnimator wags
-- it. The importer's facing is taken as-is: the .fbx was exported with the
-- face toward -Z, Roblox's forward. Returns the scaled size, or nil if the
-- model has no parts.
local function buildCustomModelBody(character, torso, template, modelSpec, targetLength, folder)
	local clone = template:Clone()
	local parts = collectParts(clone)
	if #parts == 0 then
		clone:Destroy()
		return nil
	end

	local center, size = worldBounds(parts)
	local factor = targetLength / math.max(size.X, size.Y, size.Z)
	local frame = torso.CFrame * CFrame.Angles(0, math.rad(modelSpec.YawDegrees or 0), 0)

	for _, part in ipairs(parts) do
		for _, joint in ipairs(part:GetChildren()) do
			if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
				joint:Destroy()
			end
		end
		local relative = part.CFrame - center
		part.Size = part.Size * factor
		part.CFrame = frame * (CFrame.new(relative.Position * factor) * relative.Rotation)
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.Massless = true
		part.Parent = folder
	end
	if not clone:IsA("BasePart") then
		clone:Destroy()
	end

	for _, part in ipairs(parts) do
		if part.Name == modelSpec.TailPartName then
			local toBody = frame.Position - part.Position
			local direction = toBody.Magnitude > 1e-3 and toBody.Unit or frame.LookVector
			local localDir = part.CFrame:VectorToObjectSpace(direction)
			local halfExtent = 0.5 * (math.abs(localDir.X) * part.Size.X + math.abs(localDir.Y) * part.Size.Y + math.abs(localDir.Z) * part.Size.Z)
			local jointWorld = CFrame.new(part.Position + direction * halfExtent) * frame.Rotation

			local motor = Instance.new("Motor6D")
			motor.Name = "SwimMotor"
			motor.Part0 = torso
			motor.Part1 = part
			motor.C0 = torso.CFrame:ToObjectSpace(jointWorld)
			motor.C1 = part.CFrame:ToObjectSpace(jointWorld)
			motor:SetAttribute("BaseC0", motor.C0)
			motor.Parent = part
		else
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = part
			weld.Parent = part
		end
	end

	return size * factor
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

	-- Scale the (invisible) rig before building the body: the body is built
	-- at an already-scaled size, so scaling afterward would scale it twice
	-- and desync the tail's saved BaseC0 from its rescaled joint.
	local ok, err = pcall(function()
		character:ScaleTo(scale)
	end)
	if not ok then
		warn("CreatureAppearance: ScaleTo failed for " .. player.Name .. " — " .. tostring(err))
	end

	local folder = Instance.new("Folder")
	folder.Name = "FishBody"

	local fishLength = (tierData.Body.Length + (tierData.Body.SnoutLength or 0)) * scale
	local customTemplate = speciesData.CustomModel and findCustomModel(speciesData.CustomModel)
	local customSize = customTemplate and buildCustomModelBody(character, torso, customTemplate, speciesData.CustomModel, fishLength, folder)
	if not customSize and speciesData.BodyStyle == "cubie" then
		customSize = buildCubieBody(character, torso, fishLength, isGolden and topColor, isGolden and finColor, finMaterial, folder)
	end

	if customSize then
		if tierData.Body.HasSpikes then
			attachSpikes(character, torso, { Height = customSize.Y, Length = customSize.Z }, finColor, finMaterial, folder)
		end
	elseif speciesData.BodyStyle == "serpentine" then
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
end

for _, speciesKey in ipairs(Config.SpeciesOrder) do
	local modelSpec = Config.Species[speciesKey].CustomModel
	if modelSpec then
		findCustomModel(modelSpec)
	end
end

return CreatureAppearance
