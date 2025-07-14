--!strict
-- PolishEffectsController.luau
-- Client-side visual effects controller for premium polish
-- Handles screen effects, particles, impact frames, and visual juice locally

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local EffectsTypes = require(ReplicatedStorage.Shared.Types.EffectsTypes)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)

type ScreenEffect = EffectsTypes.ScreenEffect
type ParticleSystem = EffectsTypes.ParticleSystem
type ImpactFrame = EffectsTypes.ImpactFrame
type JuiceSequence = EffectsTypes.JuiceSequence
type ChromaticAberrationEffect = EffectsTypes.ChromaticAberrationEffect
type BloomEffect = EffectsTypes.BloomEffect

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PolishEffectsController = {}
PolishEffectsController.__index = PolishEffectsController
setmetatable(PolishEffectsController, {__index = BaseController})

function PolishEffectsController.new()
	local self = BaseController.new("PolishEffectsController", {"AudioController"})
	setmetatable(self, PolishEffectsController)
	
	-- Visual Effects State
	self._isEnabled = true
	self._qualityLevel = 2
	self._frameRate = 60
	
	-- Active Effects
	self._activeScreenEffects = {} :: {[string]: any}
	self._activeParticleEmitters = {} :: {[string]: ParticleEmitter}
	self._activeJuiceAnimations = {} :: {[string]: Tween}
	self._impactFrameData = {} :: {[string]: any}
	
	-- Performance Management
	self._particlePool = {} :: {[string]: {ParticleEmitter}}
	self._effectCount = 0
	self._particleCount = 0
	self._lastOptimization = 0
	
	-- Screen Effect Elements
	self._screenEffectGui = nil :: ScreenGui?
	self._chromaticFrame = nil :: Frame?
	self._bloomFrame = nil :: Frame?
	self._vignetteFrame = nil :: Frame?
	self._distortionFrame = nil :: Frame?
	
	-- Impact Frame State
	self._originalTimeScale = 1.0
	self._impactFrameActive = false
	
	-- Research-Based Configurations
	self._researchConfig = {
		ImpactDurations = {
			Light = 0.05, -- 3 frames at 60fps
			Medium = 0.1, -- 6 frames at 60fps
			Heavy = 0.167, -- 10 frames at 60fps
			Ultimate = 0.2 -- 12 frames at 60fps
		},
		SatisfactionCurves = {
			ButtonPress = Enum.EasingStyle.Back,
			CardReveal = Enum.EasingStyle.Elastic,
			Victory = Enum.EasingStyle.Bounce
		},
		OptimalIntensities = {
			Hover = 0.1,
			Press = 0.3,
			Success = 0.7,
			Epic = 0.9
		}
	}
	
	-- Events from server (using individual GetRemoteEvent calls)
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

function PolishEffectsController:Initialize()
	self:_log("PolishEffectsController initializing...")
	
	-- Initialize screen effects GUI
	self:_initializeScreenEffectsGUI()
	
	-- Initialize particle pools
	self:_initializeParticlePools()
	
	-- Setup remote event handlers
	self:_setupRemoteEventHandlers()
	
	-- Initialize performance monitoring
	self:_initializePerformanceMonitoring()
	
	self:_log("PolishEffectsController initialized successfully")
end

function PolishEffectsController:Start()
	self:_log("PolishEffectsController starting...")
	
	-- Start effects update loop
	self:_startEffectsUpdateLoop()
	
	-- Start performance monitoring
	self:_startPerformanceMonitoring()
	
	self:_log("PolishEffectsController started successfully")
end

function PolishEffectsController:Stop()
	self:_log("PolishEffectsController stopping...")
	
	-- Stop all effects
	self:StopAllEffects()
	
	-- Cleanup connections
	if self._effectsUpdateConnection then
		self._effectsUpdateConnection:Disconnect()
		self._effectsUpdateConnection = nil
	end
	
	if self._performanceConnection then
		self._performanceConnection:Disconnect()
		self._performanceConnection = nil
	end
	
	BaseController.Stop(self)
	self:_log("PolishEffectsController stopped")
end

-- Public API

