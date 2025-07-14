--!strict
-- BattleTypes.luau
-- Type definitions for the elevated 2D battle system

local CardTypes = require(script.Parent.CardTypes)
local PlayerTypes = require(script.Parent.PlayerTypes)
local UITypes = require(script.Parent.UITypes)

type CardData = CardTypes.CardData
type PlayerData = PlayerTypes.PlayerData

-- Battle Core Types
export type BattleSession = {
    BattleID: string,
    Player1: BattlePlayer,
    Player2: BattlePlayer,
    CurrentTurn: number,
    ActivePlayer: number, -- 1 or 2
    BattleState: BattleState,
    TurnTimer: number,
    BattleStartTime: number,
    BattleEndTime: number?,
    Winner: number?, -- 1, 2, or nil for draw
    BattleType: BattleType,
    Spectators: {number}, -- UserIDs
    BattleSettings: BattleSettings
}

export type BattlePlayer = {
    UserID: number,
    Username: string,
    Deck: {BattleCard},
    Hand: {BattleCard},
    ActiveCard: BattleCard?,
    Health: number,
    MaxHealth: number,
    Energy: number,
    MaxEnergy: number,
    Shield: number,
    StatusEffects: {StatusEffect},
    IsReady: boolean,
    LastActionTime: number,
    BattleStats: PlayerBattleStats
}

export type BattleCard = {
    InstanceID: string,
    CardData: CardData,
    CurrentHealth: number,
    MaxHealth: number,
    Attack: number,
    Defense: number,
    Energy: number,
    StatusEffects: {StatusEffect},
    Position: CardPosition,
    CanAttack: boolean,
    TurnsOnField: number,
    DamageDealt: number,
    DamageTaken: number
}

export type CardPosition = "Hand" | "Active" | "Graveyard" | "Deck"

export type BattleState = "Waiting" | "Starting" | "InProgress" | "Paused" | "Finished" | "Cancelled"

export type BattleType = "Ranked" | "Casual" | "Practice" | "Tournament" | "AI"

export type BattleSettings = {
    TurnTimeLimit: number,
    MaxTurns: number,
    StartingHealth: number,
    StartingEnergy: number,
    DeckSize: number,
    HandSize: number,
    AllowSpectators: boolean,
    RankedMatch: boolean
}

-- Action Types
export type BattleAction = {
    ActionID: string,
    PlayerID: number,
    ActionType: ActionType,
    ActionData: ActionData,
    Timestamp: number,
    IsValid: boolean,
    ProcessingTime: number?,
    VisualEffects: {VisualActionEffect}?
}

export type ActionType = "PlayCard" | "Attack" | "UseSpecial" | "EndTurn" | "Surrender" | "UseItem"

export type ActionData = {
    SourceCardID: string?,
    TargetCardID: string?,
    TargetPlayerID: number?,
    Position: CardPosition?,
    SpecialData: {[string]: any}?
}

export type VisualActionEffect = {
    EffectType: string,
    SourcePosition: Vector2?,
    TargetPosition: Vector2?,
    Duration: number,
    Intensity: number,
    Properties: {[string]: any}
}

-- Damage and Effects Types
export type DamageCalculation = {
    BaseAttack: number,
    BaseDamage: number,
    AttackModifiers: {DamageModifier},
    DefenseModifiers: {DamageModifier},
    FinalDamage: number,
    IsCritical: boolean,
    CriticalMultiplier: number,
    DamageType: DamageType,
    Penetration: number,
    MitigatedDamage: number
}

export type DamageModifier = {
    ModifierType: string,
    Value: number,
    Source: string,
    Duration: number?
}

export type DamageType = "Physical" | "Special" | "True" | "Healing"

export type StatusEffect = {
    EffectID: string,
    EffectType: StatusEffectType,
    Stacks: number,
    Duration: number,
    Intensity: number,
    Source: string,
    TickDamage: number?,
    StatModifiers: {StatModifier}?,
    VisualEffect: string?
}

