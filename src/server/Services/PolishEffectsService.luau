--!strict
-- PolishEffectsService.luau
-- Advanced visual effects service for premium polish
-- Manages screen effects, particles, impact frames, and visual juice

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local EffectsTypes = require(ReplicatedStorage.Shared.Types.EffectsTypes)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)

type EffectsSystemState = EffectsTypes.EffectsSystemState
type ScreenEffect = EffectsTypes.ScreenEffect
type ParticleSystem = EffectsTypes.ParticleSystem
type ImpactFrame = EffectsTypes.ImpactFrame
type JuiceSequence = EffectsTypes.JuiceSequence
type PolishEffectsServiceConfig = EffectsTypes.PolishEffectsServiceConfig
type EffectsPerformanceConfig = EffectsTypes.EffectsPerformanceConfig

local PolishEffectsService = {}
PolishEffectsService.__index = PolishEffectsService
setmetatable(PolishEffectsService, {__index = BaseService})

function PolishEffectsService.new()
	local self = BaseService.new("PolishEffectsService", {"AudioService"})
	setmetatable(self, PolishEffectsService)
	
	-- Core State
	self._systemState = {
		IsInitialized = false,
		CurrentQualityLevel = 2, -- Start at medium-high quality
		ActiveScreenEffects = {},
		ActiveParticleSystems = {},
		ActiveImpactFrames = {},
		ActiveJuiceSequences = {},
		PerformanceConfig = self:_createDefaultPerformanceConfig(),
		ResearchData = self:_createResearchData(),
		FrameRate = 60,
		EffectCount = 0,
		ParticleCount = 0,
		LastOptimizationTime = 0
	} :: EffectsSystemState
	
	-- Configuration
	self._config = {
		EnableScreenEffects = true,
		EnableParticleEffects = true,
		EnableImpactFrames = true,
		EnableVisualJuice = true,
		AutoQualityAdjustment = true,
		MobileOptimizations = true,
		PerformanceMonitoring = true,
		DebugMode = false
	} :: PolishEffectsServiceConfig
	
	-- Effect Management
	self._effectInstances = {} :: {[string]: any}
	self._particlePools = {} :: {[string]: any}
	self._activeAnimations = {} :: {[string]: Tween}
	self._impactSequences = {} :: {[string]: any}
	
	-- Performance Tracking
	self._performanceMetrics = {
		FrameTime = 0,
		EffectFrameTime = 0,
		ParticleFrameTime = 0,
		MemoryUsage = 0,
		QualityAdjustments = 0
	}
	
	-- Research-based Impact Types
	self._impactTypes = self:_createImpactTypes()
	
	-- Visual Juice Presets
	self._juicePresets = self:_createJuicePresets()
	
	-- Events (using individual GetRemoteEvent calls)
	self._events = {
		ScreenEffectRequested = RemoteEventHandler:GetRemoteEvent("ScreenEffectRequested"),
		ParticleSystemRequested = RemoteEventHandler:GetRemoteEvent("ParticleSystemRequested"),
		ImpactFrameRequested = RemoteEventHandler:GetRemoteEvent("ImpactFrameRequested"),
		VisualJuiceRequested = RemoteEventHandler:GetRemoteEvent("VisualJuiceRequested"),
		QualityLevelChanged = RemoteEventHandler:GetRemoteEvent("QualityLevelChanged"),
		PerformanceMetricsUpdate = RemoteEventHandler:GetRemoteEvent("PerformanceMetricsUpdate")
	}
	
	return self
end

function PolishEffectsService:Initialize()
	self:_log("PolishEffectsService initializing...")
	
	-- Initialize performance monitoring
	self:_initializePerformanceMonitoring()
	
	-- Initialize particle pools
	self:_initializeParticlePools()
	
	-- Initialize screen effects system
	if self._config.EnableScreenEffects then
		self:_initializeScreenEffects()
	end
	
	-- Initialize impact frame system
	if self._config.EnableImpactFrames then
		self:_initializeImpactFrames()
	end
	
	-- Initialize visual juice system
	if self._config.EnableVisualJuice then
		self:_initializeVisualJuice()
	end
	
	-- Setup remote event handlers
	self:_setupRemoteEventHandlers()
	
	-- Apply mobile optimizations if needed
	if self._config.MobileOptimizations then
		self:_applyMobileOptimizations()
	end
	
	self._systemState.IsInitialized = true
	self:_log("PolishEffectsService initialized successfully")
end

