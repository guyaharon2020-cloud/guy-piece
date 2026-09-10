-- SecretPets.lua
-- Curated, hand-picked six-part combinations that get a special name and a
-- server-wide announcement instead of an auto-generated one. Discovering one
-- of these should feel like winning the lottery.

local Worlds = require(script.Parent:WaitForChild("Worlds"))
local PetStats = require(script.Parent:WaitForChild("PetStats"))

local SecretPets = {}

local function combo(partIds)
	local parts = {}
	for slot, id in pairs(partIds) do
		parts[slot] = Worlds.PartById[id]
		assert(parts[slot], ("SecretPets: unknown part id '%s' for slot %s"):format(id, slot))
	end
	return PetStats.comboId(parts)
end

local DEFINITIONS = {
	{
		name = "The Error",
		parts = {
			Head = "gw_head_s1",
			Body = "gw_body_s1",
			Legs = "gw_legs_s1",
			Eyes = "gw_eyes_s1",
			Special = "gw_special_s1",
			Ability = "gw_ability_s1",
		},
	},
	{
		name = "Void Frog",
		parts = {
			Head = "bw_head_u1",
			Body = "gw_body_s1",
			Legs = "gw_legs_s1",
			Eyes = "gw_eyes_m1",
			Special = "gw_special_m1",
			Ability = "gw_ability_m1",
		},
	},
	{
		name = "Mega Chicken",
		parts = {
			Head = "bw_head_e1",
			Body = "vc_body_m1",
			Legs = "vc_legs_m1",
			Eyes = "bw_eyes_e1",
			Special = "vc_special_m1",
			Ability = "vc_ability_m1",
		},
	},
	{
		name = "Unknown",
		parts = {
			Head = "gw_head_m1",
			Body = "gw_body_m1",
			Legs = "gw_legs_m1",
			Eyes = "gw_eyes_m1",
			Special = "gw_special_m1",
			Ability = "gw_ability_m1",
		},
	},
	{
		name = "???",
		parts = {
			Head = "ap_head_e1",
			Body = "vc_body_l1",
			Legs = "lb_legs_e1",
			Eyes = "gw_eyes_s1",
			Special = "ap_special_e1",
			Ability = "gw_ability_s1",
		},
	},
}

-- comboId -> secret pet name
SecretPets.ByComboId = {}
for _, def in ipairs(DEFINITIONS) do
	SecretPets.ByComboId[combo(def.parts)] = def.name
end

-- Returns the secret name for a comboId, or nil if it's not a curated secret.
function SecretPets.lookup(comboId)
	return SecretPets.ByComboId[comboId]
end

return SecretPets
