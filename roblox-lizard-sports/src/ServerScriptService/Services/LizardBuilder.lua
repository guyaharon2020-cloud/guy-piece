-- Turns a stock R15/R6 character into a lizard: recolors the existing rig
-- (so every built-in walk/run/jump animation keeps working for free),
-- then bolts on a snout, eyes, a back spine ridge and a wagging tail.
--
-- The tail is real gameplay state, not just decoration: AbilityService
-- calls DropTail/RegrowTail/HasTail to run the tail-autotomy mechanic.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopData = require(ReplicatedStorage.Shared.ShopData)
local Constants = require(ReplicatedStorage.Shared.Constants)

local SKIN_TAG = Constants.TAG_SKIN_PART
local TAIL_TAG = Constants.TAG_TAIL_PART
local TAIL_SEGMENT_COUNT = 4

local LizardBuilder = {}

-- [character] = { material = Enum.Material } for skins that cycle color every frame.
local animatedCharacters = {}

local RIG_PART_NAMES = {
	-- R6
	"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
	-- R15
	"UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function getAnchor(character, ...)
	for _, name in ipairs({ ... }) do
		local inst = character:FindFirstChild(name)
		if inst and inst:IsA("BasePart") then
			return inst
		end
	end
	return nil
end

local function tagRigParts(character)
	for _, name in ipairs(RIG_PART_NAMES) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			CollectionService:AddTag(part, SKIN_TAG)
		end
	end
end

local function getVisualParts(character)
	local parts = {}
	for _, part in ipairs(CollectionService:GetTagged(SKIN_TAG)) do
		if part:IsDescendantOf(character) then
			table.insert(parts, part)
		end
	end
	return parts
end

local function removeAvatarClothing(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			child:Destroy()
		end
	end
	local head = character:FindFirstChild("Head")
	if head then
		local face = head:FindFirstChildOfClass("Decal")
		if face then
			face:Destroy()
		end
	end
end

local function buildSnout(character, head)
	local snout = Instance.new("Part")
	snout.Name = "LizardSnout"
	snout.Size = Vector3.new(head.Size.X * 0.55, head.Size.Y * 0.45, head.Size.Z * 0.8)
	snout.CanCollide = false
	snout.CastShadow = false
	snout.TopSurface = Enum.SurfaceType.Smooth
	snout.BottomSurface = Enum.SurfaceType.Smooth

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.75, 1.4)
	mesh.Parent = snout

	snout.CFrame = head.CFrame * CFrame.new(0, -head.Size.Y * 0.12, -(head.Size.Z / 2 + snout.Size.Z * 0.35))
	snout.Parent = character
	CollectionService:AddTag(snout, SKIN_TAG)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = snout
	weld.Parent = snout

	return snout
end

local function buildEyes(character, head)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "LizardEye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(head.Size.X * 0.22, head.Size.X * 0.22, head.Size.X * 0.22)
		eye.Color = Color3.fromRGB(255, 225, 50)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CanCollide = false
		eye.CastShadow = false
		eye.CFrame = head.CFrame * CFrame.new(side * head.Size.X * 0.32, head.Size.Y * 0.1, -head.Size.Z * 0.32)
		eye.Parent = character

		local pupil = Instance.new("Part")
		pupil.Name = "LizardPupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = eye.Size * 0.45
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.CanCollide = false
		pupil.CastShadow = false
		pupil.CFrame = eye.CFrame * CFrame.new(0, 0, -eye.Size.Z * 0.4)
		pupil.Parent = character

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye

		local pupilWeld = Instance.new("WeldConstraint")
		pupilWeld.Part0 = eye
		pupilWeld.Part1 = pupil
		pupilWeld.Parent = pupil
	end
end

local function buildSpineRidge(character, torso)
	for i = 1, 3 do
		local spike = Instance.new("Part")
		spike.Name = "LizardSpine"
		spike.Size = Vector3.new(torso.Size.X * 0.15, torso.Size.Y * 0.4, torso.Size.X * 0.15)
		spike.CanCollide = false
		spike.CastShadow = false

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(0.5, 1, 0.5)
		mesh.Parent = spike

		local zOffset = (i - 2) * torso.Size.Z * 0.35
		spike.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y * 0.55, zOffset)
		spike.Parent = character
		CollectionService:AddTag(spike, SKIN_TAG)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = spike
		weld.Parent = spike
	end
end

