-- Shared tuning values for the water-creature game.
-- Edit these to change difficulty, spawn rates, and progression pace.

local Config = {}

-- World / water
Config.WaterCenter = Vector3.new(0, -10, 0)
Config.WaterSize = Vector3.new(1000, 60, 1000)

-- Raft spawning
Config.RaftSpawnInterval = 8 -- seconds between spawn attempts
Config.MaxRafts = 12 -- rafts alive at once
Config.SpawnRadius = 400 -- studs from the water center
Config.HumansPerRaftMin = 2
Config.HumansPerRaftMax = 6

-- Economy: destroying a raft pays out per human that was on it
Config.MoneyPerHuman = 1
Config.XPPerHuman = 10

-- Leveling: swim speed and size grow with level
Config.BaseWalkSpeed = 40
Config.WalkSpeedPerLevel = 3
Config.SizePerLevel = 0.03 -- +3% scale per level
Config.MaxLevel = 50

-- XP required to go from `level` to `level + 1`
function Config.XPForLevel(level)
	return math.floor(100 * level ^ 1.35)
end

return Config
