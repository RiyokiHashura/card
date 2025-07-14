--!strict
-- AudioController.luau
-- Client-side audio controller that interfaces with AudioService
-- Provides local audio playback with psychological timing and frequency layering

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local AudioTypes = require(ReplicatedStorage.Shared.Types.AudioTypes)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)

type AudioContext = AudioTypes.AudioContext
type PsychologicalAudioConfig = AudioTypes.PsychologicalAudioConfig
type AudioCue = AudioTypes.AudioCue
type AudioSequence = AudioTypes.AudioSequence

local Player = Players.LocalPlayer

local AudioController = {}
AudioController.__index = AudioController
setmetatable(AudioController, {__index = BaseController})

function AudioController.new()
	local self = BaseController.new("AudioController", {})
	setmetatable(self, AudioController)
	
	-- Audio state
	self._isEnabled = true
	self._masterVolume = GameConstants.Audio.MasterVolume
	self._sfxVolume = GameConstants.Audio.SFXVolume
	self._musicVolume = GameConstants.Audio.MusicVolume
	self._isMuted = false
	
	-- Local audio management
	self._activeSounds = {} :: {[string]: Sound}
	self._soundGroups = {} :: {[string]: SoundGroup}
	self._audioQueue = {} :: {AudioCue}
	self._localSequences = {} :: {[string]: AudioSequence}
	
	-- Psychological state tracking
	self._currentContext = {
		CurrentScene = "Menu",
		PlayerState = "Idle", 
		TensionLevel = 0.0,
		ExcitementLevel = 0.0,
		RecentActions = {},
		SessionLength = 0,
		LastMajorEvent = "SessionStart",
		NextExpectedEvent = "CardRoll"
	} :: AudioContext
	
	-- Performance tracking
	self._performanceMetrics = {
		LocalSounds = 0,
		QueuedSounds = 0,
		LatencyMS = 0
	}
	
	-- Audio events from server (using individual GetRemoteEvent calls)
	self._events = {
		AudioCueRequested = RemoteEventHandler:GetRemoteEvent("AudioCueRequested"),
		AudioSequenceRequested = RemoteEventHandler:GetRemoteEvent("AudioSequenceRequested"),
		AudioContextChanged = RemoteEventHandler:GetRemoteEvent("AudioContextChanged"),
		AudioSettingsChanged = RemoteEventHandler:GetRemoteEvent("AudioSettingsChanged"),
		PsychologicalEventTriggered = RemoteEventHandler:GetRemoteEvent("PsychologicalEventTriggered"),
		SpatialAudioUpdate = RemoteEventHandler:GetRemoteEvent("SpatialAudioUpdate")
	}
	
	return self
end

function AudioController:Initialize()
	self:_log("AudioController initializing...")
	
	-- Initialize sound service settings
	self:_initializeSoundService()
	
	-- Create sound groups for frequency layering
	self:_createSoundGroups()
	
	-- Setup remote event handlers
	self:_setupRemoteEventHandlers()
	
	-- Initialize user preferences
	self:_loadUserAudioSettings()
	
	self:_log("AudioController initialized successfully")
end

function AudioController:Start()
	self:_log("AudioController starting...")
	
	-- Start audio processing loop
	self:_startAudioProcessingLoop()
	
	-- Setup input handlers for audio controls
	self:_setupInputHandlers()
	
	-- Request initial audio context from server
	self:_requestAudioContextUpdate()
	
	self:_log("AudioController started successfully")
end

function AudioController:Stop()
	self:_log("AudioController stopping...")
	
	-- Stop all active audio
	self:StopAllAudio()
	
	-- Cleanup audio processing
	if self._audioProcessingConnection then
		self._audioProcessingConnection:Disconnect()
		self._audioProcessingConnection = nil
	end
	
	BaseController.Stop(self)
	self:_log("AudioController stopped")
end

-- Public API