export type StatusEffectType = "Poison" | "Burn" | "Freeze" | "Stun" | "Shield" | "Rage" | "Heal" | "Buff" | "Debuff"

export type StatModifier = {
    StatName: string,
    ModifierType: "Add" | "Multiply" | "Set",
    Value: number,
    Duration: number
}

-- Turn Management Types
export type TurnPhase = "Draw" | "Main" | "Attack" | "End"

export type TurnData = {
    TurnNumber: number,
    PlayerID: number,
    Phase: TurnPhase,
    PhaseStartTime: number,
    ActionsPerformed: {BattleAction},
    TimeRemaining: number,
    CanPerformActions: boolean
}

-- Battle Events Types
export type BattleEvent = {
    EventID: string,
    EventType: BattleEventType,
    PlayerID: number?,
    EventData: {[string]: any},
    Timestamp: number,
    TurnNumber: number,
    ShouldBroadcast: boolean
}

export type BattleEventType = "BattleStart" | "TurnStart" | "TurnEnd" | "CardPlayed" | "Attack" | "Damage" | 
    "StatusEffectApplied" | "StatusEffectRemoved" | "CardDestroyed" | "PlayerDefeated" | "BattleEnd"

-- Visual Effects Integration Types
export type BattleVisualEffect = {
    EffectID: string,
    EffectType: BattleEffectType,
    SourceCard: BattleCard?,
    TargetCard: BattleCard?,
    SourcePlayer: number?,
    TargetPlayer: number?,
    EffectData: BattleEffectData,
    Timing: EffectTiming,
    Priority: number
}

export type BattleEffectType = "CardPlay" | "Attack" | "Damage" | "Heal" | "StatusEffect" | "CardDestroy" | "SpecialAbility"

export type BattleEffectData = {
    Duration: number,
    Intensity: number,
    ImpactFrames: number,
    ScreenShakeIntensity: number,
    ParticleCount: number,
    AudioCues: {string},
    ColorOverride: Color3?,
    PositionData: EffectPositionData?
}

export type EffectPositionData = {
    StartPosition: Vector2,
    EndPosition: Vector2,
    ArcHeight: number?,
    Speed: number,
    EasingStyle: string
}

export type EffectTiming = {
    StartDelay: number,
    ImpactTime: number,
    EffectDuration: number,
    FadeOutTime: number
}

-- AI Battle Types
export type AIOpponent = {
    AIID: string,
    Name: string,
    Difficulty: AIDifficulty,
    Deck: {CardData},
    Personality: AIPersonality,
    BehaviorSettings: AIBehaviorSettings
}

export type AIDifficulty = "Easy" | "Medium" | "Hard" | "Expert" | "Master"

export type AIPersonality = {
    Aggression: number, -- 0-1
    Defense: number, -- 0-1
    RiskTaking: number, -- 0-1
    Patience: number, -- 0-1
    Adaptability: number -- 0-1
}

export type AIBehaviorSettings = {
    ThinkingTime: number,
    RandomnessFactor: number,
    PredictiveDepth: number,
    FavoriteStrategies: {string},
    CounterStrategies: {string}
}

-- Battle Statistics Types
export type PlayerBattleStats = {
    DamageDealt: number,
    DamageTaken: number,
    CardsPlayed: number,
    SpecialAbilitiesUsed: number,
    CriticalHits: number,
    StatusEffectsApplied: number,
    TurnsPlayed: number,
    LongestCombo: number,
    HighestSingleDamage: number,
    CardsDestroyed: number
}

export type BattleResult = {
    BattleID: string,
    Winner: number?,
    Loser: number?,
    BattleDuration: number,
    TotalTurns: number,
    Player1Stats: PlayerBattleStats,
    Player2Stats: PlayerBattleStats,
    ExperienceGained: {[number]: number},
    RewardsEarned: {[number]: BattleRewards},
    RankingChanges: {[number]: number}?
}

export type BattleRewards = {
    Coins: number,
    Experience: number,
    Cards: {CardData}?,
    Items: {string}?,
    Achievements: {string}?
}

