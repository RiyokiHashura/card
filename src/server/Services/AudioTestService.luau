--!strict
-- AudioTestService.luau
-- Comprehensive testing for AudioService functionality
-- Tests psychological audio design, frequency layering, and timing precision

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local AudioTypes = require(ReplicatedStorage.Shared.Types.AudioTypes)

type AudioContext = AudioTypes.AudioContext
type PsychologicalAudioConfig = AudioTypes.PsychologicalAudioConfig

local AudioTestService = {}
AudioTestService.__index = AudioTestService
setmetatable(AudioTestService, {__index = BaseService})

function AudioTestService.new()
	local self = BaseService.new("AudioTestService", {"AudioService"})
	setmetatable(self, AudioTestService)
	
	-- Test configuration
	self._testConfig = {
		EnableExtensiveTests = true,
		EnablePerformanceTests = true,
		EnablePsychologicalTests = true,
		EnableFrequencyTests = true,
		EnableSpatialTests = true,
		LogAllResults = true
	}
	
	-- Test results
	self._testResults = {
		BasicFunctionality = {},
		PsychologicalDesign = {},
		FrequencyLayering = {},
		SpatialAudio = {},
		Performance = {},
		Integration = {}
	}
	
	return self
end

function AudioTestService:Initialize()
	self:_log("AudioTestService initializing...")
	
	-- Verify AudioService dependency
	if not self.ServiceRegistry:GetService("AudioService") then
		self:_logError("AudioService dependency not found!")
		return
	end
	
	self:_log("AudioTestService initialized successfully")
end

function AudioTestService:Start()
	self:_log("AudioTestService starting...")
	
	-- Run all tests
	self:RunAllAudioTests()
	
	self:_log("AudioTestService started successfully")
end

-- Public Testing API

function AudioTestService:RunAllAudioTests()
	self:_log("=== Running All Audio Tests ===")
	
	local startTime = tick()
	
	-- Basic functionality tests
	if self._testConfig.EnableExtensiveTests then
		self:TestBasicAudioFunctionality()
	end
	
	-- Psychological design tests
	if self._testConfig.EnablePsychologicalTests then
		self:TestPsychologicalAudioDesign()
	end
	
	-- Frequency layering tests
	if self._testConfig.EnableFrequencyTests then
		self:TestFrequencyLayering()
	end
	
	-- Spatial audio tests
	if self._testConfig.EnableSpatialTests then
		self:TestSpatialAudio()
	end
	
	-- Performance tests
	if self._testConfig.EnablePerformanceTests then
		self:TestAudioPerformance()
	end
	
	-- Integration tests
	self:TestAudioIntegration()
	
	local endTime = tick()
	local totalTime = endTime - startTime
	
	self:_log("=== Audio Test Suite Completed ===")
	self:_log("Total execution time: " .. string.format("%.3f", totalTime) .. " seconds")
	
	-- Print summary
	self:PrintTestSummary()
	
	return self._testResults
end