-- Play audio cue with optional psychological configuration
function AudioController:PlayAudioCue(cueID: string, config: PsychologicalAudioConfig?): string
	if not self._isEnabled or self._isMuted then
		return ""
	end
	
	-- Generate local instance ID
	local instanceID = self:_generateInstanceID(cueID)
	
	-- Create audio cue
	local audioCue = self:_createAudioCue(cueID, config)
	if not audioCue then
		self:_logError("Failed to create audio cue: " .. cueID)
		return ""
	end
	
	-- Apply psychological timing if configured
	if config then
		self:_applyPsychologicalTiming(audioCue, config)
	end
	
	-- Play locally with frequency layering
	self:_playAudioCueLocally(audioCue, instanceID)
	
	-- Also request from server for synchronized experience
	if self._events.AudioCueRequested then
		self._events.AudioCueRequested:FireServer(cueID, config)
	end
	
	return instanceID
end

-- Play audio sequence with crossfading
function AudioController:PlayAudioSequence(sequenceID: string, config: PsychologicalAudioConfig?): string
	if not self._isEnabled or self._isMuted then
		return ""
	end
	
	local instanceID = self:_generateInstanceID(sequenceID)
	
	-- Request sequence from server
	if self._events.AudioSequenceRequested then
		self._events.AudioSequenceRequested:FireServer(sequenceID, config)
	end
	
	return instanceID
end

-- Update current audio context for psychological adaptation
function AudioController:UpdateAudioContext(context: AudioContext)
	self._currentContext = context
	
	-- Apply context-based audio changes
	self:_adaptToContext(context)
	
	-- Notify server of context change
	if self._events.AudioContextChanged then
		self._events.AudioContextChanged:FireServer(context)
	end
	
	self:_log("Audio context updated: " .. context.CurrentScene)
end

-- Trigger psychological audio event (e.g., card reveal, battle victory)
function AudioController:TriggerPsychologicalEvent(eventType: string, intensity: number, duration: number?)
	-- Update local context
	self._currentContext.TensionLevel = math.min(1.0, self._currentContext.TensionLevel + intensity * 0.3)
	self._currentContext.ExcitementLevel = math.min(1.0, self._currentContext.ExcitementLevel + intensity * 0.5)
	
	-- Play appropriate audio response
	local audioResponse = self:_createPsychologicalResponse(eventType, intensity)
	if audioResponse then
		self:PlayAudioCue(audioResponse, {
			RarityLevel = self:_intensityToRarity(intensity),
			DopamineProfile = {
				BuildupCurve = "exponential",
				PeakIntensity = intensity,
				SustainDuration = duration or 1.0,
				ReleaseCurve = "logarithmic",
				NextEventPrep = 0.5
			},
			PsychologicalTiming = {
				AnticipationDelay = 0.1,
				ImpactTiming = 0.05,
				ResolutionFade = 0.5,
				NextCuePrep = 0.2
			},
			FrequencyEmphasis = self:_getFrequencyEmphasisForEvent(eventType),
			SpatialEffects = intensity > 0.7,
			CompressionLevel = math.max(0.3, 1.0 - intensity)
		})
	end
	
	self:_log("Psychological event triggered: " .. eventType .. " (intensity: " .. intensity .. ")")
end

-- Audio volume controls
function AudioController:SetMasterVolume(volume: number)
	self._masterVolume = math.clamp(volume, 0.0, 1.0)
	self:_updateSoundGroupVolumes()
	self:_saveUserAudioSettings()
end

function AudioController:SetSFXVolume(volume: number)
	self._sfxVolume = math.clamp(volume, 0.0, 1.0)
	if self._soundGroups.SFX then
		self._soundGroups.SFX.Volume = self._sfxVolume * self._masterVolume
	end
	self:_saveUserAudioSettings()
end

function AudioController:SetMusicVolume(volume: number)
	self._musicVolume = math.clamp(volume, 0.0, 1.0)
	if self._soundGroups.Music then
		self._soundGroups.Music.Volume = self._musicVolume * self._masterVolume
	end
	self:_saveUserAudioSettings()
end

function AudioController:ToggleMute()
	self._isMuted = not self._isMuted
	
	if self._isMuted then
		self:StopAllAudio()
	end
	
	self:_updateSoundGroupVolumes()
	self:_saveUserAudioSettings()
	
	self:_log("Audio " .. (self._isMuted and "muted" or "unmuted"))
end