-- Screen Effects
function PolishEffectsController:PlayScreenEffect(effectName: string, intensity: number?, duration: number?): string
	if not self._isEnabled then
		return ""
	end
	
	local effectID = self:_generateEffectID(effectName)
	
	-- Create screen effect based on type
	local success = false
	
	if effectName == "ChromaticAberration" then
		success = self:_playChromaticAberration(effectID, intensity or 0.7, duration or 1.0)
	elseif effectName == "Bloom" then
		success = self:_playBloom(effectID, intensity or 0.7, duration or 1.0)
	elseif effectName == "Vignette" then
		success = self:_playVignette(effectID, intensity or 0.7, duration or 1.0)
	elseif effectName == "Distortion" then
		success = self:_playDistortion(effectID, intensity or 0.7, duration or 1.0)
	else
		self:_logError("Unknown screen effect: " .. effectName)
		return ""
	end
	
	if success then
		self._effectCount = self._effectCount + 1
		self:_log("Screen effect started: " .. effectName .. " (ID: " .. effectID .. ")")
		return effectID
	else
		return ""
	end
end

-- Particle Systems
function PolishEffectsController:SpawnParticleEffect(effectType: string, position: Vector3, guiObject: GuiObject?): string
	local effectID = self:_generateEffectID(effectType)
	
	-- Get particle emitter from pool
	local emitter = self:_getParticleFromPool(effectType)
	if not emitter then
		self:_logError("Failed to create particle emitter for: " .. effectType)
		return ""
	end
	
	-- Configure the emitter
	self:_configureParticleEmitter(emitter, effectType, position)
	
	-- Enable the emitter
	emitter.Enabled = true
	
	-- Auto-disable after duration
	spawn(function()
		wait(self:_getParticleEffectDuration(effectType))
		emitter.Enabled = false
		
		-- Return to pool after cleanup
		spawn(function()
			wait(2.0) -- Allow existing particles to finish
			self:_returnParticleToPool(emitter)
		end)
	end)
	
	-- Track active emitter
	self._activeParticleEmitters[effectID] = emitter
	self._particleCount = self._particleCount + 1
	
	self:_log("Particle effect spawned: " .. effectType .. " (ID: " .. effectID .. ")")
	return effectID
end

-- Impact Frames with research-based timing
function PolishEffectsController:TriggerImpactFrame(impactType: string, intensity: number?, targetPosition: Vector3?): string
	if not self._isEnabled or self._impactFrameActive then
		return ""
	end
	
	local frameID = self:_generateEffectID(impactType .. "_impact")
	
	-- Get research-based timing
	local duration = self._researchConfig.ImpactDurations[impactType] or 0.1
	intensity = intensity or 0.7
	
	-- Store original game speed
	self._originalTimeScale = workspace.CurrentCamera.FieldOfView
	self._impactFrameActive = true
	
	-- Execute impact frame sequence
	self:_executeImpactFrameSequence(impactType, intensity, duration, frameID, targetPosition)
	
	-- Track impact frame
	self._impactFrameData[frameID] = {
		Type = impactType,
		Intensity = intensity,
		Duration = duration,
		StartTime = tick()
	}
	
	self:_log("Impact frame triggered: " .. impactType .. " (ID: " .. frameID .. ")")
	return frameID
end

-- Visual Juice Effects
function PolishEffectsController:PlayVisualJuice(sequenceName: string, targetObject: Instance, config: any?): string
	if not self._isEnabled or not targetObject then
		return ""
	end
	
	local juiceID = self:_generateEffectID(sequenceName .. "_juice")
	
	-- Get juice sequence configuration
	local sequence = self:_getJuiceSequenceConfig(sequenceName, config)
	if not sequence then
		self:_logError("Unknown visual juice sequence: " .. sequenceName)
		return ""
	end
	
	-- Execute juice sequence
	local tween = self:_createJuiceTween(targetObject, sequence)
	if tween then
		-- Track animation
		self._activeJuiceAnimations[juiceID] = tween
		
		-- Start animation
		tween:Play()
		
		-- Auto-cleanup when finished
		tween.Completed:Connect(function()
			self._activeJuiceAnimations[juiceID] = nil
		end)
		
		self:_log("Visual juice started: " .. sequenceName .. " (ID: " .. juiceID .. ")")
		return juiceID
	else
		self:_logError("Failed to create visual juice: " .. sequenceName)
		return ""
	end
