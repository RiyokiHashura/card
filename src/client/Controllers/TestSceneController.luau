--!strict
-- TestSceneController.luau
-- Simple test controller with a basic ROLL button for MVP testing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local UIUtils = require(ReplicatedStorage.Shared.Utils.UIUtils)
local UIConstants = require(ReplicatedStorage.Shared.Constants.UIConstants)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local TestSceneController = {}
TestSceneController.__index = TestSceneController
setmetatable(TestSceneController, {__index = BaseController})

function TestSceneController.new()
	local self = BaseController.new("TestSceneController", {"PolishEffectsController", "CardRevealController"})
	setmetatable(self, TestSceneController)
	
	-- UI Elements
	self._testGui = nil
	self._rollButton = nil
	
	return self
end

function TestSceneController:Initialize()
	self:_log("TestSceneController initializing...")
	
	-- Create simple test UI
	self:_createTestUI()
	
	self:_log("TestSceneController initialized successfully")
end

function TestSceneController:Start()
	self:_log("TestSceneController starting...")
	
	-- Set up server event listeners
	self:_setupServerEventListeners()
	
	-- Connect roll button
	if self._rollButton then
		self._rollButton.MouseButton1Click:Connect(function()
			self:_performCardRoll()
		end)
		
		-- Enhance with visual effects
		local polishEffectsController = self.ServiceRegistry:GetService("PolishEffectsController")
		if polishEffectsController then
			polishEffectsController:EnhanceButton(self._rollButton)
		end
	end
	
	self:_log("Test scene ready! Click 'ROLL CARD' to test the core game loop")
end

function TestSceneController:Stop()
	self:_log("TestSceneController stopping...")
	
	-- Cleanup UI
	if self._testGui then
		self._testGui:Destroy()
		self._testGui = nil
	end
	
	BaseController.Stop(self)
	self:_log("TestSceneController stopped")
end

-- Private Methods

function TestSceneController:_createTestUI()
	-- Create main GUI
	self._testGui = Instance.new("ScreenGui")
	self._testGui.Name = "TestSceneGUI"
	self._testGui.Parent = PlayerGui
	self._testGui.ResetOnSpawn = false
	
	-- Create responsive container using professional UI system
	local container = UIUtils.CreateResponsiveContainer({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		LayoutType = "List",
		Spacing = UIConstants.Spacing.Large,
		Parent = self._testGui
	})
	
	-- Create professional ROLL CARD button
	self._rollButton = UIUtils.CreateButton({
		Text = "🎲 ROLL CARD",
		Size = Vector2.new(240, 70),
		Position = UDim2.new(0.5, 0, 0.7, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = UIConstants.RarityColors.Primary,
		TextColor = Color3.new(0, 0, 0),
		TextSize = UIConstants.Typography.UI,
		Parent = container
	})
	
	-- Add professional button animations
	UIUtils.AddButtonAnimation(self._rollButton)
	
	-- Add text padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = self._rollButton
end

function TestSceneController:_performCardRoll()
	self:_log("Performing card roll...")
	
	-- Disable button temporarily
	if self._rollButton then
		self._rollButton.Text = "Rolling..."
		self._rollButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	end
	
	-- Request card roll from server
	RemoteEventHandler:FireServer("RequestCardRoll", "Standard")
	
	-- Re-enable button after delay
	spawn(function()
		wait(3) -- Wait for roll sequence
		if self._rollButton then
			self._rollButton.Text = "🎲 ROLL CARD"
			self._rollButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		end
	end)
end

function TestSceneController:_setupServerEventListeners()
	-- Listen for card roll results
	RemoteEventHandler:ConnectRemoteEventClient("CardRollResult", function(rollResult)
		self:_handleCardRollResult(rollResult)
	end)
	
	-- Listen for card roll errors
	RemoteEventHandler:ConnectRemoteEventClient("CardRollError", function(errorMessage)
		self:_handleCardRollError(errorMessage)
	end)
end

function TestSceneController:_handleCardRollResult(rollResult: any)
	self:_log("Received card roll result!")
	
	-- Re-enable button
	if self._rollButton then
		self._rollButton.Text = "🎲 ROLL CARD"
		self._rollButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	end
	
	-- Get the first card from the result
	if rollResult.Cards and #rollResult.Cards > 0 then
		local cardResult = rollResult.Cards[1]
		self:_log("Rolling card: " .. cardResult.Card.Name .. " (" .. cardResult.Rarity .. ")")
		
		-- Trigger card reveal
		local cardRevealController = self.ServiceRegistry:GetService("CardRevealController")
		if cardRevealController then
			cardRevealController:RevealSingleCard(cardResult)
		end
	end
end

function TestSceneController:_handleCardRollError(errorMessage: string)
	warn("[TestSceneController] Card roll failed: " .. errorMessage)
	
	-- Re-enable button
	if self._rollButton then
		self._rollButton.Text = "❌ ROLL FAILED"
		self._rollButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		
		-- Reset after delay
		spawn(function()
			wait(2)
			if self._rollButton then
				self._rollButton.Text = "🎲 ROLL CARD"
				self._rollButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			end
		end)
	end
end

return TestSceneController.new() 