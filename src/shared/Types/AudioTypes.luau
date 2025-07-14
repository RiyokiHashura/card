--!strict
-- AudioTypes.luau
-- Comprehensive audio type definitions for psychological audio design
-- Supports frequency layering, timing precision, and spatial audio

-- Basic Audio Types
export type AudioFrequencyRange = {
	Low: number,
	High: number
}

export type AudioLayer = {
	Name: string,
	FrequencyRange: AudioFrequencyRange,
	Volume: number,
	Pitch: number,
	Reverb: number,
	Delay: number,
	IsActive: boolean
}

export type AudioCue = {
	ID: string,
	Name: string,
	SoundId: string,
	Volume: number,
	Pitch: number,
	Duration: number,
	Layers: {AudioLayer},
	Priority: number,
	Category: string,
	IsLooping: boolean,
	FadeInDuration: number,
	FadeOutDuration: number
}

export type AudioSequence = {
	ID: string,
	Name: string,
	AudioCues: {AudioCue},
	TotalDuration: number,
	IsLooping: boolean,
	CrossfadeDuration: number,
	SyncWindow: number -- 2ms precision window
}

-- Psychological Audio Design
export type PsychologicalTiming = {
	AnticipationDelay: number, -- Build tension
	ImpactTiming: number, -- Peak satisfaction moment
	ResolutionFade: number, -- Emotional release
	NextCuePrep: number -- Prepare for next audio event
}

export type DopamineProfile = {
	BuildupCurve: string, -- "linear", "exponential", "logarithmic"
	PeakIntensity: number, -- 0.0 to 1.0
	SustainDuration: number,
	ReleaseCurve: string,
	NextEventPrep: number -- Priming for next dopamine hit
}

export type PsychologicalAudioConfig = {
	RarityLevel: string,
	DopamineProfile: DopamineProfile,
	PsychologicalTiming: PsychologicalTiming,
	FrequencyEmphasis: {[string]: number}, -- Which frequency bands to emphasize
	SpatialEffects: boolean,
	CompressionLevel: number -- Dynamic range compression for mobile
}

-- Frequency Layering System
export type FrequencyLayer = {
	Name: string, -- "SubBass", "MidBass", "Presence", "Brilliance"
	FrequencyRange: AudioFrequencyRange,
	Purpose: string, -- "impact", "clarity", "magic", "weight"
	IntensityMultiplier: number,
	PsychologicalEffect: string, -- "tension", "satisfaction", "excitement", "calm"
	Priority: number -- For mobile optimization
}

export type FrequencyLayerConfig = {
	SubBass: FrequencyLayer, -- 20-60Hz: Visceral impact
	MidBass: FrequencyLayer, -- 60-250Hz: Weight and power  
	LowMid: FrequencyLayer, -- 250-500Hz: Fullness
	Midrange: FrequencyLayer, -- 500-1000Hz: Core presence
	UpperMid: FrequencyLayer, -- 1000-4000Hz: Clarity and cut
	Presence: FrequencyLayer, -- 4000-8000Hz: Sparkle
	Brilliance: FrequencyLayer, -- 8000-16000Hz: Magic and air
	ActiveLayers: {string}, -- Which layers are currently active
	MobileOptimization: boolean
}

-- Spatial Audio
export type SpatialAudioConfig = {
	IsEnabled: boolean,
	ListenerPosition: Vector3,
	ListenerOrientation: Vector3,
	RoomSize: string, -- "small", "medium", "large"
	ReverbAmount: number,
	DopplerEffect: boolean,
	DistanceAttenuation: number,
	MaxAudibleDistance: number
}

export type AudioSource = {
	ID: string,
	Position: Vector3,
	Orientation: Vector3,
	Volume: number,
	AttenuationRadius: number,
	IsDirectional: boolean,
	ConeAngle: number,
	IsLooping: boolean,
	CurrentCue: AudioCue?
}