end

-- Enhanced Button Interactions
function PolishEffectsController:EnhanceButton(button: GuiButton, config: EffectsTypes.ButtonEnhancementConfig?)
	-- Default configuration
	local buttonConfig = config or {
		HoverScale = 1.05, -- This will now be treated as a pixel offset
		PressScale = 0.95, -- This will now be treated as a pixel offset
		HoverDuration = 0.1,
		PressDuration = 0.05,
		EasingStyle = Enum.EasingStyle.Quad
	}
	
	-- Store original properties
	local originalSize = button.AbsoluteSize
	button.AnchorPoint = Vector2.new(0.5, 0.5) -- Ensure scaling is from the center
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		local hoverSize = UDim2.fromOffset(originalSize.X + 10, originalSize.Y + 10) -- Add 10px on hover
		TweenService:Create(button, TweenInfo.new(buttonConfig.HoverDuration), {Size = hoverSize}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		local normalSize = UDim2.fromOffset(originalSize.X, originalSize.Y)
		TweenService:Create(button, TweenInfo.new(buttonConfig.HoverDuration), {Size = normalSize}):Play()
	end)
	
	-- Press effects
	button.MouseButton1Down:Connect(function()
		local pressSize = UDim2.fromOffset(originalSize.X - 5, originalSize.Y - 5) -- Subtract 5px on press
		TweenService:Create(button, TweenInfo.new(buttonConfig.PressDuration), {Size = pressSize}):Play()
		self:TriggerImpactFrame("Light", 0.3)
	end)
	
	button.MouseButton1Up:Connect(function()
		local hoverSize = UDim2.fromOffset(originalSize.X + 10, originalSize.Y + 10) -- Return to hover size
		TweenService:Create(button, TweenInfo.new(buttonConfig.PressDuration * 2), {Size = hoverSize}):Play()
	end)
	
	self:_log("Button enhanced: " .. button.Name)
end

-- Card-Specific Effects
function PolishEffectsController:PlayCardRevealEffect(cardFrame: Frame, rarity: string): string
	if not cardFrame then return "" end
	
	local effectID = self:_generateEffectID("card_reveal")
	
	-- Rarity-based effects
	local intensity = self:_getRarityIntensity(rarity)
	local duration = self:_getRarityDuration(rarity)
	
	-- Play multiple synchronized effects
	spawn(function()
		-- Visual juice sequence
		self:PlayVisualJuice("CardReveal", cardFrame, {
			Intensity = intensity,
			Duration = duration
		})
		
		-- Screen effect for higher rarities
		if intensity > 0.6 then
			self:PlayScreenEffect("Bloom", intensity * 0.8, duration * 0.5)
		end
		
		if intensity > 0.8 then
			self:PlayScreenEffect("ChromaticAberration", intensity * 0.6, duration * 0.3)
		end
		
		-- Particle effects
		if intensity > 0.5 then
			local cardPosition = self:_getWorldPositionFromGui(cardFrame)
			self:SpawnParticleEffect("CardSparkle", cardPosition, cardFrame)
		end
		
		-- Impact frame for legendary+ cards
		if intensity > 0.7 then
			wait(duration * 0.3) -- Timing for maximum impact
			self:TriggerImpactFrame(intensity > 0.9 and "Ultimate" or "Heavy", intensity)
		end
	end)
	
	self:_log("Card reveal effect started: " .. rarity .. " (ID: " .. effectID .. ")")
	return effectID
end

-- Stop Effects
function PolishEffectsController:StopScreenEffect(effectID: string)
	if self._activeScreenEffects[effectID] then
		local effect = self._activeScreenEffects[effectID]
		if effect.Tween then
			effect.Tween:Cancel()
		end
		self._activeScreenEffects[effectID] = nil
		self._effectCount = math.max(0, self._effectCount - 1)
	end
end

function PolishEffectsController:StopParticleEffect(effectID: string)
	if self._activeParticleEmitters[effectID] then
		local emitter = self._activeParticleEmitters[effectID]
		emitter.Enabled = false
		
		-- Return to pool after cleanup delay
		spawn(function()
			wait(2.0) -- Allow existing particles to finish
			self:_returnParticleToPool(emitter)
		end)
		
		self._activeParticleEmitters[effectID] = nil
		self._particleCount = math.max(0, self._particleCount - 1)
	end
