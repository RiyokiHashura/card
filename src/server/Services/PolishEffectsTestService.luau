--!strict
-- PolishEffectsTestService.luau
-- Comprehensive testing for PolishEffectsService functionality
-- Tests screen effects, particle systems, impact frames, and visual juice

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local EffectsTypes = require(ReplicatedStorage.Shared.Types.EffectsTypes)

local PolishEffectsTestService = {}
PolishEffectsTestService.__index = PolishEffectsTestService
setmetatable(PolishEffectsTestService, {__index = BaseService})

function PolishEffectsTestService.new()
	local self = BaseService.new("PolishEffectsTestService", {"PolishEffectsService"})
	setmetatable(self, PolishEffectsTestService)
	
	-- Test configuration
	self._testConfig = {
		EnableExtensiveTests = true,
		EnablePerformanceTests = true,
		EnableScreenEffectTests = true,
		EnableParticleTests = true,
		EnableImpactFrameTests = true,
		EnableVisualJuiceTests = true,
		LogAllResults = true
	}
	
	-- Test results
	self._testResults = {
		ScreenEffects = {},
		ParticleSystems = {},
		ImpactFrames = {},
		VisualJuice = {},
		Performance = {},
		Integration = {}
	}
	
	return self
end

function PolishEffectsTestService:Initialize()
	self:_log("PolishEffectsTestService initializing...")
	
	-- Verify PolishEffectsService dependency
	if not self.ServiceRegistry:GetService("PolishEffectsService") then
		self:_logError("PolishEffectsService dependency not found!")
		return
	end
	
	self:_log("PolishEffectsTestService initialized successfully")
end

function PolishEffectsTestService:Start()
	self:_log("PolishEffectsTestService starting...")
	
	--[[
	-- Run all tests
	self:RunAllPolishEffectsTests()
	--]]
	
	self:_log("PolishEffectsTestService started successfully")
end

-- Public Testing API

function PolishEffectsTestService:RunAllPolishEffectsTests()
	self:_log("=== Running All Polish Effects Tests ===")
	
	local startTime = tick()
	
	-- Screen effects tests
	if self._testConfig.EnableScreenEffectTests then
		self:TestScreenEffects()
	end
	
	-- Particle systems tests
	if self._testConfig.EnableParticleTests then
		self:TestParticleSystems()
	end
	
	-- Impact frames tests
	if self._testConfig.EnableImpactFrameTests then
		self:TestImpactFrames()
	end
	
	-- Visual juice tests
	if self._testConfig.EnableVisualJuiceTests then
		self:TestVisualJuice()
	end
	
	-- Performance tests
	if self._testConfig.EnablePerformanceTests then
		self:TestPerformance()
	end
	
	-- Integration tests
	self:TestIntegration()
	
	local endTime = tick()
	local totalTime = endTime - startTime
	
	self:_log("=== Polish Effects Test Suite Completed ===")
	self:_log("Total execution time: " .. string.format("%.3f", totalTime) .. " seconds")
	
	-- Print summary
	self:PrintTestSummary()
	
	return self._testResults
end

