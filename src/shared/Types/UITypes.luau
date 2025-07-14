--!strict
-- UITypes.luau
-- Type definitions for the card reveal UI system and visual effects

local RollTypes = require(script.Parent.RollTypes)
local CardTypes = require(script.Parent.CardTypes)

type CardRollResult = RollTypes.CardRollResult
type CardData = CardTypes.CardData

-- Card Reveal UI Types
export type CardRevealRequest = {
    Cards: {CardRollResult},
    RevealType: RevealType,
    TotalDuration: number,
    AudioEnabled: boolean,
    EffectsEnabled: boolean,
    SkipAnimations: boolean?
}

export type RevealType = "Single" | "Multi" | "Batch" | "Guaranteed"

export type CardRevealState = {
    CurrentCard: number,
    TotalCards: number,
    RevealStartTime: number,
    IsRevealing: boolean,
    IsPaused: boolean,
    CanSkip: boolean,
    RevealProgress: number -- 0-1
}

export type CardRevealResult = {
    Success: boolean,
    CardsRevealed: number,
    TotalDuration: number,
    UserSkipped: boolean,
    ErrorMessage: string?
}

-- Animation Types
export type AnimationData = {
    Duration: number,
    EasingStyle: Enum.EasingStyle,
    EasingDirection: Enum.EasingDirection,
    RepeatCount: number,
    Reverses: boolean,
    DelayTime: number
}

export type CardAnimationSequence = {
    CardID: string,
    Rarity: string,
    Animations: {AnimationStep},
    TotalDuration: number,
    EffectIntensity: number
}

export type AnimationStep = {
    StepName: string,
    StartTime: number,
    Duration: number,
    AnimationType: AnimationType,
    Properties: {[string]: any},
    EasingData: AnimationData,
    AudioCue: string?
}

export type AnimationType = "Position" | "Size" | "Rotation" | "Transparency" | "Color" | "Effect"

-- Visual Effect Types
export type VisualEffect = {
    EffectID: string,
    EffectType: EffectType,
    Duration: number,
    StartTime: number,
    EndTime: number,
    Properties: EffectProperties,
    Target: Instance?,
    IsActive: boolean
}

export type EffectType = "Particle" | "Light" | "ScreenShake" | "Flash" | "Glow" | "Sparkle" | "Explosion" | "Aura"

export type EffectProperties = {
    Color: Color3?,
    Size: number?,
    Intensity: number?,
    Speed: number?,
    Lifetime: number?,
    EmissionRate: number?,
    SpreadAngle: number?,
    Texture: string?,
    Transparency: number?,
    Position: Vector3?,
    Rotation: Vector3?
}

-- Screen Effect Types
export type ScreenEffect = {
    EffectName: string,
    Duration: number,
    Intensity: number,
    Color: Color3?,
    StartTime: number,
    FadeInTime: number,
    FadeOutTime: number,
    Properties: {[string]: any}
}

export type ScreenShakeData = {
    Intensity: number,
    Duration: number,
    Frequency: number,
    Decay: number,
    Trauma: number,
    StartTime: number
}

-- Audio Types
export type AudioCue = {
    SoundID: string,
    Volume: number,
    Pitch: number,
    PlayTime: number,
    Duration: number,
    FadeIn: number?,
    FadeOut: number?,
    Loop: boolean,
    Rarity: string?
}

export type AudioSequence = {
    SequenceID: string,
    AudioCues: {AudioCue},
    TotalDuration: number,
    IsPlaying: boolean,
    CurrentCue: number
}

-- UI Element Types
export type CardDisplayElement = {
    Frame: GuiObject,
    CardImage: ImageLabel,
    RarityBorder: ImageLabel,
    NameLabel: TextLabel,
    StatsFrame: Frame,
    EffectContainer: Frame,
    IsVisible: boolean,
    CurrentCard: CardData?
}

export type RevealUIElements = {
    MainFrame: ScreenGui,
    RevealContainer: Frame,
    CardDisplays: {CardDisplayElement},
    ProgressBar: Frame,
    SkipButton: TextButton,
    ContinueButton: TextButton,
    BackgroundOverlay: Frame,
    EffectsLayer: Frame
}

