-- Worlds.lua
-- Defines the 5 unlockable worlds and every creature part available in each.
-- Kept data-only and declarative so designers can add parts without touching
-- any service code.

local Worlds = {}

-- Base stat point granted per stat key, scaled by a part's rarity tier.
-- (The pet's overall rarity multiplier, applied in PetStats.compute, is what
-- makes rarer *pets* dramatically stronger -- this table just keeps
-- individual parts within a world feeling meaningfully different.)
local BASE_BY_RARITY = {
	Common = 2,
	Uncommon = 3,
	Rare = 4,
	Epic = 6,
	Legendary = 9,
	Mythic = 14,
	Secret = 20,
}

-- Builds a statBonuses table: every key in `keys` gets the rarity's base
-- value, and Weirdness always gets at least half that (creature parts are
-- inherently a little weird).
local function stats(rarity, keys)
	local base = BASE_BY_RARITY[rarity]
	local bonuses = { Weirdness = math.floor(base * 0.5) }
	for _, key in ipairs(keys) do
		bonuses[key] = (bonuses[key] or 0) + base
	end
	return bonuses
end

local function part(id, name, rarity, slot, shape, color, statKeys, weirdness)
	return {
		id = id,
		name = name,
		rarity = rarity,
		slot = slot,
		shape = shape, -- "Ball" | "Block" | "Cylinder" | "Wedge" | "CornerWedge"
		color = color,
		statBonuses = stats(rarity, statKeys),
		weirdness = weirdness or 1,
	}
end

-- ===========================================================================
-- World 1: Backyard -- basic animal parts
-- ===========================================================================
local backyard = {
	Head = {
		part("bw_head_c1", "Dog Head", "Common", "Head", "Ball", Color3.fromRGB(163, 116, 74), { "Luck" }),
		part("bw_head_u1", "Frog Head", "Uncommon", "Head", "Ball", Color3.fromRGB(90, 180, 90), { "Luck", "Jump" }, 3),
		part("bw_head_r1", "Owl Head", "Rare", "Head", "Ball", Color3.fromRGB(140, 110, 70), { "Luck" }, 3),
		part("bw_head_e1", "Chicken Head", "Epic", "Head", "Ball", Color3.fromRGB(240, 230, 200), { "Luck", "Speed" }, 5),
	},
	Body = {
		part("bw_body_c1", "Cat Body", "Common", "Body", "Block", Color3.fromRGB(120, 120, 120), { "Strength" }),
		part("bw_body_u1", "Turtle Shell Body", "Uncommon", "Body", "Block", Color3.fromRGB(80, 140, 80), { "Strength" }, 2),
		part("bw_body_r1", "Bunny Body", "Rare", "Body", "Block", Color3.fromRGB(230, 230, 230), { "Strength", "Jump" }, 3),
		part("bw_body_e1", "Pig Body", "Epic", "Body", "Block", Color3.fromRGB(240, 170, 180), { "Strength" }, 4),
	},
	Legs = {
		part("bw_legs_c1", "Duck Legs", "Common", "Legs", "Cylinder", Color3.fromRGB(240, 200, 60), { "Speed" }),
		part("bw_legs_u1", "Spider Legs", "Uncommon", "Legs", "Cylinder", Color3.fromRGB(40, 40, 40), { "Speed" }, 4),
		part("bw_legs_r1", "Kangaroo Legs", "Rare", "Legs", "Cylinder", Color3.fromRGB(180, 130, 90), { "Jump" }, 3),
		part("bw_legs_e1", "Horse Legs", "Epic", "Legs", "Cylinder", Color3.fromRGB(90, 60, 40), { "Speed", "Jump" }, 3),
	},
	Eyes = {
		part("bw_eyes_c1", "Round Eyes", "Common", "Eyes", "Ball", Color3.fromRGB(0, 0, 0), { "Luck" }),
		part("bw_eyes_u1", "Bug Eyes", "Uncommon", "Eyes", "Ball", Color3.fromRGB(200, 30, 30), { "Luck" }, 4),
		part("bw_eyes_r1", "Cross Eyes", "Rare", "Eyes", "Ball", Color3.fromRGB(60, 60, 200), { "Luck", "Weirdness" }, 5),
		part("bw_eyes_e1", "Googly Eyes", "Epic", "Eyes", "Ball", Color3.fromRGB(255, 255, 255), { "Luck" }, 6),
	},
	Special = {
		part("bw_special_c1", "Feather Tuft", "Common", "Special", "Wedge", Color3.fromRGB(230, 230, 230), { "Jump" }),
		part("bw_special_u1", "Fluffy Tail", "Uncommon", "Special", "Ball", Color3.fromRGB(210, 180, 140), { "Speed" }, 3),
		part("bw_special_r1", "Extra Ear", "Rare", "Special", "Wedge", Color3.fromRGB(163, 116, 74), { "Luck" }, 4),
		part("bw_special_e1", "Tiny Wings", "Epic", "Special", "CornerWedge", Color3.fromRGB(255, 255, 255), { "Jump", "Speed" }, 5),
	},
	Ability = {
		part("bw_ability_c1", "Bark", "Common", "Ability", "Ball", Color3.fromRGB(180, 180, 180), { "Strength" }),
		part("bw_ability_u1", "Hop Boost", "Uncommon", "Ability", "Ball", Color3.fromRGB(90, 220, 90), { "Jump" }, 3),
		part("bw_ability_r1", "Night Vision", "Rare", "Ability", "Ball", Color3.fromRGB(60, 60, 160), { "Luck" }, 3),
		part("bw_ability_e1", "Cluck Charm", "Epic", "Ability", "Ball", Color3.fromRGB(240, 230, 200), { "Luck", "Strength" }, 5),
	},
}

