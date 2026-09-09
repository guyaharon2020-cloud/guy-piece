-- Server bootstrap: builds the world, then starts every service in the
-- order that keeps their dependencies satisfied.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Services = script.Parent:WaitForChild("Services")

local MapBuilder = require(Services.MapBuilder)
local LizardBuilder = require(Services.LizardBuilder)
local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)
local AbilityService = require(Services.AbilityService)
local CharacterService = require(Services.CharacterService)

local Events = Services:WaitForChild("Events")
local BugHuntEvent = require(Events.BugHuntEvent)
local SprintDashEvent = require(Events.SprintDashEvent)
local ClimbTowerEvent = require(Events.ClimbTowerEvent)

MapBuilder.Build()
LizardBuilder.Init()
DataService.Init(Remotes)
ShopService.Init(Remotes)
AbilityService.Init(Remotes)
BugHuntEvent.Init(Remotes)
SprintDashEvent.Init(Remotes)
ClimbTowerEvent.Init(Remotes)
CharacterService.Init()

print("[LizardSportsLegend] Server ready.")
