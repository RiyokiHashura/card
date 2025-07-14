--!strict
-- Client initialization
-- Sets up the service registry and loads all client controllers

-- Core framework
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServiceRegistry = require(ReplicatedStorage.Shared.Core.ServiceRegistry)

-- Controllers will be loaded here
local controllers = {}

-- Load Controllers (they auto-register themselves)
local TestSceneController = require(script.Controllers.TestSceneController)
local BattleController = require(script.Controllers.BattleController)
local AudioController = require(script.Controllers.AudioController)
local EffectsController = require(script.Controllers.EffectsController)
local PolishEffectsController = require(script.Controllers.PolishEffectsController)
local CardRevealTestController = require(script.Controllers.CardRevealTestController)
-- DISABLED: local CardRollController = require(script.Controllers.CardRollController) -- Causing banner UI issues
local CardRevealController = require(script.Controllers.CardRevealController)
local TestCombatController = require(script.Controllers.TestCombatController)

-- Load all controllers from the Controllers folder
local function loadControllers()
	local controllersFolder = script.Controllers
	if not controllersFolder then
		warn("Controllers folder not found")
		return
	end
	
	for _, controllerModule in pairs(controllersFolder:GetChildren()) do
		if controllerModule:IsA("ModuleScript") then
			local controllerName = controllerModule.Name
			local success, controller = pcall(require, controllerModule)
			
			if success then
				controllers[controllerName] = controller
				ServiceRegistry:RegisterService(controllerName, controller)
			else
				error("Failed to load controller: " .. controllerName .. " - " .. tostring(controller))
			end
		end
	end
end

-- Initialize the client
local function initializeClient()
	print("🎮 Starting Anime Card Clash Client...")
	
	-- Load all controllers
	loadControllers()
	
	-- Initialize controllers
	local success = ServiceRegistry:InitializeAll()
	if not success then
		error("Failed to initialize controllers")
	end
	
	-- Start controllers
	success = ServiceRegistry:StartAll()
	if not success then
		error("Failed to start controllers")
	end
	
	print("✅ Client initialized successfully!")
	
	-- List loaded controllers
	local controllerNames = {}
	for name in pairs(controllers) do
		table.insert(controllerNames, name)
	end
	print("📊 Controllers loaded:", table.concat(controllerNames, ", "))
end

-- Handle client cleanup (BindToClose only works on server)
-- Client cleanup will happen automatically when the player leaves

-- Start the client
initializeClient()

-- Export for debugging
_G.ServiceRegistry = ServiceRegistry
_G.Controllers = controllers