-- ===========================================================================
-- World 2: Laboratory -- robot, mutant and science parts
-- ===========================================================================
local laboratory = {
	Head = {
		part("lb_head_c1", "Robot Head", "Common", "Head", "Block", Color3.fromRGB(150, 150, 160), { "Strength" }),
		part("lb_head_u1", "Beaker Head", "Uncommon", "Head", "Cylinder", Color3.fromRGB(120, 220, 160), { "Weirdness" }, 5),
		part("lb_head_r1", "Camera Lens Head", "Rare", "Head", "Ball", Color3.fromRGB(40, 40, 40), { "Luck" }, 4),
		part("lb_head_e1", "Mutant Brain Head", "Epic", "Head", "Ball", Color3.fromRGB(220, 130, 180), { "Luck", "Weirdness" }, 7),
	},
	Body = {
		part("lb_body_c1", "Tin Can Body", "Common", "Body", "Cylinder", Color3.fromRGB(180, 180, 190), { "Strength" }),
		part("lb_body_u1", "Battery Body", "Uncommon", "Body", "Block", Color3.fromRGB(60, 200, 90), { "Strength" }, 3),
		part("lb_body_r1", "Reactor Body", "Rare", "Body", "Cylinder", Color3.fromRGB(240, 200, 40), { "Strength" }, 5),
		part("lb_body_e1", "Mutated Torso", "Epic", "Body", "Block", Color3.fromRGB(150, 220, 100), { "Strength", "Weirdness" }, 7),
	},
	Legs = {
		part("lb_legs_c1", "Piston Legs", "Common", "Legs", "Cylinder", Color3.fromRGB(120, 120, 130), { "Speed" }),
		part("lb_legs_u1", "Wheel Legs", "Uncommon", "Legs", "Cylinder", Color3.fromRGB(40, 40, 40), { "Speed" }, 3),
		part("lb_legs_r1", "Hydraulic Legs", "Rare", "Legs", "Cylinder", Color3.fromRGB(200, 60, 60), { "Jump", "Strength" }, 4),
		part("lb_legs_e1", "Spring Legs", "Epic", "Legs", "Cylinder", Color3.fromRGB(220, 220, 40), { "Jump" }, 6),
	},
	Eyes = {
		part("lb_eyes_c1", "LED Eyes", "Common", "Eyes", "Ball", Color3.fromRGB(220, 30, 30), { "Luck" }),
		part("lb_eyes_u1", "Scanner Eye", "Uncommon", "Eyes", "Ball", Color3.fromRGB(30, 220, 220), { "Luck" }, 4),
		part("lb_eyes_r1", "X-Ray Eyes", "Rare", "Eyes", "Ball", Color3.fromRGB(180, 220, 255), { "Luck", "Weirdness" }, 5),
		part("lb_eyes_e1", "Third Eye", "Epic", "Eyes", "Ball", Color3.fromRGB(220, 80, 220), { "Luck" }, 8),
	},
	Special = {
		part("lb_special_c1", "Antenna", "Common", "Special", "Cylinder", Color3.fromRGB(120, 120, 120), { "Luck" }),
		part("lb_special_u1", "Exhaust Pipe", "Uncommon", "Special", "Cylinder", Color3.fromRGB(80, 80, 80), { "Strength" }, 3),
		part("lb_special_r1", "Tesla Coil", "Rare", "Special", "Cylinder", Color3.fromRGB(120, 200, 255), { "Weirdness" }, 6),
		part("lb_special_e1", "Extra Arm", "Epic", "Special", "Block", Color3.fromRGB(180, 180, 190), { "Strength" }, 6),
	},
	Ability = {
		part("lb_ability_c1", "Beep", "Common", "Ability", "Ball", Color3.fromRGB(150, 150, 160), { "Luck" }),
		part("lb_ability_u1", "Overclock", "Uncommon", "Ability", "Ball", Color3.fromRGB(240, 100, 40), { "Speed" }, 4),
		part("lb_ability_r1", "Shock Zap", "Rare", "Ability", "Ball", Color3.fromRGB(120, 200, 255), { "Strength" }, 5),
		part("lb_ability_e1", "Self Repair", "Epic", "Ability", "Ball", Color3.fromRGB(90, 220, 90), { "Strength", "Luck" }, 6),
	},
}