end

function PolishEffectsController:StopAllEffects()
	-- Stop screen effects
	for effectID, _ in pairs(self._activeScreenEffects) do
		self:StopScreenEffect(effectID)
	end
	
	-- Stop particle effects
	for effectID, _ in pairs(self._activeParticleEmitters) do
		self:StopParticleEffect(effectID)
	end
	
	-- Stop juice animations
	for juiceID, tween in pairs(self._activeJuiceAnimations) do
		tween:Cancel()
	end
	self._activeJuiceAnimations = {}
	
	-- Reset counters
	self._effectCount = 0
	self._particleCount = 0
	
	self:_log("All effects stopped")
end

-- Performance and Quality
function PolishEffectsController:SetQualityLevel(level: number)
	level = math.clamp(level, 0, 3)
	self._qualityLevel = level
	
	-- Adjust performance settings based on quality
	self:_adjustPerformanceForQuality(level)
	
	self:_log("Quality level set to: " .. level)
end

function PolishEffectsController:GetPerformanceMetrics()
	return {
		EffectCount = self._effectCount,
		ParticleCount = self._particleCount,
		QualityLevel = self._qualityLevel,
		FrameRate = self._frameRate,
		ActiveScreenEffects = table.getn(self._activeScreenEffects),
		ActiveParticleEffects = table.getn(self._activeParticleEmitters),
		ActiveJuiceAnimations = table.getn(self._activeJuiceAnimations)
	}
end

-- Private Methods

function PolishEffectsController:_initializeScreenEffectsGUI()
	-- Create screen effects GUI container
	self._screenEffectGui = Instance.new("ScreenGui")
	self._screenEffectGui.Name = "PolishEffectsGUI"
	self._screenEffectGui.Parent = PlayerGui
	self._screenEffectGui.ResetOnSpawn = false
	self._screenEffectGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Create effect frames
	self._chromaticFrame = self:_createEffectFrame("ChromaticAberration")
	self._bloomFrame = self:_createEffectFrame("Bloom")
	self._vignetteFrame = self:_createEffectFrame("Vignette")
	self._distortionFrame = self:_createEffectFrame("Distortion")
end

function PolishEffectsController:_createEffectFrame(effectType: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = effectType .. "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = self._screenEffectGui
	frame.ZIndex = 1000
	
	-- Add effect-specific visual elements
	if effectType == "Vignette" then
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		
		-- Create gradient for vignette effect
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0))
		gradient.Rotation = 0
		gradient.Parent = frame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
	end
	
	return frame
end

function PolishEffectsController:_initializeParticlePools()
	-- Initialize particle pools for different effect types
	local particleTypes = {"Spark", "Glow", "Magic", "Energy", "Explosion", "CardSparkle"}
	
	for _, particleType in ipairs(particleTypes) do
		self._particlePool[particleType] = {}
		
		-- Pre-create pool of particles
		for i = 1, 10 do
			local emitter = self:_createParticleEmitter(particleType)
			if emitter then
				table.insert(self._particlePool[particleType], emitter)
			end
		end
	end
end

function PolishEffectsController:_getParticleFromPool(effectType: string): ParticleEmitter?
	if not self._particlePool[effectType] then
		self._particlePool[effectType] = {}
	end
	
	local pool = self._particlePool[effectType]
	if #pool > 0 then
		return table.remove(pool, 1)
	end
	
	-- Create new emitter if pool is empty
	return self:_createParticleEmitter(effectType)
end

function PolishEffectsController:_returnParticleToPool(emitter: ParticleEmitter)
	if not emitter then return end
	
	emitter.Enabled = false
	emitter.Parent = nil
	
	-- Find the effect type
	local effectType = emitter.Name:match("(.+)Emitter") or "Default"
	
	if not self._particlePool[effectType] then
		self._particlePool[effectType] = {}
	end
	
	-- Return to pool if not full
	if #self._particlePool[effectType] < 10 then
		table.insert(self._particlePool[effectType], emitter)
	else
		emitter:Destroy()
	end