function AudioTestService:TestBasicAudioFunctionality()
	self:_log("Testing basic audio functionality...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: AudioService initialization
	local test1 = self:_runTest("AudioService Initialization", function()
		local systemState = audioService:GetSystemState()
		return systemState.IsInitialized == true
	end)
	table.insert(results, test1)
	
	-- Test 2: Play audio cue
	local test2 = self:_runTest("Play Audio Cue", function()
		local instanceID = audioService:PlayAudioCue("test_cue")
		return typeof(instanceID) == "string" and instanceID ~= ""
	end)
	table.insert(results, test2)
	
	-- Test 3: Audio context update
	local test3 = self:_runTest("Audio Context Update", function()
		local context: AudioContext = {
			CurrentScene = "Battle",
			PlayerState = "Fighting",
			TensionLevel = 0.8,
			ExcitementLevel = 0.9,
			RecentActions = {"AttackCard", "DefendCard"},
			SessionLength = 300,
			LastMajorEvent = "CriticalHit",
			NextExpectedEvent = "Victory"
		}
		
		audioService:UpdateAudioContext(context)
		local systemState = audioService:GetSystemState()
		
		return systemState.CurrentContext.CurrentScene == "Battle" and
		       systemState.CurrentContext.TensionLevel == 0.8
	end)
	table.insert(results, test3)
	
	-- Test 4: Frequency layer emphasis
	local test4 = self:_runTest("Frequency Layer Emphasis", function()
		audioService:SetFrequencyLayerEmphasis("SubBass", 1.5)
		local systemState = audioService:GetSystemState()
		return systemState.FrequencyConfig.SubBass.IntensityMultiplier == 1.5
	end)
	table.insert(results, test4)
	
	-- Test 5: Stop audio
	local test5 = self:_runTest("Stop Audio", function()
		local instanceID = audioService:PlayAudioCue("test_cue_2")
		audioService:StopAudio(instanceID)
		-- Basic test - just verify no errors occurred
		return true
	end)
	table.insert(results, test5)
	
	self._testResults.BasicFunctionality = results
	self:_logTestResults("Basic Audio Functionality", results)
end

function AudioTestService:TestPsychologicalAudioDesign()
	self:_log("Testing psychological audio design...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: Psychological event trigger
	local test1 = self:_runTest("Psychological Event Trigger", function()
		audioService:TriggerPsychologicalEvent("DopamineSpike", 0.8, 2.0)
		-- Test that event was triggered without errors
		return true
	end)
	table.insert(results, test1)
	
	-- Test 2: Rarity-based psychological profiles
	local test2 = self:_runTest("Rarity-Based Psychological Profiles", function()
		local commonConfig: PsychologicalAudioConfig = {
			RarityLevel = "Common",
			DopamineProfile = {
				BuildupCurve = "linear",
				PeakIntensity = 0.3,
				SustainDuration = 0.5,
				ReleaseCurve = "exponential",
				NextEventPrep = 0.2
			},
			PsychologicalTiming = {
				AnticipationDelay = 0.1,
				ImpactTiming = 0.05,
				ResolutionFade = 0.3,
				NextCuePrep = 0.1
			},
			FrequencyEmphasis = {Midrange = 1.0},
			SpatialEffects = false,
			CompressionLevel = 0.7
		}
		
		local instanceID = audioService:PlayAudioCue("common_card", commonConfig)
		return typeof(instanceID) == "string" and instanceID ~= ""
	end)
	table.insert(results, test2)
	
	-- Test 3: Legendary psychological profile
	local test3 = self:_runTest("Legendary Psychological Profile", function()
		local legendaryConfig: PsychologicalAudioConfig = {
			RarityLevel = "Legendary",
			DopamineProfile = {
				BuildupCurve = "exponential",
				PeakIntensity = 0.9,
				SustainDuration = 2.0,
				ReleaseCurve = "logarithmic",
				NextEventPrep = 1.0
			},
			PsychologicalTiming = {
				AnticipationDelay = 0.5,
				ImpactTiming = 0.2,
				ResolutionFade = 1.5,
				NextCuePrep = 0.5
			},
			FrequencyEmphasis = {SubBass = 1.2, Brilliance = 1.4},
			SpatialEffects = true,
			CompressionLevel = 0.3
		}
		
		local instanceID = audioService:PlayAudioCue("legendary_card", legendaryConfig)
		return typeof(instanceID) == "string" and instanceID ~= ""
	end)
	table.insert(results, test3)
	
	-- Test 4: Context-based audio adaptation
	local test4 = self:_runTest("Context-Based Audio Adaptation", function()
		-- Test different contexts
		local contexts = {
			{CurrentScene = "Menu", TensionLevel = 0.2, ExcitementLevel = 0.3},
			{CurrentScene = "CardRoll", TensionLevel = 0.6, ExcitementLevel = 0.8},
			{CurrentScene = "Battle", TensionLevel = 0.9, ExcitementLevel = 0.7}
		}
		
		for _, contextData in ipairs(contexts) do
			local context: AudioContext = {
				CurrentScene = contextData.CurrentScene,
				PlayerState = "Active",
				TensionLevel = contextData.TensionLevel,
				ExcitementLevel = contextData.ExcitementLevel,
				RecentActions = {},
				SessionLength = 60,
				LastMajorEvent = "SceneChange",
				NextExpectedEvent = "PlayerAction"
			}
			
			audioService:UpdateAudioContext(context)
		end
		
		return true
	end)
	table.insert(results, test4)
	
	self._testResults.PsychologicalDesign = results
	self:_logTestResults("Psychological Audio Design", results)
end

function AudioTestService:TestFrequencyLayering()
	self:_log("Testing frequency layering system...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: Individual frequency layer control
	local test1 = self:_runTest("Individual Frequency Layer Control", function()
		local systemState = audioService:GetSystemState()
		local originalEmphasis = systemState.FrequencyConfig.SubBass.IntensityMultiplier
		
		audioService:SetFrequencyLayerEmphasis("SubBass", 1.5)
		audioService:SetFrequencyLayerEmphasis("Presence", 0.8)
		audioService:SetFrequencyLayerEmphasis("Brilliance", 1.2)
		
		local newState = audioService:GetSystemState()
		return newState.FrequencyConfig.SubBass.IntensityMultiplier == 1.5 and
		       newState.FrequencyConfig.Presence.IntensityMultiplier == 0.8 and
		       newState.FrequencyConfig.Brilliance.IntensityMultiplier == 1.2
	end)
	table.insert(results, test1)
	
	-- Test 2: Frequency layer combinations
	local test2 = self:_runTest("Frequency Layer Combinations", function()
		-- Test different frequency combinations for psychological effect
		local combinations = {
			{SubBass = 1.3, MidBass = 1.1, Purpose = "Impact"},
			{Presence = 1.4, Brilliance = 1.5, Purpose = "Sparkle"},
			{Midrange = 1.2, UpperMid = 1.3, Purpose = "Clarity"}
		}
		
		for _, combo in ipairs(combinations) do
			for layerName, emphasis in pairs(combo) do
				if layerName ~= "Purpose" then
					audioService:SetFrequencyLayerEmphasis(layerName, emphasis)
				end
			end
		end
		
		return true
	end)
	table.insert(results, test2)
	
	-- Test 3: Research-based frequency ranges
	local test3 = self:_runTest("Research-Based Frequency Ranges", function()
		local systemState = audioService:GetSystemState()
		local config = systemState.FrequencyConfig
		
		-- Verify frequency ranges match research
		local subBassRange = config.SubBass.FrequencyRange
		local brillianceRange = config.Brilliance.FrequencyRange
		
		return subBassRange.Low == 20 and subBassRange.High == 60 and
		       brillianceRange.Low == 8000 and brillianceRange.High == 16000
	end)
	table.insert(results, test3)
	
	-- Test 4: Mobile optimization
	local test4 = self:_runTest("Mobile Optimization", function()
		local systemState = audioService:GetSystemState()
		return systemState.FrequencyConfig.MobileOptimization == true
	end)
	table.insert(results, test4)
	
	self._testResults.FrequencyLayering = results
	self:_logTestResults("Frequency Layering", results)
end

function AudioTestService:TestSpatialAudio()
	self:_log("Testing spatial audio system...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: Spatial configuration
	local test1 = self:_runTest("Spatial Configuration", function()
		local systemState = audioService:GetSystemState()
		local spatialConfig = systemState.SpatialConfig
		
		return spatialConfig.IsEnabled == true and
		       spatialConfig.MaxAudibleDistance > 0
	end)
	table.insert(results, test1)
	
	-- Test 2: Spatial audio with psychological config
	local test2 = self:_runTest("Spatial Audio with Psychological Config", function()
		local spatialConfig: PsychologicalAudioConfig = {
			RarityLevel = "Epic",
			DopamineProfile = {
				BuildupCurve = "exponential",
				PeakIntensity = 0.7,
				SustainDuration = 1.5,
				ReleaseCurve = "linear",
				NextEventPrep = 0.5
			},
			PsychologicalTiming = {
				AnticipationDelay = 0.3,
				ImpactTiming = 0.15,
				ResolutionFade = 1.0,
				NextCuePrep = 0.3
			},
			FrequencyEmphasis = {SubBass = 1.1, Presence = 1.2},
			SpatialEffects = true,
			CompressionLevel = 0.5
		}
		
		local instanceID = audioService:PlayAudioCue("spatial_test", spatialConfig)
		return typeof(instanceID) == "string" and instanceID ~= ""
	end)
	table.insert(results, test2)
	
	self._testResults.SpatialAudio = results
	self:_logTestResults("Spatial Audio", results)
end

function AudioTestService:TestAudioPerformance()
	self:_log("Testing audio performance...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: Performance metrics tracking
	local test1 = self:_runTest("Performance Metrics Tracking", function()
		local metrics = audioService:GetPerformanceMetrics()
		return type(metrics.ConcurrentSounds) == "number" and
		       type(metrics.ConcurrentLayers) == "number" and
		       type(metrics.CPUUsage) == "number"
	end)
	table.insert(results, test1)
	
	-- Test 2: Concurrent audio handling
	local test2 = self:_runTest("Concurrent Audio Handling", function()
		local instanceIDs = {}
		
		-- Play multiple audio cues simultaneously
		for i = 1, 5 do
			local instanceID = audioService:PlayAudioCue("concurrent_test_" .. i)
			table.insert(instanceIDs, instanceID)
		end
		
		-- Verify they were all created
		return #instanceIDs == 5
	end)
	table.insert(results, test2)
	
	-- Test 3: Audio system limits
	local test3 = self:_runTest("Audio System Limits", function()
		local systemState = audioService:GetSystemState()
		local performanceConfig = systemState.PerformanceConfig
		
		return performanceConfig.MaxConcurrentSounds > 0 and
		       performanceConfig.MaxConcurrentLayers > 0 and
		       performanceConfig.CPUUsageLimit > 0
	end)
	table.insert(results, test3)
	
	-- Test 4: Timing precision
	local test4 = self:_runTest("Timing Precision", function()
		-- Test that audio sync window meets requirement (2ms)
		local expectedSyncWindow = GameConstants.Audio.AudioSyncWindow
		return expectedSyncWindow <= 0.002
	end)
	table.insert(results, test4)
	
	self._testResults.Performance = results
	self:_logTestResults("Audio Performance", results)
end

function AudioTestService:TestAudioIntegration()
	self:_log("Testing audio integration...")
	
	local audioService = self.ServiceRegistry:GetService("AudioService")
	local results = {}
	
	-- Test 1: GameConstants integration
	local test1 = self:_runTest("GameConstants Integration", function()
		local systemState = audioService:GetSystemState()
		return systemState.MasterVolume == GameConstants.Audio.MasterVolume and
		       systemState.SFXVolume == GameConstants.Audio.SFXVolume
	end)
	table.insert(results, test1)
	
	-- Test 2: Service registry integration
	local test2 = self:_runTest("Service Registry Integration", function()
		-- Verify AudioService is properly registered
		local audioServiceFromRegistry = self.ServiceRegistry:GetService("AudioService")
		return audioServiceFromRegistry ~= nil
	end)
	table.insert(results, test2)
	
	-- Test 3: Audio sequence handling
	local test3 = self:_runTest("Audio Sequence Handling", function()
		local sequenceID = audioService:PlayAudioSequence("test_sequence")
		-- Basic test - verify no errors and returns string
		return typeof(sequenceID) == "string"
	end)
	table.insert(results, test3)
	
	self._testResults.Integration = results
	self:_logTestResults("Audio Integration", results)
end

function AudioTestService:PrintTestSummary()
	self:_log("=== Audio Test Summary ===")
	
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
		self:_log("🎉 Audio system is functioning excellently!")
	elseif overallPassRate >= 75 then
		self:_log("✅ Audio system is functioning well with minor issues")
	else
		self:_log("⚠️  Audio system has significant issues that need attention")
	end
end

-- Private Testing Utilities

function AudioTestService:_runTest(testName: string, testFunction: () -> boolean): {Name: string, Passed: boolean, Error: string?}
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

function AudioTestService:_logTestResults(categoryName: string, results: any)
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

function AudioTestService:_logError(message: string)
	warn("[AudioTestService] ERROR: " .. message)
end

return AudioTestService.new() 