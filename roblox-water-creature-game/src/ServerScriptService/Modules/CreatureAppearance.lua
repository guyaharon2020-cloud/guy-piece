-- Makes the player's default Roblox character look like a fish: strips
-- normal clothing/accessories, recolors the body per evolution tier, and
-- welds on a few cosmetic fin parts. Runs entirely with primitive Parts —
-- no custom mesh/asset upload is needed (and none is available from here).
--
-- Kept deliberately simple: fins are rigidly welded to the torso, so they
-- won't deform with walk/swim animations, but they read fine at a glance
-- and need zero external assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.GameConfig)

local CreatureAppearance = {}

local function getTorso(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local function attachFin(character, torso, name, size, color, offset)
	local fin = Instance.new("WedgePart")
	fin.Name = name
	fin.Size = size
	fin.Color = color
	fin.Material = Enum.Material.SmoothPlastic
	fin.CanCollide = false
	fin.CanQuery = false
	fin.Massless = true
	fin.CFrame = torso.CFrame * offset
	fin.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = fin
	weld.Parent = fin

	return fin
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

	local leaderstats = player:FindFirstChild("leaderstats")
	local tierIndex = (leaderstats and leaderstats.Evolution.Value or 0) + 1
	local tier = Config.EvolutionTiers[math.clamp(tierIndex, 1, #Config.EvolutionTiers)]

	local consumables = player:FindFirstChild("Consumables")
	local goldenScales = consumables and consumables:FindFirstChild("GoldenScales")
	local bodyColor = (goldenScales and goldenScales.Value) and Color3.fromRGB(230, 190, 60) or tier.Color

	local bodyColors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bodyColors.HeadColor3 = bodyColor
	bodyColors.TorsoColor3 = bodyColor
	bodyColors.LeftArmColor3 = bodyColor
	bodyColors.RightArmColor3 = bodyColor
	bodyColors.LeftLegColor3 = bodyColor
	bodyColors.RightLegColor3 = bodyColor
	bodyColors.Parent = character

	local existingFins = character:FindFirstChild("CreatureFins")
	if existingFins then
		existingFins:Destroy()
	end

	local finsFolder = Instance.new("Folder")
	finsFolder.Name = "CreatureFins"

	local finColor = tier.FinColor
	local s = tier.FinScale

	attachFin(character, torso, "TailFin", Vector3.new(0.4, 2.2 * s, 3 * s), finColor, CFrame.new(0, -0.5, 1.4) * CFrame.Angles(0, math.rad(180), 0)).Parent = finsFolder
	attachFin(character, torso, "DorsalFin", Vector3.new(0.4, 1.6 * s, 1.6 * s), finColor, CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))).Parent = finsFolder
	attachFin(character, torso, "LeftFin", Vector3.new(1.4 * s, 0.3, 1 * s), finColor, CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(20))).Parent = finsFolder
	attachFin(character, torso, "RightFin", Vector3.new(1.4 * s, 0.3, 1 * s), finColor, CFrame.new(1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(-20))).Parent = finsFolder

	finsFolder.Parent = character
end

return CreatureAppearance