end

function PolishEffectsController:_createParticleEmitter(effectType: string): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = effectType .. "Emitter"
	
	-- Configure based on effect type
	if effectType == "GoldenNova" then
		-- Legendary card effect - golden explosion
		emitter.Rate = 200
		emitter.Lifetime = NumberRange.new(1.5, 3.0)
		emitter.Speed = NumberRange.new(5, 15)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Drag = 5
		emitter.VelocityInheritance = 0.5
		
		-- Golden colors
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),   -- Gold
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)), -- Yellow
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))    -- Orange
		})
		
		-- Size animation - starts small, grows, then shrinks
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 2),
			NumberSequenceKeypoint.new(0.7, 1.5),
			NumberSequenceKeypoint.new(1, 0)
		})
		
		-- Transparency animation
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.2, 0.1),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 0.9
		emitter.LightInfluence = 0.1
		
	elseif effectType == "RainbowCosmos" then
		-- Ultimate card effect - cosmic rainbow
		emitter.Rate = 150
		emitter.Lifetime = NumberRange.new(2.0, 4.0)
		emitter.Speed = NumberRange.new(3, 12)
		emitter.SpreadAngle = Vector2.new(360, 360)
		emitter.Drag = 3
		emitter.VelocityInheritance = 0.3
		
		-- Rainbow colors
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),    -- Green
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),   -- Blue
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),  -- Indigo
			ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))     -- Violet
		})
		
		-- Cosmic size animation
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.4, 3),
			NumberSequenceKeypoint.new(0.8, 2),
			NumberSequenceKeypoint.new(1, 0.2)
		})
		
		-- Mystical transparency
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 1.0
		emitter.LightInfluence = 0
		
	elseif effectType == "EpicSpark" then
		-- Epic card effect - purple sparks
		emitter.Rate = 100
		emitter.Lifetime = NumberRange.new(1.0, 2.5)
		emitter.Speed = NumberRange.new(4, 10)
		emitter.SpreadAngle = Vector2.new(90, 90)
		emitter.Drag = 4
		
		-- Purple spark colors
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(148, 0, 211)),   -- Violet
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(138, 43, 226)), -- Blue Violet
			ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 130))     -- Indigo
		})
		
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 1.2),
			NumberSequenceKeypoint.new(1, 0.1)
		})
		
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 0.7
		
	elseif effectType == "RareGlow" then
		-- Rare card effect - blue glow
		emitter.Rate = 60
		emitter.Lifetime = NumberRange.new(0.8, 2.0)
		emitter.Speed = NumberRange.new(2, 6)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.Drag = 6
		
		-- Blue glow colors
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 191, 255)),   -- Deep Sky Blue
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 144, 255)), -- Dodger Blue
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))      -- Blue
		})
		
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.4, 0.8),
			NumberSequenceKeypoint.new(1, 0.2)
		})
		
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.4, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 0.5
		
	elseif effectType == "UncommonShimmer" then
		-- Uncommon card effect - green shimmer
		emitter.Rate = 40
		emitter.Lifetime = NumberRange.new(0.5, 1.5)
		emitter.Speed = NumberRange.new(1, 4)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Drag = 8
		
		-- Green shimmer colors
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),     -- Lime
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 205, 50)), -- Lime Green
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 128, 0))      -- Green
		})
		
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.3, 0.5),
			NumberSequenceKeypoint.new(1, 0.1)
		})
		
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 0.3
		
	elseif effectType == "CardSparkle" then
		-- Generic card sparkle effect
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(0.5, 1.2)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.Drag = 5
		
		-- White sparkle
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 0.05)
		})
		
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		emitter.LightEmission = 0.2
		
	else
		-- Default particle effect
		emitter.Rate = 20
		emitter.Lifetime = NumberRange.new(0.5, 1.0)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		emitter.LightEmission = 0.1
	end
	
	-- Add mobile optimization
	if game:GetService("UserInputService").TouchEnabled then
		emitter.Rate = emitter.Rate * 0.7 -- Reduce particles on mobile
	end
	
	return emitter
end

