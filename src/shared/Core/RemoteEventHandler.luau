--!strict
-- RemoteEventHandler.luau
-- Handles all client-server communication
-- Provides type-safe remote event and remote function management

local RemoteEventHandler = {}
RemoteEventHandler.__index = RemoteEventHandler

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local REMOTE_EVENTS_FOLDER = "RemoteEvents"
local REMOTE_FUNCTIONS_FOLDER = "RemoteFunctions"

-- Storage
local remoteEvents: {[string]: RemoteEvent} = {}
local remoteFunctions: {[string]: RemoteFunction} = {}
local initialized = false

-- Debug logging
local DEBUG_ENABLED = RunService:IsStudio()

local function debugLog(message: string, data: any?)
	if not DEBUG_ENABLED then return end
	
	local timestamp = os.date("%H:%M:%S")
	if data then
		print(string.format("[%s] [RemoteEventHandler] %s", timestamp, message), data)
	else
		print(string.format("[%s] [RemoteEventHandler] %s", timestamp, message))
	end
end

-- Initialize remote event folders
local function initializeFolders()
	if initialized then return end
	
	-- Create remote events folder
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild(REMOTE_EVENTS_FOLDER)
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = REMOTE_EVENTS_FOLDER
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- Create remote functions folder
	local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER)
	if not remoteFunctionsFolder then
		remoteFunctionsFolder = Instance.new("Folder")
		remoteFunctionsFolder.Name = REMOTE_FUNCTIONS_FOLDER
		remoteFunctionsFolder.Parent = ReplicatedStorage
	end
	
	initialized = true
	debugLog("Remote event folders initialized")
end

-- Get or create remote event
function RemoteEventHandler:GetRemoteEvent(eventName: string): RemoteEvent
	assert(type(eventName) == "string", "Event name must be a string")
	
	initializeFolders()
	
	-- Check cache first
	if remoteEvents[eventName] then
		return remoteEvents[eventName]
	end
	
	-- Get folder
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_EVENTS_FOLDER)
	if not folder then
		error("Remote events folder not found")
	end
	
	-- Find or create remote event
	local remoteEvent = folder:FindFirstChild(eventName)
	if not remoteEvent then
		if RunService:IsServer() then
			-- Server creates the remote event
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = folder
			debugLog("Created remote event: " .. eventName)
		else
			-- Client waits for remote event
			debugLog("Waiting for remote event: " .. eventName)
			remoteEvent = folder:WaitForChild(eventName)
		end
	end
	
	-- Cache and return
	remoteEvents[eventName] = remoteEvent
	return remoteEvent
end

-- Get or create remote function
function RemoteEventHandler:GetRemoteFunction(functionName: string): RemoteFunction
	assert(type(functionName) == "string", "Function name must be a string")
	
	initializeFolders()
	
	-- Check cache first
	if remoteFunctions[functionName] then
		return remoteFunctions[functionName]
	end
	
	-- Get folder
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER)
	if not folder then
		error("Remote functions folder not found")
	end
	
	-- Find or create remote function
	local remoteFunction = folder:FindFirstChild(functionName)
	if not remoteFunction then
		if RunService:IsServer() then
			-- Server creates the remote function
			remoteFunction = Instance.new("RemoteFunction")
			remoteFunction.Name = functionName
			remoteFunction.Parent = folder
			debugLog("Created remote function: " .. functionName)
		else
			-- Client waits for remote function
			debugLog("Waiting for remote function: " .. functionName)
			remoteFunction = folder:WaitForChild(functionName)
		end
	end
	
	-- Cache and return
	remoteFunctions[functionName] = remoteFunction
	return remoteFunction
end

-- Server-side methods
function RemoteEventHandler:ConnectRemoteEvent(eventName: string, callback: (player: Player, ...any) -> ()): RBXScriptConnection
	if not RunService:IsServer() then
		error("ConnectRemoteEvent can only be called on the server")
	end
	
	local remoteEvent = self:GetRemoteEvent(eventName)
	debugLog("Connected server callback for event: " .. eventName)
	
	return remoteEvent.OnServerEvent:Connect(callback)
end

function RemoteEventHandler:BindRemoteFunction(functionName: string, callback: (player: Player, ...any) -> ...any)
	if not RunService:IsServer() then
		error("BindRemoteFunction can only be called on the server")
	end
	
	local remoteFunction = self:GetRemoteFunction(functionName)
	remoteFunction.OnServerInvoke = callback
	debugLog("Bound server callback for function: " .. functionName)
end

function RemoteEventHandler:FireClient(player: Player, eventName: string, ...): ()
	if not RunService:IsServer() then
		error("FireClient can only be called on the server")
	end
	
	local remoteEvent = self:GetRemoteEvent(eventName)
	remoteEvent:FireClient(player, ...)
end

function RemoteEventHandler:FireAllClients(eventName: string, ...): ()
	if not RunService:IsServer() then
		error("FireAllClients can only be called on the server")
	end
	
	local remoteEvent = self:GetRemoteEvent(eventName)
	remoteEvent:FireAllClients(...)
end

-- Client-side methods
function RemoteEventHandler:ConnectRemoteEventClient(eventName: string, callback: (...any) -> ()): RBXScriptConnection
	if RunService:IsServer() then
		error("ConnectRemoteEventClient can only be called on the client")
	end
	
	local remoteEvent = self:GetRemoteEvent(eventName)
	debugLog("Connected client callback for event: " .. eventName)
	
	return remoteEvent.OnClientEvent:Connect(callback)
end

function RemoteEventHandler:FireServer(eventName: string, ...): ()
	if RunService:IsServer() then
		error("FireServer can only be called on the client")
	end
	
	local remoteEvent = self:GetRemoteEvent(eventName)
	remoteEvent:FireServer(...)
end

function RemoteEventHandler:InvokeServer(functionName: string, ...): ...any
	if RunService:IsServer() then
		error("InvokeServer can only be called on the client")
	end
	
	local remoteFunction = self:GetRemoteFunction(functionName)
	return remoteFunction:InvokeServer(...)
end

-- Utility methods
function RemoteEventHandler:GetAllRemoteEvents(): {[string]: RemoteEvent}
	local eventsCopy = {}
	for name, event in pairs(remoteEvents) do
		eventsCopy[name] = event
	end
	return eventsCopy
end

function RemoteEventHandler:GetAllRemoteFunctions(): {[string]: RemoteFunction}
	local functionsCopy = {}
	for name, func in pairs(remoteFunctions) do
		functionsCopy[name] = func
	end
	return functionsCopy
end

function RemoteEventHandler:Cleanup()
	-- Clear caches
	table.clear(remoteEvents)
	table.clear(remoteFunctions)
	
	-- Remove folders if server
	if RunService:IsServer() then
		local remoteEventsFolder = ReplicatedStorage:FindFirstChild(REMOTE_EVENTS_FOLDER)
		if remoteEventsFolder then
			remoteEventsFolder:Destroy()
		end
		
		local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER)
		if remoteFunctionsFolder then
			remoteFunctionsFolder:Destroy()
		end
	end
	
	initialized = false
	debugLog("RemoteEventHandler cleaned up")
end

-- Export
return RemoteEventHandler 