-- ===========================================================================
-- World 3: Alien Planet -- alien and space parts
-- ===========================================================================
local alienPlanet = {
	Head = {
		part("ap_head_c1", "Alien Head", "Common", "Head", "Ball", Color3.fromRGB(120, 220, 120), { "Weirdness" }),
		part("ap_head_u1", "Bug Alien Head", "Uncommon", "Head", "Ball", Color3.fromRGB(80, 180, 200), { "Luck" }, 5),
		part("ap_head_r1", "Astronaut Helmet Head", "Rare", "Head", "Ball", Color3.fromRGB(230, 230, 230), { "Luck" }, 4),
		part("ap_head_e1", "Tentacle Head", "Epic", "Head", "Ball", Color3.fromRGB(160, 60, 200), { "Weirdness", "Luck" }, 8),
	},
	Body = {
		part("ap_body_c1", "Green Alien Body", "Common", "Body", "Block", Color3.fromRGB(120, 220, 120), { "Strength" }),
		part("ap_body_u1", "Crystal Alien Body", "Uncommon", "Body", "Block", Color3.fromRGB(120, 200, 255), { "Strength" }, 4),
		part("ap_body_r1", "UFO Body", "Rare", "Body", "Cylinder", Color3.fromRGB(200, 200, 210), { "Strength", "Speed" }, 6),
		part("ap_body_e1", "Nebula Body", "Epic", "Body", "Block", Color3.fromRGB(160, 60, 200), { "Strength" }, 8),
	},
	Legs = {
		part("ap_legs_c1", "Slime Legs", "Common", "Legs", "Cylinder", Color3.fromRGB(120, 220, 120), { "Speed" }),
		part("ap_legs_u1", "Crab Legs", "Uncommon", "Legs", "Cylinder", Color3.fromRGB(220, 90, 40), { "Speed" }, 4),
		part("ap_legs_r1", "Anti-Grav Legs", "Rare", "Legs", "Cylinder", Color3.fromRGB(120, 200, 255), { "Jump" }, 6),
		part("ap_legs_e1", "Comet Tail Legs", "Epic", "Legs", "Cylinder", Color3.fromRGB(220, 220, 255), { "Speed", "Jump" }, 8),
	},
	Eyes = {
		part("ap_eyes_c1", "Alien Eyes", "Common", "Eyes", "Ball", Color3.fromRGB(0, 0, 0), { "Luck" }),
		part("ap_eyes_u1", "Compound Eyes", "Uncommon", "Eyes", "Ball", Color3.fromRGB(80, 180, 200), { "Luck" }, 5),
		part("ap_eyes_r1", "Star Eyes", "Rare", "Eyes", "Ball", Color3.fromRGB(255, 240, 120), { "Luck", "Weirdness" }, 6),
		part("ap_eyes_e1", "Void Eyes", "Epic", "Eyes", "Ball", Color3.fromRGB(20, 0, 40), { "Luck" }, 9),
	},
	Special = {
		part("ap_special_c1", "Antenna Pair", "Common", "Special", "Cylinder", Color3.fromRGB(120, 220, 120), { "Luck" }),
		part("ap_special_u1", "Ray Gun", "Uncommon", "Special", "Block", Color3.fromRGB(120, 200, 255), { "Strength" }, 4),
		part("ap_special_r1", "Jetpack", "Rare", "Special", "Block", Color3.fromRGB(200, 200, 210), { "Speed", "Jump" }, 6),
		part("ap_special_e1", "Portal Ring", "Epic", "Special", "Cylinder", Color3.fromRGB(160, 60, 200), { "Weirdness" }, 9),
	},
	Ability = {
		part("ap_ability_c1", "Zap", "Common", "Ability", "Ball", Color3.fromRGB(120, 220, 120), { "Strength" }),
		part("ap_ability_u1", "Teleport", "Uncommon", "Ability", "Ball", Color3.fromRGB(120, 200, 255), { "Speed" }, 5),
		part("ap_ability_r1", "Mind Beam", "Rare", "Ability", "Ball", Color3.fromRGB(160, 60, 200), { "Luck" }, 6),
		part("ap_ability_e1", "Gravity Pulse", "Epic", "Ability", "Ball", Color3.fromRGB(220, 220, 255), { "Jump", "Strength" }, 8),
	},
}