-- Layout Types
export type CardLayoutConfig = {
    CardSize: UDim2,
    CardSpacing: number,
    MaxCardsPerRow: number,
    AnimationStartPosition: UDim2,
    AnimationEndPosition: UDim2,
    ScaleMultiplier: number
}

export type ResponsiveLayout = {
    Mobile: CardLayoutConfig,
    Tablet: CardLayoutConfig,
    Desktop: CardLayoutConfig,
    Console: CardLayoutConfig
}

-- Input Types
export type RevealInputAction = {
    ActionType: InputActionType,
    InputObject: InputObject?,
    Timestamp: number,
    IsProcessed: boolean
}

export type InputActionType = "Skip" | "Continue" | "Pause" | "Resume" | "Tap" | "Hold"

-- Performance Types
export type PerformanceMetrics = {
    FrameRate: number,
    MemoryUsage: number,
    ActiveAnimations: number,
    ActiveEffects: number,
    RenderTime: number,
    LastUpdateTime: number
}

export type OptimizationSettings = {
    MaxConcurrentAnimations: number,
    MaxParticleCount: number,
    EffectQuality: EffectQuality,
    ReduceMotion: boolean,
    SkipComplexEffects: boolean
}

export type EffectQuality = "Low" | "Medium" | "High" | "Ultra"

-- Rarity Specific Types
export type RarityVisualConfig = {
    BorderColor: Color3,
    GlowColor: Color3,
    ParticleColor: Color3,
    EffectIntensity: number,
    AnimationDuration: number,
    AudioFrequency: number,
    ScreenShakeIntensity: number,
    FlashIntensity: number
}

export type RarityConfigs = {
    [string]: RarityVisualConfig -- Rarity name -> config
}

-- Timing Types
export type TimingCalculation = {
    OptimalRevealTime: number,
    PsychologicalDelay: number,
    AnticipationPhase: number,
    RevealPhase: number,
    SatisfactionPhase: number,
    TotalTime: number
}

export type TimingPhase = "Anticipation" | "Buildup" | "Reveal" | "Satisfaction" | "Transition"

-- Event Types
export type UIEvent = {
    EventType: UIEventType,
    EventData: {[string]: any},
    Timestamp: number,
    PlayerID: number?
}

export type UIEventType = "RevealStarted" | "RevealCompleted" | "CardRevealed" | "EffectTriggered" | "UserSkipped" | "AnimationFinished"

-- Controller State Types
export type ControllerState = {
    IsInitialized: boolean,
    IsRevealing: boolean,
    CurrentRevealID: string?,
    QueuedReveals: {CardRevealRequest},
    ActiveEffects: {VisualEffect},
    UIElements: RevealUIElements?,
    PerformanceMode: EffectQuality,
    LastRevealTime: number
}

-- Configuration Types
export type UIConfiguration = {
    RarityConfigs: RarityConfigs,
    ResponsiveLayouts: ResponsiveLayout,
    AnimationSettings: AnimationSettings,
    AudioSettings: AudioSettings,
    PerformanceSettings: PerformanceSettings
}

export type AnimationSettings = {
    DefaultDuration: number,
    EasingStyle: Enum.EasingStyle,
    EasingDirection: Enum.EasingDirection,
    ScaleMultiplier: number,
    FadeInTime: number,
    FadeOutTime: number,
    StaggerDelay: number
}

export type AudioSettings = {
    MasterVolume: number,
    SFXVolume: number,
    MusicVolume: number,
    AudioEnabled: boolean,
    FrequencyEnabled: boolean,
    SpatialAudioEnabled: boolean
}

export type PerformanceSettings = {
    MaxFPS: number,
    EffectQuality: EffectQuality,
    ParticleLimit: number,
    AnimationLimit: number,
    AutoOptimize: boolean,
    PerformanceMonitoring: boolean
}

-- Utility Types
export type Color3WithAlpha = {
    Color: Color3,
    Alpha: number
}

export type Vector3WithTime = {
    Vector: Vector3,
    Time: number
}

export type AnimationPromise = {
    IsCompleted: boolean,
    IsCancelled: boolean,
    OnCompleted: (boolean) -> (),
    OnProgress: (number) -> (),
    Cancel: () -> ()
}

-- Service Response Types
export type UIServiceResponse<T> = {
    Success: boolean,
    Data: T?,
    ErrorMessage: string?,
    ProcessingTime: number
}

return {} 