function PolishEffectsController:_configureParticleEmitter(emitter: ParticleEmitter, effectType: string, position: Vector3)
	-- Apply position-based modifications
	if effectType == "GoldenNova" then
		-- Add slight upward velocity for nova effect
		emitter.Acceleration = Vector3.new(0, -2, 0)
		emitter.EmissionDirection = Enum.NormalId.Top
		
	elseif effectType == "RainbowCosmos" then
		-- Cosmic swirl effect
		emitter.Acceleration = Vector3.new(0, -1, 0)
		emitter.EmissionDirection = Enum.NormalId.Front
		
	elseif effectType == "EpicSpark" then
		-- Sparks fly outward
		emitter.Acceleration = Vector3.new(0, -5, 0)
		emitter.EmissionDirection = Enum.NormalId.Front
		
	elseif effectType == "RareGlow" then
		-- Gentle float upward
		emitter.Acceleration = Vector3.new(0, 2, 0)
		emitter.EmissionDirection = Enum.NormalId.Top
		
	elseif effectType == "UncommonShimmer" then
		-- Subtle shimmer
		emitter.Acceleration = Vector3.new(0, 1, 0)
		emitter.EmissionDirection = Enum.NormalId.Front
	end
	
	-- Create attachment point for world position
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace
	emitter.Parent = attachment
	
	-- Auto-cleanup attachment after effect
	spawn(function()
		wait(self:_getParticleEffectDuration(effectType))
		if attachment then
			attachment:Destroy()
		end
	end)
end

function PolishEffectsController:_getParticleEffectDuration(effectType: string): number
	local durations = {
		GoldenNova = 4.0,      -- Legendary needs long duration
		RainbowCosmos = 5.0,   -- Ultimate gets longest
		EpicSpark = 3.0,       -- Epic medium duration
		RareGlow = 2.5,        -- Rare shorter
		UncommonShimmer = 2.0, -- Uncommon brief
		CardSparkle = 1.5,     -- Generic short
		Default = 2.0
	}
	
	return durations[effectType] or durations.Default
end

function PolishEffectsController:_generateEffectID(baseName: string): string
	return "client_" .. baseName .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

function PolishEffectsController:_setupRemoteEventHandlers()
	-- Handle server effect requests
	if self._events.ScreenEffectRequested then
		self._events.ScreenEffectRequested.OnClientEvent:Connect(function(effectName: string, effectID: string, effect: any)
			self:PlayScreenEffect(effectName, effect.Intensity, effect.Duration)
		end)
	end
	
	if self._events.ImpactFrameRequested then
		self._events.ImpactFrameRequested.OnClientEvent:Connect(function(impactType: string, frameID: string, frame: any)
			self:TriggerImpactFrame(impactType, frame.Intensity)
		end)
	end
	
	if self._events.QualityLevelChanged then
		self._events.QualityLevelChanged.OnClientEvent:Connect(function(level: number, reason: string)
			self:SetQualityLevel(level)
		end)
	end
end

-- Placeholder methods for complex screen effects
function PolishEffectsController:_playChromaticAberration(id: string, intensity: number, duration: number): boolean
	if not self._chromaticFrame then return false end
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
	
	-- Create red/blue shifted images
	local redLayer = self._chromaticFrame:Clone()
	redLayer.ImageColor3 = Color3.new(1, 0, 0)
	redLayer.ImageTransparency = 0.8
	redLayer.Parent = self._chromaticFrame
	
	local blueLayer = self._chromaticFrame:Clone()
	blueLayer.ImageColor3 = Color3.new(0, 0, 1)
	blueLayer.ImageTransparency = 0.8
	blueLayer.Parent = self._chromaticFrame
	
	-- Animate layers
	local redTween = TweenService:Create(redLayer, tweenInfo, {Position = UDim2.new(0, intensity * 20, 0, 0)})
	local blueTween = TweenService:Create(blueLayer, tweenInfo, {Position = UDim2.new(0, -intensity * 20, 0, 0)})
	
	redTween:Play()
	blueTween:Play()
	
	-- Cleanup
	spawn(function()
		wait(duration)
		redLayer:Destroy()
		blueLayer:Destroy()
	end)
	
	return true
end