-- ===========================================================================
-- World 4: Volcano -- fire and lava parts
-- ===========================================================================
local volcano = {
	Head = {
		part("vc_head_r1", "Ember Head", "Rare", "Head", "Ball", Color3.fromRGB(230, 100, 30), { "Strength" }, 4),
		part("vc_head_e1", "Magma Head", "Epic", "Head", "Ball", Color3.fromRGB(240, 60, 20), { "Strength", "Weirdness" }, 6),
		part("vc_head_l1", "Dragon Head", "Legendary", "Head", "Ball", Color3.fromRGB(200, 30, 20), { "Strength", "Luck" }, 9),
		part("vc_head_m1", "Phoenix Head", "Mythic", "Head", "Ball", Color3.fromRGB(255, 150, 30), { "Strength", "Luck", "Weirdness" }, 12),
	},
	Body = {
		part("vc_body_r1", "Obsidian Body", "Rare", "Body", "Block", Color3.fromRGB(40, 30, 30), { "Strength" }, 4),
		part("vc_body_e1", "Lava Core Body", "Epic", "Body", "Block", Color3.fromRGB(240, 90, 20), { "Strength" }, 7),
		part("vc_body_l1", "Ash Golem Body", "Legendary", "Body", "Block", Color3.fromRGB(90, 80, 80), { "Strength", "Jump" }, 8),
		part("vc_body_m1", "Molten Core Body", "Mythic", "Body", "Block", Color3.fromRGB(255, 120, 20), { "Strength", "Weirdness" }, 13),
	},
	Legs = {
		part("vc_legs_r1", "Charred Legs", "Rare", "Legs", "Cylinder", Color3.fromRGB(60, 40, 30), { "Speed" }, 4),
		part("vc_legs_e1", "Lava Strider Legs", "Epic", "Legs", "Cylinder", Color3.fromRGB(240, 90, 20), { "Speed", "Jump" }, 7),
		part("vc_legs_l1", "Dragon Claw Legs", "Legendary", "Legs", "Cylinder", Color3.fromRGB(200, 30, 20), { "Jump" }, 9),
		part("vc_legs_m1", "Meteor Legs", "Mythic", "Legs", "Cylinder", Color3.fromRGB(255, 150, 30), { "Speed", "Jump" }, 12),
	},
	Eyes = {
		part("vc_eyes_r1", "Ember Eyes", "Rare", "Eyes", "Ball", Color3.fromRGB(240, 90, 20), { "Luck" }, 5),
		part("vc_eyes_e1", "Molten Eyes", "Epic", "Eyes", "Ball", Color3.fromRGB(255, 60, 20), { "Luck", "Weirdness" }, 7),
		part("vc_eyes_l1", "Dragon Eyes", "Legendary", "Eyes", "Ball", Color3.fromRGB(200, 30, 20), { "Luck" }, 9),
		part("vc_eyes_m1", "Solar Flare Eyes", "Mythic", "Eyes", "Ball", Color3.fromRGB(255, 200, 60), { "Luck", "Weirdness" }, 13),
	},
	Special = {
		part("vc_special_r1", "Lava Vents", "Rare", "Special", "Cylinder", Color3.fromRGB(240, 90, 20), { "Strength" }, 5),
		part("vc_special_e1", "Fire Wings", "Epic", "Special", "CornerWedge", Color3.fromRGB(240, 60, 20), { "Jump", "Speed" }, 8),
		part("vc_special_l1", "Dragon Wings", "Legendary", "Special", "CornerWedge", Color3.fromRGB(200, 30, 20), { "Jump", "Strength" }, 9),
		part("vc_special_m1", "Solar Corona", "Mythic", "Special", "Ball", Color3.fromRGB(255, 200, 60), { "Weirdness" }, 13),
	},
	Ability = {
		part("vc_ability_r1", "Fireball", "Rare", "Ability", "Ball", Color3.fromRGB(240, 90, 20), { "Strength" }, 5),
		part("vc_ability_e1", "Eruption", "Epic", "Ability", "Ball", Color3.fromRGB(255, 60, 20), { "Strength", "Weirdness" }, 8),
		part("vc_ability_l1", "Dragon Roar", "Legendary", "Ability", "Ball", Color3.fromRGB(200, 30, 20), { "Strength", "Luck" }, 9),
		part("vc_ability_m1", "Rebirth Flame", "Mythic", "Ability", "Ball", Color3.fromRGB(255, 150, 30), { "Luck", "Strength" }, 13),
	},
}

