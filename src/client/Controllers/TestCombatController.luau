--!strict
-- TestCombatController.luau
-- A simple controller to initiate a test combat sequence.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
local UIUtils = require(ReplicatedStorage.Shared.Utils.UIUtils)
local UIConstants = require(ReplicatedStorage.Shared.Constants.UIConstants)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local TestCombatController = {}
TestCombatController.__index = TestCombatController
setmetatable(TestCombatController, {__index = BaseController})

function TestCombatController.new()
	local self = BaseController.new("TestCombatController", {"BattleController"})
	setmetatable(self, TestCombatController)
	
	self._testGui = nil
	self._battleButton = nil
	
	return self
end

function TestCombatController:Initialize()
	self:_log("Initializing...")
	self:_createTestUI()
	self:_log("Initialized.")
end

function TestCombatController:Start()
	self:_log("Starting...")
	if self._battleButton then
		self._battleButton.MouseButton1Click:Connect(function()
			self:_startTestBattle()
		end)
	end
	self:_log("Started.")
end

function TestCombatController:_createTestUI()
	self._testGui = Instance.new("ScreenGui")
	self._testGui.Name = "TestCombatGUI"
	self._testGui.Parent = PlayerGui
	
	-- Create responsive container using professional UI system
	local container = UIUtils.CreateResponsiveContainer({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		LayoutType = "List",
		Spacing = UIConstants.Spacing.Large
	})
	container.Parent = self._testGui
	
	-- Create professional START BATTLE button
	self._battleButton = UIUtils.CreateButton({
		Text = "⚔️ START BATTLE",
		Size = Vector2.new(200, 60),
		Position = UDim2.new(0.5, 0, 0.3, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = UIConstants.RarityColors.Legendary,
		TextColor = UIConstants.RarityColors.Text,
		TextSize = UIConstants.Typography.UI,
		Parent = container
	})
	
	-- Add professional button animations
	UIUtils.AddButtonAnimation(self._battleButton)
end

function TestCombatController:_startTestBattle()
	self:_log("Starting test battle...")
	local battleController = self.ServiceRegistry:GetService("BattleController")
	if battleController then
		battleController:StartBattle({
			OpponentId = "AI_EASY_01",
			BattleType = "PVE",
		})
	end
end

return TestCombatController.new() 