-- Matchmaking Types
export type MatchmakingRequest = {
    PlayerID: number,
    BattleType: BattleType,
    PreferredDifficulty: AIDifficulty?,
    SkillRating: number,
    SearchStartTime: number,
    MaxWaitTime: number
}

export type MatchmakingResult = {
    Success: boolean,
    BattleSession: BattleSession?,
    WaitTime: number,
    ErrorMessage: string?
}

-- Battle UI Types
export type BattleUIState = {
    IsActive: boolean,
    CurrentPhase: TurnPhase,
    SelectedCard: BattleCard?,
    ValidTargets: {BattleCard},
    CanEndTurn: boolean,
    ShowingResults: boolean,
    AnimationsPlaying: number,
    UILocked: boolean
}

export type BattleUIElements = {
    MainFrame: ScreenGui,
    BattleField: Frame,
    Player1Area: Frame,
    Player2Area: Frame,
    HandContainer: Frame,
    ActionButtons: Frame,
    StatusDisplay: Frame,
    TimerDisplay: Frame,
    EffectsLayer: Frame
}

export type CardUIData = {
    Frame: GuiObject,
    CardID: string,
    Position: Vector2,
    IsAnimating: boolean,
    IsSelected: boolean,
    IsValidTarget: boolean,
    EffectContainer: Frame
}

-- Animation Types
export type BattleAnimation = {
    AnimationID: string,
    AnimationType: BattleAnimationType,
    SourceCard: CardUIData?,
    TargetCard: CardUIData?,
    Duration: number,
    ImpactFrame: number,
    EffectIntensity: number,
    OnComplete: (() -> ())?,
    OnImpact: (() -> ())?
}

export type BattleAnimationType = "CardPlay" | "Attack" | "Block" | "Special" | "Destroy" | "Heal" | "StatusEffect"

-- Network Types
export type BattleMessage = {
    MessageType: BattleMessageType,
    BattleID: string,
    PlayerID: number,
    MessageData: any,
    Timestamp: number,
    Sequence: number
}

export type BattleMessageType = "Action" | "StateUpdate" | "Event" | "Chat" | "Disconnect" | "Reconnect"

-- Service Response Types
export type BattleServiceResponse<T> = {
    Success: boolean,
    Data: T?,
    ErrorMessage: string?,
    ProcessingTime: number,
    BattleID: string?
}

export type ActionValidationResult = {
    IsValid: boolean,
    ErrorReason: string?,
    SuggestedActions: {ActionType}?
}

export type StartBattleRequest = {
	BattleType: "PVE" | "PVP_RANDOM" | "PVP_FRIEND",
	OpponentId: string?, -- For PVE or specific PVP
	DeckId: string?,
	BattlefieldId: string?
}

-- Configuration Types
export type BattleConfiguration = {
    GameplaySettings: GameplaySettings,
    VisualSettings: BattleVisualSettings,
    AudioSettings: BattleAudioSettings,
    PerformanceSettings: BattlePerformanceSettings
}

export type GameplaySettings = {
    DefaultTurnTime: number,
    MaxBattleDuration: number,
    StartingResources: {[string]: number},
    DamageScaling: number,
    CriticalChance: number,
    StatusEffectDurations: {[string]: number}
}

export type BattleVisualSettings = {
    ImpactFrameDuration: number,
    ScreenShakeIntensity: number,
    ParticleQuality: string,
    AnimationSpeed: number,
    EffectLayering: boolean,
    MobileOptimizations: boolean
}

export type BattleAudioSettings = {
    SFXVolume: number,
    MusicVolume: number,
    SpatialAudio: boolean,
    AudioCompression: string,
    ImpactSoundTiming: number
}

export type BattlePerformanceSettings = {
    MaxConcurrentAnimations: number,
    ParticleLimit: number,
    EffectQuality: string,
    FrameRateTarget: number,
    MemoryLimit: number
}

return {} 