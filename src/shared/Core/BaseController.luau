--!strict
-- BaseController.luau
-- Base class for all client-side controllers
-- Provides common functionality and lifecycle management

local BaseController = {}
BaseController.__index = BaseController

-- Controller lifecycle states
export type ControllerState = "Uninitialized" | "Initializing" | "Initialized" | "Starting" | "Started" | "Stopped" | "Error"

-- Base controller type
export type BaseController = {
	Name: string,
	Dependencies: {string}?,
	
	Initialize: (self: BaseController) -> (),
	Start: (self: BaseController) -> (),
	Stop: (self: BaseController) -> (),
	Cleanup: (self: BaseController) -> (),
	
	_connections: {RBXScriptConnection},
	_isController: boolean,
	_state: ControllerState,
}

-- Constructor
function BaseController.new(name: string, dependencies: {string}?): BaseController
	local self = setmetatable({}, BaseController)
	
	self.Name = name
	self.Dependencies = dependencies or {}
	self._connections = {}
	self._isController = true
	self._state = "Uninitialized"
	
	return self
end

-- Lifecycle methods (to be overridden by subclasses)
function BaseController:Initialize()
	-- Override in subclasses
end

function BaseController:Start()
	-- Override in subclasses
end

function BaseController:Stop()
	-- Override in subclasses
	self:_disconnectAll()
end

function BaseController:Cleanup()
	self:Stop()
	
	-- Clear all references
	table.clear(self._connections)
	self._state = "Stopped"
end

-- Utility methods
function BaseController:_connectEvent(event: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
	local connection = event:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function BaseController:_disconnectAll()
	for _, connection in ipairs(self._connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(self._connections)
end

-- Input handling utilities
function BaseController:_connectInput(inputType: Enum.KeyCode | Enum.UserInputType, callback: () -> ()): RBXScriptConnection
	local UserInputService = game:GetService("UserInputService")
	
	local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == inputType or input.UserInputType == inputType then
			callback()
		end
	end)
	
	table.insert(self._connections, connection)
	return connection
end

function BaseController:_connectTouchInput(guiObject: GuiObject, callback: () -> ()): RBXScriptConnection
	local connection = guiObject.Activated:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

-- State management
function BaseController:GetState(): ControllerState
	return self._state
end

function BaseController:_setState(state: ControllerState)
	self._state = state
end

-- Debug logging
function BaseController:_log(message: string, data: any?)
	if not game:GetService("RunService"):IsStudio() then return end
	
	local timestamp = os.date("%H:%M:%S")
	if data then
		print(string.format("[%s] [%s] %s", timestamp, self.Name, message), data)
	else
		print(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

function BaseController:_warn(message: string, data: any?)
	local timestamp = os.date("%H:%M:%S")
	if data then
		warn(string.format("[%s] [%s] %s", timestamp, self.Name, message), data)
	else
		warn(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

function BaseController:_error(message: string, data: any?)
	local timestamp = os.date("%H:%M:%S")
	if data then
		error(string.format("[%s] [%s] %s", timestamp, self.Name, message) .. " " .. tostring(data))
	else
		error(string.format("[%s] [%s] %s", timestamp, self.Name, message))
	end
end

-- Export
return BaseController 