-- ===========================================================================
-- World 5: Glitch World -- extremely strange and corrupted parts
-- ===========================================================================
local glitchWorld = {
	Head = {
		part("gw_head_l1", "Corrupted Head", "Legendary", "Head", "Block", Color3.fromRGB(10, 10, 10), { "Weirdness" }, 12),
		part("gw_head_m1", "Pixelated Head", "Mythic", "Head", "Block", Color3.fromRGB(0, 255, 100), { "Weirdness", "Luck" }, 15),
		part("gw_head_s1", "Error Head", "Secret", "Head", "Block", Color3.fromRGB(255, 0, 0), { "Weirdness", "Luck", "Strength" }, 25),
	},
	Body = {
		part("gw_body_l1", "Static Body", "Legendary", "Body", "Block", Color3.fromRGB(20, 20, 20), { "Strength" }, 12),
		part("gw_body_m1", "Wireframe Body", "Mythic", "Body", "Block", Color3.fromRGB(0, 255, 100), { "Strength", "Weirdness" }, 15),
		part("gw_body_s1", "404 Body", "Secret", "Body", "Block", Color3.fromRGB(255, 0, 0), { "Strength", "Weirdness" }, 25),
	},
	Legs = {
		part("gw_legs_l1", "Lag Spike Legs", "Legendary", "Legs", "Cylinder", Color3.fromRGB(10, 10, 10), { "Speed" }, 12),
		part("gw_legs_m1", "Rendered Legs", "Mythic", "Legs", "Cylinder", Color3.fromRGB(0, 255, 100), { "Speed", "Jump" }, 15),
		part("gw_legs_s1", "Null Legs", "Secret", "Legs", "Cylinder", Color3.fromRGB(255, 0, 0), { "Speed", "Jump" }, 25),
	},
	Eyes = {
		part("gw_eyes_l1", "Static Eyes", "Legendary", "Eyes", "Ball", Color3.fromRGB(20, 20, 20), { "Luck" }, 13),
		part("gw_eyes_m1", "Buffering Eyes", "Mythic", "Eyes", "Ball", Color3.fromRGB(0, 255, 100), { "Luck", "Weirdness" }, 16),
		part("gw_eyes_s1", "Unknown Eyes", "Secret", "Eyes", "Ball", Color3.fromRGB(255, 0, 0), { "Luck", "Weirdness" }, 25),
	},
	Special = {
		part("gw_special_l1", "Clipping Wings", "Legendary", "Special", "CornerWedge", Color3.fromRGB(10, 10, 10), { "Jump" }, 13),
		part("gw_special_m1", "Duplicate Limb", "Mythic", "Special", "Block", Color3.fromRGB(0, 255, 100), { "Strength", "Weirdness" }, 16),
		part("gw_special_s1", "Question Mark", "Secret", "Special", "Ball", Color3.fromRGB(255, 0, 0), { "Weirdness" }, 30),
	},
	Ability = {
		part("gw_ability_l1", "Crash", "Legendary", "Ability", "Ball", Color3.fromRGB(10, 10, 10), { "Strength" }, 13),
		part("gw_ability_m1", "Rewind", "Mythic", "Ability", "Ball", Color3.fromRGB(0, 255, 100), { "Luck", "Speed" }, 16),
		part("gw_ability_s1", "Delete", "Secret", "Ability", "Ball", Color3.fromRGB(255, 0, 0), { "Strength", "Luck", "Weirdness" }, 30),
	},
}

