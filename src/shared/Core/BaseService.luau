--!strict
-- BaseService.luau
-- Base class for all server-side services
-- Provides common functionality and lifecycle management

local BaseService = {}
BaseService.__index = BaseService

-- Service lifecycle states
export type ServiceState = "Uninitialized" | "Initializing" | "Initialized" | "Starting" | "Started" | "Stopped" | "Error"

-- Base service type
export type BaseService = {
	Name: string,
	Dependencies: {string}?,
	
	Initialize: (self: BaseService) -> (),
	Start: (self: BaseService) -> (),
	Stop: (self: BaseService) -> (),
	Cleanup: (self: BaseService) -> (),
	
	_connections: {RBXScriptConnection},
	_isService: boolean,
	_state: ServiceState,
}

-- Constructor
function BaseService.new(name: string, dependencies: {string}?): BaseService
	local self = setmetatable({}, BaseService)
	
	self.Name = name
	self.Dependencies = dependencies or {}
	self._connections = {}
	self._isService = true
	self._state = "Uninitialized"
	
	return self
end

-- Lifecycle methods (to be overridden by subclasses)
function BaseService:Initialize()
	-- Override in subclasses
end

function BaseService:Start()
	-- Override in subclasses
end

function BaseService:Stop()
	-- Override in subclasses
	self:_disconnectAll()
end

function BaseService:Cleanup()
	self:Stop()
	
	-- Clear all references
	table.clear(self._connections)
	self._state = "Stopped"
end

-- Utility methods
function BaseService:_connectEvent(event: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
	local connection = event:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function BaseService:_disconnectAll()
	for _, connection in ipairs(self._connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(self._connections)
end

-- State management
function BaseService:GetState(): ServiceState
	return self._state
end

function BaseService:_setState(state: ServiceState)
	self._state = state
end

-- Debug logging
function BaseService:_log(message: string, data: any?)
	if not game:GetService("RunService"):IsStudio() then return end
	
	local timestamp = os.date("%H:%M:%S")
	if data then
		print(string.format("[%s] [%s] %s", timestamp, self.Name, message), data)
	else
		print(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

function BaseService:_warn(message: string, data: any?)
	local timestamp = os.date("%H:%M:%S")
	if data then
		warn(string.format("[%s] [%s] %s", timestamp, self.Name, message), data)
	else
		warn(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

function BaseService:_logError(message: string)
	warn(string.format("[%s] ERROR: %s", self.Name, message))
end

function BaseService:_error(message: string, data: any?)
	local timestamp = os.date("%H:%M:%S")
	if data then
		error(string.format("[%s] [%s] %s", timestamp, self.Name, message) .. " " .. tostring(data))
	else
		error(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

-- Export
return BaseService 