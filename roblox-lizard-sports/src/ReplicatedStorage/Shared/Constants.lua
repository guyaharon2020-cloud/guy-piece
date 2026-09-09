-- Shared tuning values for movement, stamina and ability cooldowns.
-- Both server (authoritative) and client (prediction/UI) read this table.

local Constants = {
	BASE_WALKSPEED = 16,
	SPRINT_SPEED_MULTIPLIER = 1.8,

	BASE_STAMINA = 100,
	STAMINA_DRAIN_PER_SEC = 20,
	STAMINA_REGEN_PER_SEC = 8,
	BASKING_REGEN_MULTIPLIER = 3, -- lizards are ectothermic: sunlight recharges them much faster
	MIN_STAMINA_TO_SPRINT = 5,

	BASE_TONGUE_RANGE = 20,
	TONGUE_COOLDOWN = 1.5,

	BASE_CAMO_DURATION = 5,
	BASE_CAMO_COOLDOWN = 15,
	CAMO_TRANSPARENCY = 0.65,

	BASE_TAIL_REGROW_TIME = 30,
	TAIL_DROP_INVULNERABILITY = 1.5,
	TAIL_DETACHED_SPEED_PENALTY = 0.7, -- multiplier applied to climb/sprint while tail is gone

	BASE_CLIMB_SPEED = 12,

	STATS_UPDATE_INTERVAL = 0.2,

	-- CollectionService tags shared between server (tags things) and client
	-- (finds things to animate, e.g. the idle tail wag).
	TAG_SKIN_PART = "LizardSkinPart",
	TAG_TAIL_PART = "LizardTailPart",
}

return Constants