function PolishEffectsController:_playBloom(id: string, intensity: number, duration: number): boolean
	if not self._bloomFrame then return false end
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local bloomEffect = Lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
	bloomEffect.Parent = Lighting
	
	bloomEffect.Intensity = intensity
	bloomEffect.Size = 24
	bloomEffect.Threshold = 0.8
	
	-- Animate bloom intensity
	local bloomTween = TweenService:Create(bloomEffect, tweenInfo, {Intensity = 0})
	bloomTween:Play()
	
	-- Cleanup
	bloomTween.Completed:Connect(function()
		bloomEffect.Intensity = 0
	end)
	
	return true
end

function PolishEffectsController:_playVignette(id: string, intensity: number, duration: number): boolean
	if not self._vignetteFrame then return false end
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	-- Animate transparency
	self._vignetteFrame.BackgroundTransparency = 1 - intensity
	local vignetteTween = TweenService:Create(self._vignetteFrame, tweenInfo, {BackgroundTransparency = 1})
	vignetteTween:Play()
	
	return true
end

function PolishEffectsController:_playDistortion(id: string, intensity: number, duration: number): boolean
	-- Placeholder for distortion effect
	return true
end

function PolishEffectsController:_executeImpactFrameSequence(impactType: string, intensity: number, duration: number, id: string, position: Vector3?) end

function PolishEffectsController:_getJuiceSequenceConfig(sequenceName: string, config: any?): any
	if sequenceName == "ButtonHover" then
		return {
			Properties = { Size = UDim2.fromScale(1.1, 1.1) },
			Duration = 0.1,
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
		}
	elseif sequenceName == "ButtonUnhover" then
		return {
			Properties = { Size = UDim2.fromScale(1, 1) },
			Duration = 0.1,
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
		}
	elseif sequenceName == "ButtonPress" then
		return {
			Properties = { Size = UDim2.fromScale(0.9, 0.9) },
			Duration = 0.05,
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
		}
	elseif sequenceName == "ButtonRelease" then
		return {
			Properties = { Size = UDim2.fromScale(1.1, 1.1) },
			Duration = 0.1,
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
		}
	elseif sequenceName == "CardReveal" then
		return {
			Properties = { Rotation = 360, Transparency = 0 },
			Duration = 0.5,
			EasingStyle = Enum.EasingStyle.Quint,
			EasingDirection = Enum.EasingDirection.Out,
		}
	end

	return nil
end

function PolishEffectsController:_createJuiceTween(target: Instance, sequence: any): Tween?
	if not target or not sequence then
		return nil
	end

	local tweenInfo = TweenInfo.new(
		sequence.Duration,
		sequence.EasingStyle,
		sequence.EasingDirection
	)

	return TweenService:Create(target, tweenInfo, sequence.Properties)
end

function PolishEffectsController:_getRarityIntensity(rarity: string): number
	local intensities = {
		Common = 0.2,
		Uncommon = 0.3,
		Rare = 0.5,
		Epic = 0.7,
		Legendary = 0.9,
		Ultimate = 1.0
	}
	
	return intensities[rarity] or intensities.Common
end

function PolishEffectsController:_getRarityDuration(rarity: string): number
	local durations = {
		Common = 0.5,
		Uncommon = 0.8,
		Rare = 1.0,
		Epic = 1.5,
		Legendary = 2.0,
		Ultimate = 2.5
	}
	
	return durations[rarity] or durations.Common
end

function PolishEffectsController:_getWorldPositionFromGui(guiObject: GuiObject): Vector3
	-- Convert GUI position to world position for particles
	local camera = workspace.CurrentCamera
	local screenPos = guiObject.AbsolutePosition + guiObject.AbsoluteSize / 2
	
	-- Project screen position to world space
	local ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local distance = 10 -- Distance from camera
	
	return ray.Origin + ray.Direction * distance
end

function PolishEffectsController:_initializePerformanceMonitoring() end
function PolishEffectsController:_startEffectsUpdateLoop() end
function PolishEffectsController:_startPerformanceMonitoring() end
function PolishEffectsController:_adjustPerformanceForQuality(level: number) end

function PolishEffectsController:_logError(message: string)
	warn("[PolishEffectsController] ERROR: " .. message)
end

return PolishEffectsController.new() 