--!strict
-- Server initialization
-- Sets up the service registry and loads all server services

-- Core framework
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServiceRegistry = require(ReplicatedStorage.Shared.Core.ServiceRegistry)

-- Services will be loaded here
local services = {}

-- Load Services
local AudioService = require(script.Services.AudioService)
-- local AudioTestService = require(script.Services.AudioTestService)
local BattleService = require(script.Services.BattleService)
-- local BattleTestService = require(script.Services.BattleTestService)
local CardRollService = require(script.Services.CardRollService)
-- local CardRollTestService = require(script.Services.CardRollTestService)
-- local CardTestService = require(script.Services.CardTestService) -- Disabling to prevent server crash
local PlayerDataService = require(script.Services.PlayerDataService)
-- local PlayerDataTestService = require(script.Services.PlayerDataTestService)
local PolishEffectsService = require(script.Services.PolishEffectsService)
-- local PolishEffectsTestService = require(script.Services.PolishEffectsTestService)

-- Load all services from the Services folder
local function loadServices()
	local servicesFolder = script.Services
	if not servicesFolder then
		warn("Services folder not found")
		return
	end
	
	-- Skip test services to prevent crashes
	local testServices = {
		"AudioTestService",
		"BattleTestService", 
		"CardRollTestService",
		"CardTestService",
		"PlayerDataTestService",
		"PolishEffectsTestService",
	}
	
	for _, serviceModule in pairs(servicesFolder:GetChildren()) do
		if serviceModule:IsA("ModuleScript") then
			local serviceName = serviceModule.Name
			
			-- Skip test services
			local isTestService = false
			for _, testService in pairs(testServices) do
				if serviceName == testService then
					isTestService = true
					break
				end
			end
			
			if not isTestService then
				local success, service = pcall(require, serviceModule)
				
				if success then
					services[serviceName] = service
					ServiceRegistry:RegisterService(serviceName, service)
				else
					error("Failed to load service: " .. serviceName .. " - " .. tostring(service))
				end
			end
		end
	end
end

-- Initialize the server
local function initializeServer()
	print("🚀 Starting Anime Card Clash Server...")
	
	-- Load all services
	loadServices()
	
	-- Initialize services
	local success = ServiceRegistry:InitializeAll()
	if not success then
		error("Failed to initialize services")
	end
	
	-- Start services
	success = ServiceRegistry:StartAll()
	if not success then
		error("Failed to start services")
	end
	
	print("✅ Server initialized successfully!")
	
	-- List loaded services
	local serviceNames = {}
	for name in pairs(services) do
		table.insert(serviceNames, name)
	end
	print("📊 Services loaded:", table.concat(serviceNames, ", "))
end

-- Handle server shutdown
game:BindToClose(function()
	print("🛑 Server shutting down...")
	ServiceRegistry:StopAll()
	ServiceRegistry:Cleanup()
	print("✅ Server shutdown complete")
end)

-- Start the server
initializeServer()

-- Export for debugging
_G.ServiceRegistry = ServiceRegistry
_G.Services = services