Worlds.List = {
	{
		id = "Backyard",
		name = "Backyard",
		order = 1,
		unlockCost = 0, -- starting world
		parts = backyard,
	},
	{
		id = "Laboratory",
		name = "Laboratory",
		order = 2,
		unlockCost = 500,
		parts = laboratory,
	},
	{
		id = "AlienPlanet",
		name = "Alien Planet",
		order = 3,
		unlockCost = 3000,
		parts = alienPlanet,
	},
	{
		id = "Volcano",
		name = "Volcano",
		order = 4,
		unlockCost = 15000,
		parts = volcano,
	},
	{
		id = "GlitchWorld",
		name = "Glitch World",
		order = 5,
		unlockCost = 75000,
		parts = glitchWorld,
	},
}

local byId = {}
for _, world in ipairs(Worlds.List) do
	byId[world.id] = world
end

function Worlds.get(id)
	return byId[id]
end

-- Flat lookup of every part in the game by id, used to validate/resolve
-- part ids coming back from the client and to rehydrate saved inventories.
Worlds.PartById = {}
for _, world in ipairs(Worlds.List) do
	for _, slotParts in pairs(world.parts) do
		for _, p in ipairs(slotParts) do
			Worlds.PartById[p.id] = p
		end
	end
end

return Worlds