-- Audio Context and Environment
export type AudioContext = {
	CurrentScene: string, -- "Menu", "CardRoll", "Battle", "Collection"
	PlayerState: string, -- "Idle", "Rolling", "Battling", "Browsing"
	TensionLevel: number, -- 0.0 to 1.0
	ExcitementLevel: number, -- 0.0 to 1.0
	RecentActions: {string}, -- Last 5 player actions for context
	SessionLength: number, -- How long player has been playing
	LastMajorEvent: string, -- Last significant event for pacing
	NextExpectedEvent: string -- What's coming next
}

export type AudioEnvironment = {
	AmbientProfile: string, -- "Calm", "Tense", "Exciting", "Magical"
	ReverbSettings: {
		RoomSize: number,
		Wetness: number,
		Decay: number,
		DiffusionLevel: number
	},
	CompressionSettings: {
		Threshold: number,
		Ratio: number,
		Attack: number,
		Release: number,
		MakeupGain: number
	},
	EQSettings: {
		LowShelf: number,
		LowMid: number,
		HighMid: number,
		HighShelf: number
	}
}

-- Performance and Optimization
export type AudioPerformanceConfig = {
	MaxConcurrentSounds: number,
	MaxConcurrentLayers: number,
	MobileOptimizationLevel: number, -- 0-3
	AudioCompressionLevel: number,
	SampleRateOptimization: boolean,
	BitrateLimit: number,
	CPUUsageLimit: number, -- % of CPU for audio
	MemoryUsageLimit: number -- MB limit for audio
}

export type AudioStreamingConfig = {
	PreloadDistance: number, -- Distance to preload audio
	StreamingQuality: string, -- "Low", "Medium", "High"
	BufferSize: number,
	CompressionType: string, -- "OGG", "MP3", "WAV"
	AdaptiveQuality: boolean, -- Adjust quality based on performance
	NetworkOptimization: boolean
}

-- Analytics and Monitoring
export type AudioAnalytics = {
	PlaybackEvents: {string},
	PsychologicalResponse: {
		TensionCurve: {number},
		SatisfactionSpikes: {number},
		EngagementLevel: number,
		AudioDropoffs: {string} -- Where players mute/lower audio
	},
	PerformanceMetrics: {
		CPUUsage: number,
		MemoryUsage: number,
		LatencyMS: number,
		DroppedFrames: number
	},
	PlayerPreferences: {
		PreferredVolumeLevels: {[string]: number},
		DisabledCategories: {string},
		SpatialAudioUsage: boolean,
		QualityPreference: string
	}
}

-- Main Audio System State
export type AudioSystemState = {
	IsInitialized: boolean,
	CurrentContext: AudioContext,
	ActiveAudioSources: {[string]: AudioSource},
	ActiveSequences: {[string]: AudioSequence},
	FrequencyConfig: FrequencyLayerConfig,
	SpatialConfig: SpatialAudioConfig,
	PerformanceConfig: AudioPerformanceConfig,
	Analytics: AudioAnalytics,
	MasterVolume: number,
	SFXVolume: number,
	MusicVolume: number,
	VoiceVolume: number,
	IsAudioEnabled: boolean,
	IsMuted: boolean,
	LastUpdateTime: number
}

-- Service Interface Types
export type AudioServiceConfig = {
	EnablePsychologicalDesign: boolean,
	EnableFrequencyLayering: boolean,
	EnableSpatialAudio: boolean,
	EnableAnalytics: boolean,
	MobileOptimizationLevel: number,
	DebugMode: boolean
}

export type AudioServiceEvents = {
	AudioCueStarted: (cueID: string) -> (),
	AudioCueFinished: (cueID: string) -> (),
	SequenceStarted: (sequenceID: string) -> (),
	SequenceFinished: (sequenceID: string) -> (),
	PsychologicalEventTriggered: (eventType: string, intensity: number) -> (),
	FrequencyLayerChanged: (layerName: string, isActive: boolean) -> (),
	SpatialAudioEvent: (sourceID: string, eventType: string) -> (),
	AudioError: (errorType: string, message: string) -> ()
}

return {} 