-- Builds a fresh Motor6D-jointed tail hanging off `anchor` (LowerTorso/Torso).
-- Kept separate from Build() so RegrowTail can call it again after autotomy.
local function buildTail(character, anchor)
	local tailModel = Instance.new("Model")
	tailModel.Name = "LizardTail"
	tailModel.Parent = character

	local baseSize = Vector3.new(anchor.Size.X * 0.35, anchor.Size.Y * 0.35, anchor.Size.Z * 0.5)
	local previousPart = anchor

	for i = 1, TAIL_SEGMENT_COUNT do
		local scale = 1 - (i - 1) * 0.18
		local size = Vector3.new(baseSize.X * scale, baseSize.Y * scale, baseSize.Z)

		local segment = Instance.new("Part")
		segment.Name = "TailSegment" .. i
		segment.Size = size
		segment.CanCollide = false
		segment.CastShadow = false
		segment.Massless = true

		local offsetDistance = previousPart.Size.Z / 2 + size.Z / 2
		-- previousPart's local -Z is "forward" (character facing direction), so +Z is behind it.
		segment.CFrame = previousPart.CFrame * CFrame.new(0, -size.Y * 0.15, offsetDistance)
		segment.Parent = tailModel
		CollectionService:AddTag(segment, SKIN_TAG)
		CollectionService:AddTag(segment, TAIL_TAG)
		segment:SetAttribute("TailIndex", i)

		local motor = Instance.new("Motor6D")
		motor.Name = "TailMotor" .. i
		motor.Part0 = previousPart
		motor.Part1 = segment
		motor.C0 = previousPart.CFrame:Inverse() * segment.CFrame
		motor.C1 = CFrame.new()
		motor.Parent = segment

		previousPart = segment
	end

	return tailModel
end

local function applySkinColor(parts, item)
	for _, part in ipairs(parts) do
		part.Color = item.color
		part.Material = item.material
	end
end

--- Builds the full lizard cosmetic rig onto a freshly spawned character.
function LizardBuilder.Build(character, skinId)
	removeAvatarClothing(character)
	tagRigParts(character)

	local head = character:FindFirstChild("Head")
	local torso = getAnchor(character, "UpperTorso", "Torso")
	local lowerAnchor = getAnchor(character, "LowerTorso", "Torso")

	if head then
		buildSnout(character, head)
		buildEyes(character, head)
	end

	if torso then
		buildSpineRidge(character, torso)
	end

	if lowerAnchor then
		buildTail(character, lowerAnchor)
	end

	LizardBuilder.ApplySkin(character, skinId)
end

--- Recolors the lizard (body + snout + ridge + tail). Handles animated skins.
function LizardBuilder.ApplySkin(character, skinId)
	local item = ShopData.findSkin(skinId) or ShopData.findSkin("classic_green")
	character:SetAttribute("EquippedSkinId", item.id)
	animatedCharacters[character] = nil

	if item.animated then
		animatedCharacters[character] = { material = item.material }
	else
		applySkinColor(getVisualParts(character), item)
	end
end

--- Fades the lizard toward transparent to mimic camouflage.
function LizardBuilder.SetCamo(character, active)
	local goal = { Transparency = active and Constants.CAMO_TRANSPARENCY or 0 }
	for _, part in ipairs(getVisualParts(character)) do
		TweenService:Create(part, TweenInfo.new(0.4), goal):Play()
	end
end

function LizardBuilder.HasTail(character)
	return character:FindFirstChild("LizardTail") ~= nil
end

--- Detaches the tail as a physical prop that tumbles away and disappears.
-- Returns false if the tail was already gone.
function LizardBuilder.DropTail(character)
	local tailModel = character:FindFirstChild("LizardTail")
	if not tailModel then
		return false
	end

	for _, motor in ipairs(tailModel:GetDescendants()) do
		if motor:IsA("Motor6D") then
			motor:Destroy()
		end
	end

	for _, part in ipairs(tailModel:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.Anchored = false
			part.Massless = false
			local spin = Instance.new("BodyAngularVelocity")
			spin.AngularVelocity = Vector3.new(math.random(-4, 4), math.random(-4, 4), math.random(-4, 4))
			spin.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			spin.Parent = part
		end
	end

	tailModel.Parent = workspace
	Debris:AddItem(tailModel, 4)
	return true
end

--- Grows a brand new tail back onto the character, colored to match the
-- currently equipped skin.
function LizardBuilder.RegrowTail(character)
	if LizardBuilder.HasTail(character) then
		return
	end

	local anchor = getAnchor(character, "LowerTorso", "Torso")
	if not anchor then
		return
	end

	local tailModel = buildTail(character, anchor)
	local skinId = character:GetAttribute("EquippedSkinId") or "classic_green"
	local item = ShopData.findSkin(skinId) or ShopData.findSkin("classic_green")

	if not item.animated then
		local segments = {}
		for _, part in ipairs(tailModel:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(segments, part)
			end
		end
		applySkinColor(segments, item)
	end
end

--- Starts the single shared loop that animates every rainbow/disco skin.
-- Call once from the server bootstrap.
function LizardBuilder.Init()
	RunService.Heartbeat:Connect(function()
		if next(animatedCharacters) == nil then
			return
		end
		local hue = (os.clock() * 0.15) % 1
		local color = Color3.fromHSV(hue, 1, 1)
		for character, info in pairs(animatedCharacters) do
			if character.Parent then
				for _, part in ipairs(getVisualParts(character)) do
					part.Color = color
					part.Material = info.material
				end
			else
				animatedCharacters[character] = nil
			end
		end
	end)
end

LizardBuilder.SKIN_TAG = SKIN_TAG
LizardBuilder.TAIL_TAG = TAIL_TAG

return LizardBuilder
