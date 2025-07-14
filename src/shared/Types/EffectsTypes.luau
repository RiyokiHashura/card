--!strict
-- EffectsTypes.luau
-- Advanced visual effects type definitions for premium polish
-- Includes screen effects, particle systems, impact frames, and visual juice

-- Screen Effects Types
export type ScreenEffect = {
	Name: string,
	Type: string, -- "ChromaticAberration", "Bloom", "Distortion", "Vignette", "ColorGrading"
	Intensity: number, -- 0.0 to 1.0
	Duration: number,
	FadeInTime: number,
	FadeOutTime: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
	IsLooping: boolean,
	Priority: number -- Higher priority effects override lower ones
}

export type ChromaticAberrationEffect = {
	Intensity: number, -- 0.0 to 1.0, controls color separation
	RedOffset: Vector2, -- Pixel offset for red channel
	GreenOffset: Vector2, -- Pixel offset for green channel  
	BlueOffset: Vector2, -- Pixel offset for blue channel
	RadialDistortion: number, -- 0.0 to 1.0, screen edge emphasis
	DistortionCenter: Vector2 -- Center point for radial effect
}

export type BloomEffect = {
	Intensity: number, -- 0.0 to 2.0, brightness multiplier
	Threshold: number, -- 0.0 to 1.0, brightness threshold for bloom
	Size: number, -- 0.0 to 5.0, bloom spread radius
	SoftKnee: number, -- 0.0 to 1.0, soft threshold transition
	Color: Color3, -- Bloom tint color
	Saturation: number -- 0.0 to 2.0, color saturation boost
}

export type DistortionEffect = {
	Type: string, -- "Wave", "Ripple", "Twist", "Bulge", "Pinch"
	Strength: number, -- 0.0 to 1.0, distortion intensity
	Center: Vector2, -- Distortion origin point
	Radius: number, -- Effect radius in pixels
	Frequency: number, -- For wave effects
	Speed: number, -- Animation speed
	Direction: Vector2 -- For directional effects
}

export type ColorGradingEffect = {
	Contrast: number, -- 0.0 to 2.0, default 1.0
	Brightness: number, -- -1.0 to 1.0, default 0.0
	Saturation: number, -- 0.0 to 2.0, default 1.0
	Hue: number, -- -180 to 180 degrees
	Temperature: number, -- -100 to 100, color temperature
	Tint: number, -- -100 to 100, green/magenta tint
	Gamma: number, -- 0.1 to 3.0, default 1.0
	ColorFilter: Color3 -- Multiplicative color filter
}

export type VignetteEffect = {
	Intensity: number, -- 0.0 to 1.0, darkness at edges
	Smoothness: number, -- 0.0 to 1.0, edge softness
	Roundness: number, -- 0.0 to 1.0, circular vs square shape
	Center: Vector2, -- Vignette center point
	Color: Color3, -- Vignette color (usually black)
	Feather: number -- 0.0 to 1.0, feathering amount
}

-- Particle System Types
export type ParticleConfig = {
	ParticleType: string, -- "Spark", "Glow", "Smoke", "Magic", "Energy", "Explosion"
	Count: number, -- Number of particles to spawn
	LifeTime: NumberRange, -- Particle lifetime range
	Size: NumberSequence, -- Size over lifetime
	Color: ColorSequence, -- Color over lifetime
	Transparency: NumberSequence, -- Transparency over lifetime
	Velocity: Vector3, -- Initial velocity
	VelocityVariation: Vector3, -- Velocity randomization
	Acceleration: Vector3, -- Constant acceleration (gravity, etc.)
	Drag: number, -- Air resistance
	RotationSpeed: NumberRange, -- Rotation speed range
	EmissionRate: number, -- Particles per second
	BurstCount: number, -- Particles in initial burst
	Texture: string, -- Particle texture ID
	BlendMode: Enum.BlendMode,
	ZOffset: number -- Depth sorting offset
}