function PolishEffectsService:Start()
	self:_log("PolishEffectsService starting...")
	
	-- Start effects update loop
	self:_startEffectsUpdateLoop()
	
	-- Start performance monitoring
	if self._config.PerformanceMonitoring then
		self:_startPerformanceMonitoring()
	end
	
	-- Start auto quality adjustment
	if self._config.AutoQualityAdjustment then
		self:_startAutoQualityAdjustment()
	end
	
	self:_log("PolishEffectsService started successfully")
end

function PolishEffectsService:Stop()
	self:_log("PolishEffectsService stopping...")
	
	-- Stop all effects
	self:StopAllEffects()
	
	-- Cleanup connections
	if self._effectsUpdateConnection then
		self._effectsUpdateConnection:Disconnect()
		self._effectsUpdateConnection = nil
	end
	
	if self._performanceMonitorConnection then
		self._performanceMonitorConnection:Disconnect()
		self._performanceMonitorConnection = nil
	end
	
	BaseService.Stop(self)
	self:_log("PolishEffectsService stopped")
end

-- Public API

-- Screen Effects
function PolishEffectsService:PlayScreenEffect(effectName: string, intensity: number?, duration: number?): string
	if not self._config.EnableScreenEffects or not self._systemState.IsInitialized then
		return ""
	end
	
	-- Check performance limits
	if #self._systemState.ActiveScreenEffects >= self._systemState.PerformanceConfig.MaxScreenEffects then
		self:_optimizeScreenEffects()
	end
	
	local effectID = self:_generateEffectID(effectName)
	
	-- Create screen effect based on research data
	local screenEffect = self:_createScreenEffect(effectName, intensity or 0.7, duration or 1.0)
	if not screenEffect then
		self:_logError("Failed to create screen effect: " .. effectName)
		return ""
	end
	
	-- Apply effect
	self:_applyScreenEffect(screenEffect, effectID)
	
	-- Track effect
	self._systemState.ActiveScreenEffects[effectID] = screenEffect
	self._systemState.EffectCount = self._systemState.EffectCount + 1
	
	-- Fire event to clients
	self._events.ScreenEffectRequested:FireAllClients(effectName, effectID, screenEffect)
	
	self:_log("Screen effect started: " .. effectName .. " (ID: " .. effectID .. ")")
	return effectID
end

-- Particle Systems
function PolishEffectsService:SpawnParticleSystem(systemName: string, position: Vector3, config: any?): string
	if not self._config.EnableParticleEffects or not self._systemState.IsInitialized then
		return ""
	end
	
	-- Check performance limits
	if #self._systemState.ActiveParticleSystems >= self._systemState.PerformanceConfig.MaxParticleSystems then
		self:_optimizeParticleSystems()
	end
	
	local systemID = self:_generateEffectID(systemName)
	
	-- Create particle system with pooling
	local particleSystem = self:_createParticleSystem(systemName, position, config)
	if not particleSystem then
		self:_logError("Failed to create particle system: " .. systemName)
		return ""
	end
	
	-- Spawn particles using pooled objects
	self:_spawnParticlesFromPool(particleSystem, systemID)
	
	-- Track system
	self._systemState.ActiveParticleSystems[systemID] = particleSystem
	self._systemState.EffectCount = self._systemState.EffectCount + 1
	
	-- Fire event to clients
	self._events.ParticleSystemRequested:FireAllClients(systemName, systemID, position, config)
	
	self:_log("Particle system spawned: " .. systemName .. " (ID: " .. systemID .. ")")
	return systemID
end

-- Impact Frames (Research-based timing)
function PolishEffectsService:TriggerImpactFrame(impactType: string, intensity: number?, position: Vector3?): string
	if not self._config.EnableImpactFrames or not self._systemState.IsInitialized then
		return ""
	end
	
	local frameID = self:_generateEffectID(impactType .. "_impact")
	
	-- Get research-based impact frame configuration
	local impactFrame = self:_getImpactFrame(impactType, intensity or 0.7)
	if not impactFrame then
		self:_logError("Unknown impact type: " .. impactType)
		return ""
	end
	
	-- Apply frame timing with research precision
	self:_executeImpactFrame(impactFrame, frameID, position)
	
	-- Track impact frame
	self._systemState.ActiveImpactFrames[frameID] = impactFrame
	
	-- Sync with audio system
	local audioService = self:GetService("AudioService")
	if audioService then
		audioService:TriggerPsychologicalEvent("ImpactFrame", intensity or 0.7, impactFrame.Duration)
	end
	
	-- Fire event to clients
	self._events.ImpactFrameRequested:FireAllClients(impactType, frameID, impactFrame)
	
	self:_log("Impact frame triggered: " .. impactType .. " (ID: " .. frameID .. ")")
	return frameID
