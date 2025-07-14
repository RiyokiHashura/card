--!strict
-- ServiceRegistry.luau
-- Core service registry for modular architecture
-- Handles service initialization, dependencies, and lifecycle management

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

-- Service states
local ServiceState = {
	Uninitialized = "Uninitialized",
	Initializing = "Initializing", 
	Initialized = "Initialized",
	Starting = "Starting",
	Started = "Started",
	Stopped = "Stopped",
	Error = "Error"
}

-- Private storage
local services = {}
local serviceStates = {}
local initializationQueue = {}
local isStarted = false

-- Debug logging
local DEBUG_ENABLED = game:GetService("RunService"):IsStudio()

local function debugLog(message: string, data: any?)
	if not DEBUG_ENABLED then return end
	
	local timestamp = os.date("%H:%M:%S")
	if data then
		print(string.format("[%s] [ServiceRegistry] %s", timestamp, message), data)
	else
		print(string.format("[%s] [ServiceRegistry] %s", timestamp, message))
	end
end

-- Service registry methods
function ServiceRegistry:RegisterService(serviceName: string, service: any): any
	assert(type(serviceName) == "string", "Service name must be a string")
	assert(service, "Service cannot be nil")
	assert(not services[serviceName], "Service already exists: " .. serviceName)
	assert(not isStarted, "Cannot register services after ServiceRegistry has started")
	
	-- Set service metadata
	service.Name = serviceName
	service._isService = true
	service.ServiceRegistry = ServiceRegistry -- Add this line so services can access other services
	
	-- Store service
	services[serviceName] = service
	serviceStates[serviceName] = ServiceState.Uninitialized
	
	debugLog("Registered service: " .. serviceName)
	return service
end

function ServiceRegistry:GetService(serviceName: string): any
	assert(type(serviceName) == "string", "Service name must be a string")
	
	local service = services[serviceName]
	if not service then
		error("Service not found: " .. serviceName)
	end
	
	return service
end

function ServiceRegistry:GetServiceState(serviceName: string): string
	assert(type(serviceName) == "string", "Service name must be a string")
	return serviceStates[serviceName] or ServiceState.Uninitialized
end

function ServiceRegistry:GetAllServices(): {[string]: any}
	local servicesCopy = {}
	for name, service in pairs(services) do
		servicesCopy[name] = service
	end
	return servicesCopy
end

function ServiceRegistry:InitializeAll(): boolean
	if isStarted then
		warn("ServiceRegistry already started")
		return false
	end
	
	debugLog("Initializing all services...")
	
	-- Initialize services with dependency resolution
	local initialized = {}
	local function initializeService(serviceName: string)
		if initialized[serviceName] then
			return true
		end
		
		local service = services[serviceName]
		if not service then
			error("Service not found during initialization: " .. serviceName)
		end
		
		-- Skip if already initialized
		if serviceStates[serviceName] == ServiceState.Initialized then
			initialized[serviceName] = true
			return true
		end
		
		-- Set initializing state
		serviceStates[serviceName] = ServiceState.Initializing
		debugLog("Initializing service: " .. serviceName)
		
		-- Initialize dependencies first
		if service.Dependencies then
			for _, depName in ipairs(service.Dependencies) do
				if not initializeService(depName) then
					serviceStates[serviceName] = ServiceState.Error
					error("Failed to initialize dependency: " .. depName .. " for service: " .. serviceName)
				end
			end
		end
		
		-- Initialize the service
		local success, result = pcall(function()
			if service.Initialize then
				service:Initialize()
			end
		end)
		
		if success then
			serviceStates[serviceName] = ServiceState.Initialized
			initialized[serviceName] = true
			debugLog("Successfully initialized service: " .. serviceName)
			return true
		else
			serviceStates[serviceName] = ServiceState.Error
			error("Failed to initialize service: " .. serviceName .. " - " .. tostring(result))
		end
	end
	
	-- Initialize all services
	for serviceName in pairs(services) do
		if not initialized[serviceName] then
			initializeService(serviceName)
		end
	end
	
	debugLog("All services initialized successfully")
	return true
end

function ServiceRegistry:StartAll(): boolean
	if isStarted then
		warn("ServiceRegistry already started")
		return false
	end
	
	debugLog("Starting all services...")
	
	-- Start all services
	for serviceName, service in pairs(services) do
		if serviceStates[serviceName] == ServiceState.Initialized then
			serviceStates[serviceName] = ServiceState.Starting
			debugLog("Starting service: " .. serviceName)
			
			local success, result = pcall(function()
				if service.Start then
					service:Start()
				end
			end)
			
			if success then
				serviceStates[serviceName] = ServiceState.Started
				debugLog("Successfully started service: " .. serviceName)
			else
				serviceStates[serviceName] = ServiceState.Error
				error("Failed to start service: " .. serviceName .. " - " .. tostring(result))
			end
		end
	end
	
	isStarted = true
	debugLog("All services started successfully")
	return true
end

function ServiceRegistry:StopAll(): boolean
	if not isStarted then
		warn("ServiceRegistry not started")
		return false
	end
	
	debugLog("Stopping all services...")
	
	-- Stop all services in reverse order
	local serviceNames = {}
	for serviceName in pairs(services) do
		table.insert(serviceNames, serviceName)
	end
	
	for i = #serviceNames, 1, -1 do
		local serviceName = serviceNames[i]
		local service = services[serviceName]
		
		if serviceStates[serviceName] == ServiceState.Started then
			debugLog("Stopping service: " .. serviceName)
			
			local success, result = pcall(function()
				if service.Stop then
					service:Stop()
				end
			end)
			
			if success then
				serviceStates[serviceName] = ServiceState.Stopped
				debugLog("Successfully stopped service: " .. serviceName)
			else
				serviceStates[serviceName] = ServiceState.Error
				warn("Failed to stop service: " .. serviceName .. " - " .. tostring(result))
			end
		end
	end
	
	isStarted = false
	debugLog("All services stopped")
	return true
end

-- Cleanup
function ServiceRegistry:Cleanup()
	self:StopAll()
	
	-- Clear all references
	table.clear(services)
	table.clear(serviceStates)
	table.clear(initializationQueue)
	
	debugLog("ServiceRegistry cleaned up")
end

-- Export
return ServiceRegistry 