-- Stop specific audio instance
function AudioController:StopAudio(instanceID: string)
	if self._activeSounds[instanceID] then
		self._activeSounds[instanceID]:Stop()
		self._activeSounds[instanceID]:Destroy()
		self._activeSounds[instanceID] = nil
		self._performanceMetrics.LocalSounds = math.max(0, self._performanceMetrics.LocalSounds - 1)
	end
end

-- Stop all audio
function AudioController:StopAllAudio()
	for instanceID, sound in pairs(self._activeSounds) do
		sound:Stop()
		sound:Destroy()
	end
	self._activeSounds = {}
	self._localSequences = {}
	self._performanceMetrics.LocalSounds = 0
	
	self:_log("All audio stopped")
end

-- Get current audio state
function AudioController:GetAudioState()
	return {
		IsEnabled = self._isEnabled,
		IsMuted = self._isMuted,
		MasterVolume = self._masterVolume,
		SFXVolume = self._sfxVolume,
		MusicVolume = self._musicVolume,
		CurrentContext = self._currentContext,
		ActiveSounds = table.getn(self._activeSounds),
		PerformanceMetrics = self._performanceMetrics
	}
end

-- Private Methods

function AudioController:_initializeSoundService()
	-- Configure SoundService for optimal client experience
	SoundService.AmbientReverb = Enum.ReverbType.NoReverb
	SoundService.DistanceFactor = 3.33
	SoundService.DopplerScale = 1
	SoundService.RolloffScale = 1
end

function AudioController:_createSoundGroups()
	-- Create sound groups for frequency layering and categories
	local groupConfigs = {
		{name = "SFX", volume = self._sfxVolume},
		{name = "Music", volume = self._musicVolume},
		{name = "Voice", volume = 0.8},
		{name = "Ambient", volume = 0.6},
		-- Frequency-based groups
		{name = "SubBass", volume = 1.0},
		{name = "MidBass", volume = 1.0},
		{name = "Midrange", volume = 1.0},
		{name = "Presence", volume = 1.0},
		{name = "Brilliance", volume = 1.0}
	}
	
	for _, config in ipairs(groupConfigs) do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = config.name
		soundGroup.Parent = SoundService
		soundGroup.Volume = config.volume * self._masterVolume
		self._soundGroups[config.name] = soundGroup
	end
end

function AudioController:_setupRemoteEventHandlers()
	-- Handle audio cue requests from server
	if self._events.AudioCueRequested then
		self._events.AudioCueRequested.OnClientEvent:Connect(function(cueID: string, instanceID: string, audioCue: AudioCue)
			-- Server confirmed audio cue, sync locally if needed
			self:_syncAudioCue(cueID, instanceID, audioCue)
		end)
	end
	
	-- Handle audio sequence requests from server
	if self._events.AudioSequenceRequested then
		self._events.AudioSequenceRequested.OnClientEvent:Connect(function(sequenceID: string, instanceID: string, sequence: AudioSequence)
			self:_playAudioSequenceLocally(sequence, instanceID)
		end)
	end
	
	-- Handle context changes from server
	if self._events.AudioContextChanged then
		self._events.AudioContextChanged.OnClientEvent:Connect(function(context: AudioContext)
			self._currentContext = context
			self:_adaptToContext(context)
		end)
	end
	
	-- Handle psychological events from server
	if self._events.PsychologicalEventTriggered then
		self._events.PsychologicalEventTriggered.OnClientEvent:Connect(function(eventType: string, intensity: number)
			-- Server triggered psychological event, enhance locally
			self:_enhancePsychologicalEvent(eventType, intensity)
		end)
	end
end

function AudioController:_setupInputHandlers()
	-- Setup audio control input (e.g., mute key)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		
		-- M key to toggle mute
		if input.KeyCode == Enum.KeyCode.M then
			self:ToggleMute()
		end
	end)
end

function AudioController:_startAudioProcessingLoop()
	self._audioProcessingConnection = RunService.Heartbeat:Connect(function(deltaTime)
		-- Update audio context based on gameplay
		self:_updateAudioContext(deltaTime)
		
		-- Process audio queue
		self:_processAudioQueue()
		
		-- Update performance metrics
		self:_updatePerformanceMetrics()
		
		-- Clean up finished sounds
		self:_cleanupFinishedSounds()
	end)
end