end

-- Visual Juice Effects
function PolishEffectsService:PlayVisualJuice(sequenceName: string, targetObject: Instance?, config: any?): string
	if not self._config.EnableVisualJuice or not self._systemState.IsInitialized then
		return ""
	end
	
	local juiceID = self:_generateEffectID(sequenceName .. "_juice")
	
	-- Get visual juice sequence
	local juiceSequence = self:_getJuiceSequence(sequenceName, config)
	if not juiceSequence then
		self:_logError("Unknown visual juice sequence: " .. sequenceName)
		return ""
	end
	
	-- Execute juice sequence with precise timing
	self:_executeJuiceSequence(juiceSequence, juiceID, targetObject)
	
	-- Track sequence
	self._systemState.ActiveJuiceSequences[juiceID] = juiceSequence
	
	-- Fire event to clients
	self._events.VisualJuiceRequested:FireAllClients(sequenceName, juiceID, juiceSequence)
	
	self:_log("Visual juice started: " .. sequenceName .. " (ID: " .. juiceID .. ")")
	return juiceID
end

-- Quality Management
function PolishEffectsService:SetQualityLevel(level: number, reason: string?)
	level = math.clamp(level, 0, 3)
	
	if level == self._systemState.CurrentQualityLevel then
		return
	end
	
	local oldLevel = self._systemState.CurrentQualityLevel
	self._systemState.CurrentQualityLevel = level
	
	-- Update performance configuration
	self:_updatePerformanceConfigForQuality(level)
	
	-- Optimize existing effects
	self:_optimizeExistingEffectsForQuality(level)
	
	-- Fire event
	self._events.QualityLevelChanged:FireAllClients(level, reason or "Manual")
	
	self:_log("Quality level changed: " .. oldLevel .. " -> " .. level .. " (" .. (reason or "Manual") .. ")")
end

-- Performance Management
function PolishEffectsService:GetPerformanceMetrics()
	return {
		FrameRate = self._systemState.FrameRate,
		EffectCount = self._systemState.EffectCount,
		ParticleCount = self._systemState.ParticleCount,
		ActiveScreenEffects = #self._systemState.ActiveScreenEffects,
		ActiveParticleSystems = #self._systemState.ActiveParticleSystems,
		PerformanceMetrics = self._performanceMetrics,
		QualityLevel = self._systemState.CurrentQualityLevel
	}
end

-- Stop specific effect
function PolishEffectsService:StopEffect(effectID: string)
	-- Check all effect types
	if self._systemState.ActiveScreenEffects[effectID] then
		self:_stopScreenEffect(effectID)
		self._systemState.ActiveScreenEffects[effectID] = nil
	end
	
	if self._systemState.ActiveParticleSystems[effectID] then
		self:_stopParticleSystem(effectID)
		self._systemState.ActiveParticleSystems[effectID] = nil
	end
	
	if self._systemState.ActiveJuiceSequences[effectID] then
		self:_stopJuiceSequence(effectID)
		self._systemState.ActiveJuiceSequences[effectID] = nil
	end
	
	if self._activeAnimations[effectID] then
		self._activeAnimations[effectID]:Cancel()
		self._activeAnimations[effectID] = nil
	end
	
	self._systemState.EffectCount = math.max(0, self._systemState.EffectCount - 1)
end

-- Stop all effects
function PolishEffectsService:StopAllEffects()
	-- Stop all screen effects
	for effectID, _ in pairs(self._systemState.ActiveScreenEffects) do
		self:_stopScreenEffect(effectID)
	end
	self._systemState.ActiveScreenEffects = {}
	
	-- Stop all particle systems
	for systemID, _ in pairs(self._systemState.ActiveParticleSystems) do
		self:_stopParticleSystem(systemID)
	end
	self._systemState.ActiveParticleSystems = {}
	
	-- Stop all juice sequences
	for juiceID, _ in pairs(self._systemState.ActiveJuiceSequences) do
		self:_stopJuiceSequence(juiceID)
	end
	self._systemState.ActiveJuiceSequences = {}
	
	-- Cancel all animations
	for _, tween in pairs(self._activeAnimations) do
		tween:Cancel()
	end
	self._activeAnimations = {}
	
	self._systemState.EffectCount = 0
	self._systemState.ParticleCount = 0
	
	self:_log("All effects stopped")