export type ParticlePool = {
	ParticleType: string,
	PoolSize: number,
	ActiveParticles: {any}, -- Array of active particle objects
	InactiveParticles: {any}, -- Array of inactive particle objects
	CreatedCount: number, -- Total particles created
	RecycledCount: number, -- Total particles recycled
	MaxActiveParticles: number, -- Performance limit
	LastCleanupTime: number -- For optimization
}

export type ParticleSystem = {
	Name: string,
	Position: Vector3,
	IsActive: boolean,
	Duration: number, -- System lifetime, -1 for infinite
	Pools: {[string]: ParticlePool}, -- Particle type pools
	EmissionSettings: {[string]: ParticleConfig},
	PerformanceLevel: number, -- 0-3, adjusts quality
	AttachedTo: Instance?, -- Optional attachment point
	LocalSpace: boolean -- Particles move with attachment
}

-- Impact Frame Types  
export type ImpactFrame = {
	Name: string,
	Duration: number, -- Frame freeze duration (research: 50-200ms)
	Intensity: number, -- 0.0 to 1.0, effect strength
	FrameHold: number, -- Actual frame hold time (1-12 frames at 60fps)
	SlowMotion: number, -- 0.0 to 1.0, time scale during impact
	ScreenShake: boolean, -- Apply screen shake during impact
	ChromaticShift: boolean, -- Apply chromatic aberration
	SoundPunch: boolean, -- Audio emphasis during impact
	VisualPunch: boolean, -- Visual scaling/flash effect
	EaseInTime: number, -- Transition into impact
	EaseOutTime: number -- Transition out of impact
}

export type ImpactTiming = {
	AnticipationFrames: number, -- Windup frames before impact
	ImpactFrames: number, -- Actual impact duration
	RecoveryFrames: number, -- Frames after impact
	TotalSequenceTime: number, -- Complete sequence duration
	ImpactIntensityCurve: NumberSequence, -- Intensity over time
	TimingPrecision: number -- Frame precision (16.67ms for 60fps)
}

export type ImpactType = {
	Light: ImpactFrame, -- Quick hits, 50ms (3 frames)
	Medium: ImpactFrame, -- Standard hits, 100ms (6 frames)  
	Heavy: ImpactFrame, -- Strong hits, 167ms (10 frames)
	Ultimate: ImpactFrame, -- Legendary impacts, 200ms (12 frames)
	Critical: ImpactFrame -- Special critical hits
}

-- Visual Juice Types
export type JuiceEffect = {
	Name: string,
	Type: string, -- "Scale", "Rotation", "Position", "Color", "Glow", "Pulse"
	TriggerEvent: string, -- What triggers this effect
	StartValue: any, -- Initial value
	EndValue: any, -- Target value
	Duration: number,
	Delay: number, -- Delay before starting
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
	RepeatCount: number, -- -1 for infinite
	Reverses: boolean, -- Plays backwards after forward
	YieldUntilFinished: boolean
}

export type JuiceSequence = {
	Name: string,
	Effects: {JuiceEffect}, -- Multiple effects in sequence
	ParallelEffects: {JuiceEffect}, -- Effects that play simultaneously
	TotalDuration: number,
	IsLooping: boolean,
	Priority: number,
	InterruptBehavior: string -- "Cancel", "Complete", "Queue"
}

export type VisualJuiceConfig = {
	ButtonHover: JuiceSequence,
	ButtonPress: JuiceSequence,
	CardReveal: JuiceSequence,
	CardPull: JuiceSequence,
	RarityReveal: JuiceSequence,
	BattleHit: JuiceSequence,
	VictorySequence: JuiceSequence,
	LevelUp: JuiceSequence,
	ErrorFeedback: JuiceSequence,
	SuccessFeedback: JuiceSequence
}

-- Performance and Optimization Types
export type EffectsPerformanceConfig = {
	MaxScreenEffects: number, -- Concurrent screen effects limit
	MaxParticleSystems: number, -- Concurrent particle systems limit
	MaxParticlesPerSystem: number, -- Particles per system limit
	ParticlePoolSizes: {[string]: number}, -- Pool sizes by type
	EffectQualityLevel: number, -- 0-3, adjusts all effect quality
	MobileOptimizations: boolean,
	PerformanceMonitoring: boolean,
	AutoQualityAdjustment: boolean, -- Adjust quality based on performance
	FrameRateThreshold: number -- Minimum FPS before quality reduction
}