function AudioController:_generateInstanceID(baseID: string): string
	return "client_" .. baseID .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

function AudioController:_createAudioCue(cueID: string, config: PsychologicalAudioConfig?): AudioCue?
	-- Create basic audio cue structure
	-- In a real implementation, this would load from an asset database
	return {
		ID = cueID,
		Name = cueID,
		SoundId = "rbxasset://sounds/" .. cueID .. ".mp3", -- Placeholder
		Volume = config and (1.0 - config.CompressionLevel) or 0.5,
		Pitch = 1.0,
		Duration = 1.0,
		Layers = {},
		Priority = 1,
		Category = "SFX",
		IsLooping = false,
		FadeInDuration = 0.1,
		FadeOutDuration = 0.1
	}
end

function AudioController:_playAudioCueLocally(audioCue: AudioCue, instanceID: string)
	local sound = Instance.new("Sound")
	sound.Name = instanceID
	sound.SoundId = audioCue.SoundId
	sound.Volume = audioCue.Volume * (self._isMuted and 0 or 1)
	sound.Pitch = audioCue.Pitch
	sound.Parent = self._soundGroups[audioCue.Category] or SoundService
	
	-- Apply timing precision
	local syncWindow = GameConstants.Audio.AudioSyncWindow
	wait(syncWindow) -- 2ms precision window
	
	sound:Play()
	
	-- Track sound
	self._activeSounds[instanceID] = sound
	self._performanceMetrics.LocalSounds = self._performanceMetrics.LocalSounds + 1
	
	-- Auto-cleanup when finished
	sound.Ended:Connect(function()
		self:StopAudio(instanceID)
	end)
end

function AudioController:_updateSoundGroupVolumes()
	local masterMultiplier = self._isMuted and 0 or self._masterVolume
	
	for groupName, soundGroup in pairs(self._soundGroups) do
		if groupName == "SFX" then
			soundGroup.Volume = self._sfxVolume * masterMultiplier
		elseif groupName == "Music" then
			soundGroup.Volume = self._musicVolume * masterMultiplier
		else
			soundGroup.Volume = masterMultiplier
		end
	end
end

function AudioController:_intensityToRarity(intensity: number): string
	if intensity >= 0.9 then return "Ultimate"
	elseif intensity >= 0.7 then return "Legendary"
	elseif intensity >= 0.5 then return "Epic"
	elseif intensity >= 0.3 then return "Rare"
	elseif intensity >= 0.1 then return "Uncommon"
	else return "Common"
	end
end

function AudioController:_getFrequencyEmphasisForEvent(eventType: string): {[string]: number}
	local emphasis = {}
	
	if eventType == "CardReveal" then
		emphasis.Presence = 1.3
		emphasis.Brilliance = 1.2
	elseif eventType == "BattleVictory" then
		emphasis.SubBass = 1.4
		emphasis.MidBass = 1.2
		emphasis.Brilliance = 1.3
	elseif eventType == "DopamineSpike" then
		emphasis.Midrange = 1.2
		emphasis.Presence = 1.4
		emphasis.Brilliance = 1.5
	end
	
	return emphasis
end

-- Placeholder methods for complex functionality
function AudioController:_loadUserAudioSettings() end
function AudioController:_saveUserAudioSettings() end
function AudioController:_requestAudioContextUpdate() end
function AudioController:_applyPsychologicalTiming(cue: AudioCue, config: PsychologicalAudioConfig) end
function AudioController:_syncAudioCue(cueID: string, instanceID: string, audioCue: AudioCue) end
function AudioController:_playAudioSequenceLocally(sequence: AudioSequence, instanceID: string) end
function AudioController:_adaptToContext(context: AudioContext) end
function AudioController:_enhancePsychologicalEvent(eventType: string, intensity: number) end
function AudioController:_updateAudioContext(deltaTime: number) end
function AudioController:_processAudioQueue() end
function AudioController:_updatePerformanceMetrics() end
function AudioController:_cleanupFinishedSounds() end
function AudioController:_createPsychologicalResponse(eventType: string, intensity: number): string? return "psychological_" .. eventType end

function AudioController:_logError(message: string)
	warn("[AudioController] ERROR: " .. message)
end

return AudioController.new() 