end

-- Get system state (for debugging)
function PolishEffectsService:GetSystemState(): EffectsSystemState
	return self._systemState
end

-- Private Methods

function PolishEffectsService:_createDefaultPerformanceConfig(): EffectsPerformanceConfig
	return {
		MaxScreenEffects = 5,
		MaxParticleSystems = 8,
		MaxParticlesPerSystem = 100,
		ParticlePoolSizes = {
			Spark = 50,
			Glow = 30,
			Smoke = 20,
			Magic = 40,
			Energy = 35,
			Explosion = 15
		},
		EffectQualityLevel = 2,
		MobileOptimizations = true,
		PerformanceMonitoring = true,
		AutoQualityAdjustment = true,
		FrameRateThreshold = 45
	}
end

function PolishEffectsService:_createResearchData()
	return {
		OptimalImpactDuration = NumberRange.new(0.05, 0.2), -- 50-200ms
		AttentionGrabbingColors = {
			Color3.fromRGB(255, 255, 0), -- Yellow
			Color3.fromRGB(255, 0, 255), -- Magenta
			Color3.fromRGB(0, 255, 255), -- Cyan
			Color3.fromRGB(255, 128, 0) -- Orange
		},
		SatisfactionCurves = {},
		PerformanceLimits = {
			MobileParticleLimit = 75,
			DesktopParticleLimit = 300,
			ScreenEffectLimit = 5,
			FrameRateImpact = 0.02 -- 2% FPS impact per effect
		},
		UserPreferences = {
			PreferredEffectIntensity = NumberRange.new(0.6, 0.8),
			MotionSensitivityThreshold = 0.3,
			FlashingSensitivityLimit = 8 -- Hz
		}
	}
end

function PolishEffectsService:_createImpactTypes()
	return {
		Light = {
			Name = "Light",
			Duration = 0.05, -- 3 frames at 60fps
			Intensity = 0.3,
			FrameHold = 3,
			SlowMotion = 0.9,
			ScreenShake = false,
			ChromaticShift = false,
			SoundPunch = true,
			VisualPunch = true,
			EaseInTime = 0.01,
			EaseOutTime = 0.04
		},
		Medium = {
			Name = "Medium",
			Duration = 0.1, -- 6 frames at 60fps
			Intensity = 0.6,
			FrameHold = 6,
			SlowMotion = 0.7,
			ScreenShake = true,
			ChromaticShift = false,
			SoundPunch = true,
			VisualPunch = true,
			EaseInTime = 0.02,
			EaseOutTime = 0.08
		},
		Heavy = {
			Name = "Heavy",
			Duration = 0.167, -- 10 frames at 60fps
			Intensity = 0.8,
			FrameHold = 10,
			SlowMotion = 0.5,
			ScreenShake = true,
			ChromaticShift = true,
			SoundPunch = true,
			VisualPunch = true,
			EaseInTime = 0.03,
			EaseOutTime = 0.137
		},
		Ultimate = {
			Name = "Ultimate",
			Duration = 0.2, -- 12 frames at 60fps
			Intensity = 1.0,
			FrameHold = 12,
			SlowMotion = 0.3,
			ScreenShake = true,
			ChromaticShift = true,
			SoundPunch = true,
			VisualPunch = true,
			EaseInTime = 0.05,
			EaseOutTime = 0.15
		}
	}
end

function PolishEffectsService:_createJuicePresets()
	-- Visual juice presets for common interactions
	return {
		ButtonHover = {
			Name = "ButtonHover",
			Effects = {},
			ParallelEffects = {
				{
					Name = "Scale",
					Type = "Scale",
					TriggerEvent = "Hover",
					StartValue = Vector3.new(1, 1, 1),
					EndValue = Vector3.new(1.05, 1.05, 1.05),
					Duration = 0.1,
					Delay = 0,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					RepeatCount = 0,
					Reverses = false,
					YieldUntilFinished = false
				}
			},
			TotalDuration = 0.1,
			IsLooping = false,
			Priority = 1,
			InterruptBehavior = "Cancel"
		},
		CardReveal = {
			Name = "CardReveal",
			Effects = {
				{
					Name = "Scale",
					Type = "Scale",
					TriggerEvent = "Reveal",
					StartValue = Vector3.new(0.8, 0.8, 0.8),
					EndValue = Vector3.new(1.1, 1.1, 1.1),
					Duration = 0.3,
					Delay = 0,
					EasingStyle = Enum.EasingStyle.Back,
					EasingDirection = Enum.EasingDirection.Out,
					RepeatCount = 0,
					Reverses = false,
					YieldUntilFinished = false
				}
			},
			ParallelEffects = {},
			TotalDuration = 0.5,
			IsLooping = false,
			Priority = 3,
			InterruptBehavior = "Complete"
		}
	}