export type EffectsLODConfig = {
	HighQuality: EffectsPerformanceConfig, -- Desktop high-end
	MediumQuality: EffectsPerformanceConfig, -- Desktop mid-range  
	LowQuality: EffectsPerformanceConfig, -- Mobile/low-end
	UltraLowQuality: EffectsPerformanceConfig -- Emergency fallback
}

-- Animation and Timing Types
export type AnimationCurve = {
	CurveType: string, -- "Linear", "EaseIn", "EaseOut", "EaseInOut", "Bounce", "Elastic"
	Strength: number, -- Curve strength modifier
	Overshoot: number, -- For elastic/bounce curves
	Period: number, -- For periodic curves
	CustomPoints: {Vector2}? -- For custom bezier curves
}

export type TimingFunction = {
	Name: string,
	Function: (t: number) -> number, -- t goes from 0 to 1
	Description: string,
	RecommendedUse: string, -- When to use this timing function
	ResearchBasis: string -- Research supporting this timing
}

export type EffectTiming = {
	StartTime: number, -- When effect begins
	Duration: number, -- Effect duration
	FadeInTime: number, -- Fade in duration
	FadeOutTime: number, -- Fade out duration
	PeakTime: number, -- When effect reaches maximum
	TimingCurve: AnimationCurve,
	SyncWithAudio: boolean, -- Sync with audio events
	FrameAccurate: boolean -- Ensure frame-perfect timing
}

-- Research-Based Constants
export type EffectResearchData = {
	OptimalImpactDuration: NumberRange, -- 50-200ms from research
	AttentionGrabbingColors: {Color3}, -- Colors that grab attention
	SatisfactionCurves: {[string]: AnimationCurve}, -- Psychologically satisfying curves
	PerformanceLimits: {
		MobileParticleLimit: number, -- 50-100 particles max
		DesktopParticleLimit: number, -- 200-500 particles max  
		ScreenEffectLimit: number, -- 3-5 concurrent effects max
		FrameRateImpact: number -- % FPS impact per effect
	},
	UserPreferences: {
		PreferredEffectIntensity: NumberRange, -- Most players prefer 0.6-0.8
		MotionSensitivityThreshold: number, -- When to reduce effects
		FlashingSensitivityLimit: number -- Maximum flashing frequency
	}
}

-- Main Effects System State
export type EffectsSystemState = {
	IsInitialized: boolean,
	CurrentQualityLevel: number,
	ActiveScreenEffects: {[string]: ScreenEffect},
	ActiveParticleSystems: {[string]: ParticleSystem},
	ActiveImpactFrames: {[string]: ImpactFrame},
	ActiveJuiceSequences: {[string]: JuiceSequence},
	PerformanceConfig: EffectsPerformanceConfig,
	ResearchData: EffectResearchData,
	FrameRate: number, -- Current FPS
	EffectCount: number, -- Total active effects
	ParticleCount: number, -- Total active particles
	LastOptimizationTime: number
}

-- Service Interface Types
export type PolishEffectsServiceConfig = {
	EnableScreenEffects: boolean,
	EnableParticleEffects: boolean,
	EnableImpactFrames: boolean,
	EnableVisualJuice: boolean,
	AutoQualityAdjustment: boolean,
	MobileOptimizations: boolean,
	PerformanceMonitoring: boolean,
	DebugMode: boolean
}

export type PolishEffectsEvents = {
	ScreenEffectStarted: (effectName: string) -> (),
	ScreenEffectFinished: (effectName: string) -> (),
	ParticleSystemSpawned: (systemName: string, position: Vector3) -> (),
	ImpactFrameTriggered: (impactType: string, intensity: number) -> (),
	VisualJuiceTriggered: (sequenceName: string) -> (),
	QualityLevelChanged: (newLevel: number, reason: string) -> (),
	PerformanceWarning: (warningType: string, metrics: any) -> ()
}

return {} 