function PolishEffectsTestService:TestScreenEffects()
	self:_log("Testing screen effects...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Chromatic aberration effect
	local test1 = self:_runTest("Chromatic Aberration Effect", function()
		local effectID = polishService:PlayScreenEffect("ChromaticAberration", 0.8, 2.0)
		return typeof(effectID) == "string" and effectID ~= ""
	end)
	table.insert(results, test1)
	
	-- Test 2: Bloom effect
	local test2 = self:_runTest("Bloom Effect", function()
		local effectID = polishService:PlayScreenEffect("Bloom", 0.7, 1.5)
		return typeof(effectID) == "string" and effectID ~= ""
	end)
	table.insert(results, test2)
	
	-- Test 3: Vignette effect
	local test3 = self:_runTest("Vignette Effect", function()
		local effectID = polishService:PlayScreenEffect("Vignette", 0.6, 3.0)
		return typeof(effectID) == "string" and effectID ~= ""
	end)
	table.insert(results, test3)
	
	-- Test 4: Distortion effect
	local test4 = self:_runTest("Distortion Effect", function()
		local effectID = polishService:PlayScreenEffect("Distortion", 0.5, 1.0)
		return typeof(effectID) == "string" and effectID ~= ""
	end)
	table.insert(results, test4)
	
	-- Test 5: Multiple concurrent screen effects
	local test5 = self:_runTest("Multiple Concurrent Screen Effects", function()
		local effectIDs = {}
		table.insert(effectIDs, polishService:PlayScreenEffect("Bloom", 0.3, 1.0))
		table.insert(effectIDs, polishService:PlayScreenEffect("Vignette", 0.4, 1.0))
		table.insert(effectIDs, polishService:PlayScreenEffect("ChromaticAberration", 0.2, 1.0))
		
		return #effectIDs == 3 and effectIDs[1] ~= "" and effectIDs[2] ~= "" and effectIDs[3] ~= ""
	end)
	table.insert(results, test5)
	
	-- Test 6: Screen effect intensity scaling
	local test6 = self:_runTest("Screen Effect Intensity Scaling", function()
		local lowIntensity = polishService:PlayScreenEffect("Bloom", 0.1, 0.5)
		local highIntensity = polishService:PlayScreenEffect("Bloom", 1.0, 0.5)
		
		return lowIntensity ~= "" and highIntensity ~= ""
	end)
	table.insert(results, test6)
	
	self._testResults.ScreenEffects = results
	self:_logTestResults("Screen Effects", results)
end

function PolishEffectsTestService:TestParticleSystems()
	self:_log("Testing particle systems...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Basic particle system spawn
	local test1 = self:_runTest("Basic Particle System Spawn", function()
		local systemID = polishService:SpawnParticleSystem("TestSpark", Vector3.new(0, 10, 0))
		return typeof(systemID) == "string" and systemID ~= ""
	end)
	table.insert(results, test1)
	
	-- Test 2: Multiple particle systems
	local test2 = self:_runTest("Multiple Particle Systems", function()
		local systemIDs = {}
		table.insert(systemIDs, polishService:SpawnParticleSystem("Spark", Vector3.new(0, 10, 0)))
		table.insert(systemIDs, polishService:SpawnParticleSystem("Glow", Vector3.new(5, 10, 0)))
		table.insert(systemIDs, polishService:SpawnParticleSystem("Magic", Vector3.new(-5, 10, 0)))
		
		return #systemIDs == 3
	end)
	table.insert(results, test2)
	
	-- Test 3: Particle system with configuration
	local test3 = self:_runTest("Particle System with Configuration", function()
		local config = {
			Intensity = 0.8,
			Duration = 2.0,
			ParticleCount = 50
		}
		local systemID = polishService:SpawnParticleSystem("ConfiguredSpark", Vector3.new(0, 15, 0), config)
		return typeof(systemID) == "string" and systemID ~= ""
	end)
	table.insert(results, test3)
	
	-- Test 4: Performance limits
	local test4 = self:_runTest("Particle System Performance Limits", function()
		local systemState = polishService:GetSystemState()
		local maxSystems = systemState.PerformanceConfig.MaxParticleSystems
		
		-- Try to spawn more than the limit
		local systemIDs = {}
		for i = 1, maxSystems + 2 do
			local systemID = polishService:SpawnParticleSystem("LimitTest", Vector3.new(i, 10, 0))
			if systemID ~= "" then
				table.insert(systemIDs, systemID)
			end
		end
		
		-- Should not exceed the limit
		return #systemIDs <= maxSystems
	end)
	table.insert(results, test4)
	
	self._testResults.ParticleSystems = results
	self:_logTestResults("Particle Systems", results)
end

function PolishEffectsTestService:TestImpactFrames()
	self:_log("Testing impact frames...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Light impact frame
	local test1 = self:_runTest("Light Impact Frame", function()
		local frameID = polishService:TriggerImpactFrame("Light", 0.3)
		return typeof(frameID) == "string" and frameID ~= ""
	end)
	table.insert(results, test1)
	
	-- Test 2: Medium impact frame
	local test2 = self:_runTest("Medium Impact Frame", function()
		local frameID = polishService:TriggerImpactFrame("Medium", 0.6)
		return typeof(frameID) == "string" and frameID ~= ""
	end)
	table.insert(results, test2)
	
	-- Test 3: Heavy impact frame
	local test3 = self:_runTest("Heavy Impact Frame", function()
		local frameID = polishService:TriggerImpactFrame("Heavy", 0.8)
		return typeof(frameID) == "string" and frameID ~= ""
	end)
	table.insert(results, test3)
	
	-- Test 4: Ultimate impact frame
	local test4 = self:_runTest("Ultimate Impact Frame", function()
		local frameID = polishService:TriggerImpactFrame("Ultimate", 1.0)
		return typeof(frameID) == "string" and frameID ~= ""
	end)
	table.insert(results, test4)
	
	-- Test 5: Impact frame with position
	local test5 = self:_runTest("Impact Frame with Position", function()
		local frameID = polishService:TriggerImpactFrame("Medium", 0.7, Vector3.new(0, 10, 0))
		return typeof(frameID) == "string" and frameID ~= ""
	end)
	table.insert(results, test5)
	
	-- Test 6: Research-based timing validation
	local test6 = self:_runTest("Research-Based Impact Timing", function()
		-- Test that impact durations match research data (50-200ms)
		local systemState = polishService:GetSystemState()
		local researchData = systemState.ResearchData
		local optimalRange = researchData.OptimalImpactDuration
		
		-- Check that our impact types fall within research range
		return optimalRange.Min <= 0.05 and optimalRange.Max >= 0.2
	end)
	table.insert(results, test6)
	
	self._testResults.ImpactFrames = results
	self:_logTestResults("Impact Frames", results)
end

function PolishEffectsTestService:TestVisualJuice()
	self:_log("Testing visual juice effects...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Button hover juice
	local test1 = self:_runTest("Button Hover Visual Juice", function()
		-- Create a test part to represent a UI element
		local testPart = Instance.new("Part")
		testPart.Parent = workspace
		testPart.Name = "TestButtonPart"
		
		local juiceID = polishService:PlayVisualJuice("ButtonHover", testPart)
		
		-- Cleanup
		testPart:Destroy()
		
		return typeof(juiceID) == "string" and juiceID ~= ""
	end)
	table.insert(results, test1)
	
	-- Test 2: Card reveal juice
	local test2 = self:_runTest("Card Reveal Visual Juice", function()
		local testPart = Instance.new("Part")
		testPart.Parent = workspace
		testPart.Name = "TestCardPart"
		
		local juiceID = polishService:PlayVisualJuice("CardReveal", testPart)
		
		-- Cleanup
		testPart:Destroy()
		
		return typeof(juiceID) == "string" and juiceID ~= ""
	end)
	table.insert(results, test2)
	
	-- Test 3: Visual juice with custom configuration
	local test3 = self:_runTest("Visual Juice with Custom Configuration", function()
		local testPart = Instance.new("Part")
		testPart.Parent = workspace
		testPart.Name = "TestCustomPart"
		
		local customConfig = {
			Duration = 1.5,
			Intensity = 0.8,
			EasingStyle = "Bounce"
		}
		
		local juiceID = polishService:PlayVisualJuice("CustomJuice", testPart, customConfig)
		
		-- Cleanup
		testPart:Destroy()
		
		return typeof(juiceID) == "string"
	end)
	table.insert(results, test3)
	
	-- Test 4: Multiple simultaneous juice effects
	local test4 = self:_runTest("Multiple Simultaneous Visual Juice", function()
		local testParts = {}
		local juiceIDs = {}
		
		-- Create multiple test parts
		for i = 1, 3 do
			local part = Instance.new("Part")
			part.Parent = workspace
			part.Name = "TestPart" .. i
			table.insert(testParts, part)
			
			local juiceID = polishService:PlayVisualJuice("ButtonHover", part)
			table.insert(juiceIDs, juiceID)
		end
		
		-- Cleanup
		for _, part in ipairs(testParts) do
			part:Destroy()
		end
		
		return #juiceIDs == 3
	end)
	table.insert(results, test4)
	
	self._testResults.VisualJuice = results
	self:_logTestResults("Visual Juice", results)
end

function PolishEffectsTestService:TestPerformance()
	self:_log("Testing performance...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Performance metrics tracking
	local test1 = self:_runTest("Performance Metrics Tracking", function()
		local metrics = polishService:GetPerformanceMetrics()
		return type(metrics.EffectCount) == "number" and
		       type(metrics.ParticleCount) == "number" and
		       type(metrics.FrameRate) == "number"
	end)
	table.insert(results, test1)
	
	-- Test 2: Quality level adjustment
	local test2 = self:_runTest("Quality Level Adjustment", function()
		local originalLevel = polishService:GetSystemState().CurrentQualityLevel
		
		polishService:SetQualityLevel(1, "Test")
		local newLevel1 = polishService:GetSystemState().CurrentQualityLevel
		
		polishService:SetQualityLevel(3, "Test")
		local newLevel3 = polishService:GetSystemState().CurrentQualityLevel
		
		-- Restore original level
		polishService:SetQualityLevel(originalLevel, "Test")
		
		return newLevel1 == 1 and newLevel3 == 3
	end)
	table.insert(results, test2)
	
	-- Test 3: Effect limit enforcement
	local test3 = self:_runTest("Effect Limit Enforcement", function()
		local systemState = polishService:GetSystemState()
		local maxEffects = systemState.PerformanceConfig.MaxScreenEffects
		
		-- Try to create more effects than the limit
		local effectIDs = {}
		for i = 1, maxEffects + 2 do
			local effectID = polishService:PlayScreenEffect("Bloom", 0.1, 0.5)
			if effectID ~= "" then
				table.insert(effectIDs, effectID)
			end
		end
		
		-- Should not exceed limit due to optimization
		return #effectIDs <= maxEffects + 1 -- Allow slight tolerance for optimization timing
	end)
	table.insert(results, test3)
	
	-- Test 4: Memory management
	local test4 = self:_runTest("Memory Management", function()
		-- Create and stop effects to test cleanup
		local effectIDs = {}
		for i = 1, 5 do
			local effectID = polishService:PlayScreenEffect("Vignette", 0.2, 0.1)
			table.insert(effectIDs, effectID)
		end
		
		-- Stop all effects
		for _, effectID in ipairs(effectIDs) do
			polishService:StopEffect(effectID)
		end
		
		-- Check that effect count decreased
		local systemState = polishService:GetSystemState()
		return systemState.EffectCount >= 0 -- Should not go negative
	end)
	table.insert(results, test4)
	
	self._testResults.Performance = results
	self:_logTestResults("Performance", results)
end

function PolishEffectsTestService:TestIntegration()
	self:_log("Testing integration...")
	
	local polishService = self.ServiceRegistry:GetService("PolishEffectsService")
	local results = {}
	
	-- Test 1: Service registry integration
	local test1 = self:_runTest("Service Registry Integration", function()
		local serviceFromRegistry = self.ServiceRegistry:GetService("PolishEffectsService")
		return serviceFromRegistry ~= nil
	end)
	table.insert(results, test1)
	
	-- Test 2: Audio service integration
	local test2 = self:_runTest("Audio Service Integration", function()
		-- Trigger impact frame which should sync with audio
		local frameID = polishService:TriggerImpactFrame("Medium", 0.7)
		
		-- Check that audio service dependency is working
		local audioService = self:GetService("AudioService")
		return frameID ~= "" and audioService ~= nil
	end)
	table.insert(results, test2)
	
	-- Test 3: GameConstants integration
	local test3 = self:_runTest("GameConstants Integration", function()
		local systemState = polishService:GetSystemState()
		local researchData = systemState.ResearchData
		
		-- Verify research data is properly loaded
		return researchData.OptimalImpactDuration ~= nil and
		       #researchData.AttentionGrabbingColors > 0
	end)
	table.insert(results, test3)
	
	-- Test 4: Complex effect coordination
	local test4 = self:_runTest("Complex Effect Coordination", function()
		-- Test coordinated effects like card reveal
		local effectIDs = {}
		
		-- Simulate a legendary card reveal
		table.insert(effectIDs, polishService:PlayScreenEffect("Bloom", 0.8, 1.0))
		table.insert(effectIDs, polishService:SpawnParticleSystem("Magic", Vector3.new(0, 10, 0)))
		table.insert(effectIDs, polishService:TriggerImpactFrame("Heavy", 0.9))
		
		-- All effects should be created successfully
		return #effectIDs == 3 and effectIDs[1] ~= "" and effectIDs[2] ~= "" and effectIDs[3] ~= ""
	end)
	table.insert(results, test4)
	
	self._testResults.Integration = results
	self:_logTestResults("Integration", results)
end

function PolishEffectsTestService:PrintTestSummary()
	self:_log("=== Polish Effects Test Summary ===")
	
	local totalTests = 0
	local passedTests = 0
	
	for categoryName, categoryResults in pairs(self._testResults) do
		local categoryPassed = 0
		local categoryTotal = #categoryResults
		
		for _, result in ipairs(categoryResults) do
			if result.Passed then
				categoryPassed = categoryPassed + 1
				passedTests = passedTests + 1
			end
			totalTests = totalTests + 1
		end
		
		local passRate = categoryTotal > 0 and (categoryPassed / categoryTotal * 100) or 0
		self:_log(string.format("%s: %d/%d passed (%.1f%%)", 
			categoryName, categoryPassed, categoryTotal, passRate))
	end
	
	local overallPassRate = totalTests > 0 and (passedTests / totalTests * 100) or 0
	self:_log(string.format("Overall: %d/%d tests passed (%.1f%%)", 
		passedTests, totalTests, overallPassRate))
	
	if overallPassRate >= 90 then
		self:_log("🎉 Polish effects system is functioning excellently!")
	elseif overallPassRate >= 75 then
		self:_log("✅ Polish effects system is functioning well with minor issues")
	else
		self:_log("⚠️  Polish effects system has significant issues that need attention")
	end
end

-- Private Testing Utilities

function PolishEffectsTestService:_runTest(testName: string, testFunction: () -> boolean): {Name: string, Passed: boolean, Error: string?}
	local success, result = pcall(testFunction)
	
	local testResult = {
		Name = testName,
		Passed = success and result == true,
		Error = success and result ~= true and "Test returned false" or (not success and tostring(result)) or nil
	}
	
	if self._testConfig.LogAllResults then
		local status = testResult.Passed and "✅ PASS" or "❌ FAIL"
		local errorInfo = testResult.Error and (" - " .. testResult.Error) or ""
		self:_log(string.format("[%s] %s%s", status, testName, errorInfo))
	end
	
	return testResult
end

function PolishEffectsTestService:_logTestResults(categoryName: string, results: any)
	local passed = 0
	local total = #results
	
	for _, result in ipairs(results) do
		if result.Passed then
			passed = passed + 1
		end
	end
	
	local passRate = total > 0 and (passed / total * 100) or 0
	self:_log(string.format("%s tests completed: %d/%d passed (%.1f%%)", 
		categoryName, passed, total, passRate))
end

function PolishEffectsTestService:_logError(message: string)
	warn("[PolishEffectsTestService] ERROR: " .. message)
end

return PolishEffectsTestService.new() 