end

function PolishEffectsService:_generateEffectID(baseName: string): string
	return baseName .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

function PolishEffectsService:_setupRemoteEventHandlers()
	-- Handle client effect requests
	self._events.ScreenEffectRequested.OnServerEvent:Connect(function(player: Player, effectName: string, intensity: number, duration: number)
		-- Validate request
		if typeof(effectName) ~= "string" then return end
		
		-- Play screen effect
		local effectID = self:PlayScreenEffect(effectName, intensity, duration)
		
		-- Send confirmation
		self._events.ScreenEffectRequested:FireClient(player, effectName, effectID)
	end)
end

function PolishEffectsService:_startEffectsUpdateLoop()
	self._effectsUpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:_updateEffectsSystem(deltaTime)
	end)
end

function PolishEffectsService:_updateEffectsSystem(deltaTime: number)
	-- Update performance metrics
	self:_updatePerformanceMetrics(deltaTime)
	
	-- Update particle systems
	self:_updateParticleSystems(deltaTime)
	
	-- Update screen effects
	self:_updateScreenEffects(deltaTime)
	
	-- Update impact frames
	self:_updateImpactFrames(deltaTime)
	
	-- Cleanup finished effects
	self:_cleanupFinishedEffects()
	
	-- Performance optimization
	if tick() - self._systemState.LastOptimizationTime > 5.0 then
		self:_performOptimizationPass()
		self._systemState.LastOptimizationTime = tick()
	end
end

-- Placeholder methods for complex functionality
function PolishEffectsService:_initializePerformanceMonitoring() end
function PolishEffectsService:_initializeParticlePools() end
function PolishEffectsService:_initializeScreenEffects() end
function PolishEffectsService:_initializeImpactFrames() end
function PolishEffectsService:_initializeVisualJuice() end
function PolishEffectsService:_applyMobileOptimizations() end
function PolishEffectsService:_startPerformanceMonitoring() end
function PolishEffectsService:_startAutoQualityAdjustment() end
function PolishEffectsService:_createScreenEffect(name: string, intensity: number, duration: number): ScreenEffect? return nil end
function PolishEffectsService:_applyScreenEffect(effect: ScreenEffect, id: string) end
function PolishEffectsService:_createParticleSystem(name: string, position: Vector3, config: any?): ParticleSystem? return nil end
function PolishEffectsService:_spawnParticlesFromPool(system: ParticleSystem, id: string) end
function PolishEffectsService:_getImpactFrame(type: string, intensity: number): ImpactFrame? return nil end
function PolishEffectsService:_executeImpactFrame(frame: ImpactFrame, id: string, position: Vector3?) end
function PolishEffectsService:_getJuiceSequence(name: string, config: any?): JuiceSequence? return nil end
function PolishEffectsService:_executeJuiceSequence(sequence: JuiceSequence, id: string, target: Instance?) end
function PolishEffectsService:_updatePerformanceConfigForQuality(level: number) end
function PolishEffectsService:_optimizeExistingEffectsForQuality(level: number) end
function PolishEffectsService:_optimizeScreenEffects() end
function PolishEffectsService:_optimizeParticleSystems() end
function PolishEffectsService:_stopScreenEffect(id: string) end
function PolishEffectsService:_stopParticleSystem(id: string) end
function PolishEffectsService:_stopJuiceSequence(id: string) end
function PolishEffectsService:_updatePerformanceMetrics(deltaTime: number) end
function PolishEffectsService:_updateParticleSystems(deltaTime: number) end
function PolishEffectsService:_updateScreenEffects(deltaTime: number) end
function PolishEffectsService:_updateImpactFrames(deltaTime: number) end
function PolishEffectsService:_cleanupFinishedEffects() end
function PolishEffectsService:_performOptimizationPass() end

function PolishEffectsService:_logError(message: string)
	warn("[PolishEffectsService] ERROR: " .. message)
end

return PolishEffectsService.new() 