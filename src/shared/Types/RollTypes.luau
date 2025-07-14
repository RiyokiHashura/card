--!strict
-- RollTypes.luau
-- Type definitions for the card roll system with pity mechanics

local CardTypes = require(script.Parent.CardTypes)
local PlayerTypes = require(script.Parent.PlayerTypes)

type CardData = CardTypes.CardData

-- Roll Request Types
export type RollRequest = {
    Player: Player,
    RollType: RollType,
    Count: number,
    UseGuarantee: boolean?,
    SpecificRarity: string?
}

export type RollType = "Daily" | "Premium" | "Bonus" | "Event" | "Pity"

-- Roll Result Types
export type RollResult = {
    Success: boolean,
    Cards: {CardRollResult},
    TotalCards: number,
    PityUsed: {string}, -- Which pity types were used
    GuaranteeUsed: boolean,
    RollCost: RollCost,
    TimingData: RollTimingData,
    ErrorMessage: string?
}

export type CardRollResult = {
    Card: CardData,
    Rarity: string,
    IsNew: boolean,
    IsPityResult: boolean,
    PityCount: number,
    RollPosition: number, -- Position in the roll sequence
    AnimationDelay: number, -- Milliseconds delay for reveal
    EffectIntensity: number -- 0-1 for visual effects
}

export type RollCost = {
    Currency: string, -- "Coins", "Gems", "DailyRolls", "PremiumRolls"
    Amount: number,
    OriginalAmount: number,
    Discount: number?
}

export type RollTimingData = {
    RequestTime: number,
    ProcessTime: number,
    ResponseTime: number,
    OptimalRevealTime: number, -- Calculated optimal reveal timing
    PsychologicalDelay: number -- Additional delay for anticipation
}

-- Pity System Types
export type PityConfig = {
    SoftPityStart: number,
    HardPityLimit: number,
    SoftPityIncrease: number,
    BaseRate: number,
    MaxRate: number,
    RarityName: string
}

export type PityCalculation = {
    CurrentPity: number,
    SoftPityActive: boolean,
    HardPityActive: boolean,
    CurrentRate: number,
    BaseRate: number,
    NextGuaranteeIn: number
}

export type PitySystemState = {
    [string]: PityCalculation -- Rarity -> PityCalculation
}

-- Roll Animation Types
export type RollAnimation = {
    Duration: number,
    RevealSequence: {RevealStep},
    AudioCues: {AudioCue},
    VisualEffects: {VisualEffect}
}

export type RevealStep = {
    StepIndex: number,
    Delay: number,
    RevealType: string, -- "fade", "flip", "burst", "cascade"
    Intensity: number,
    AudioTrigger: string?
}

export type AudioCue = {
    SoundName: string,
    Timing: number,
    Frequency: number,
    Volume: number,
    Rarity: string?
}

export type VisualEffect = {
    EffectName: string,
    Timing: number,
    Duration: number,
    Intensity: number,
    Rarity: string?
}

-- Roll Statistics Types
export type RollSession = {
    SessionID: string,
    Player: Player,
    StartTime: number,
    EndTime: number?,
    TotalRolls: number,
    TotalCost: RollCost,
    CardsObtained: {CardRollResult},
    PityUsages: {string},
    AverageRevealTime: number,
    PsychologicalScore: number -- Engagement metric
}

export type RollStatistics = {
    TotalRolls: number,
    RollsByRarity: {[string]: number},
    AverageRollsPerRarity: {[string]: number},
    PityUsageRate: number,
    OptimalTimingHitRate: number,
    PlayerEngagementScore: number
}

-- Roll Economy Types
export type RollPricing = {
    DailyRolls: {
        Cost: number,
        Currency: string,
        Limit: number,
        ResetTime: number
    },
    PremiumRolls: {
        Cost: number,
        Currency: string,
        BonusMultiplier: number
    },
    BulkDiscounts: {BulkDiscount}
}

export type BulkDiscount = {
    Quantity: number,
    DiscountPercent: number,
    BonusRolls: number?
}

-- Roll Event Types
export type RollEvent = {
    EventID: string,
    EventName: string,
    StartTime: number,
    EndTime: number,
    RateBoosts: {[string]: number}, -- Rarity -> multiplier
    SpecialCards: {string}, -- Special event cards
    BonusRolls: number,
    EventCurrency: string?
}

-- Roll Validation Types
export type RollValidation = {
    IsValid: boolean,
    CanAfford: boolean,
    HasRollsRemaining: boolean,
    CooldownRemaining: number,
    ErrorReason: string?
}

-- Roll Queue Types (for high-load scenarios)
export type RollQueueItem = {
    RequestID: string,
    Player: Player,
    Request: RollRequest,
    Priority: number,
    QueueTime: number,
    EstimatedProcessTime: number
}

export type RollQueue = {
    Items: {RollQueueItem},
    ProcessingCount: number,
    AverageProcessTime: number,
    MaxQueueSize: number
}

-- Roll Analytics Types
export type RollAnalytics = {
    HourlyRolls: {[number]: number},
    PopularRarities: {[string]: number},
    PitySystemEfficiency: number,
    RevenuePerRoll: number,
    PlayerRetentionByRolls: {[number]: number}
}

-- Roll Configuration Types
export type RollSystemConfig = {
    PityConfigs: {[string]: PityConfig},
    TimingConfig: RollTimingConfig,
    AnimationConfig: RollAnimationConfig,
    EconomyConfig: RollEconomyConfig,
    ValidationConfig: RollValidationConfig
}

export type RollTimingConfig = {
    OptimalRevealBase: number, -- Base optimal reveal time (2000ms)
    PsychologicalDelayMin: number,
    PsychologicalDelayMax: number,
    RarityDelayMultiplier: {[string]: number},
    AnticipationBuildupTime: number,
    SatisfactionHoldTime: number
}

export type RollAnimationConfig = {
    DefaultDuration: number,
    RarityDurations: {[string]: number},
    EffectIntensities: {[string]: number},
    AudioFrequencies: {[string]: number},
    VisualLayers: {[string]: number}
}

export type RollEconomyConfig = {
    DailyRollCount: number,
    PremiumRollCost: number,
    BulkDiscountTiers: {BulkDiscount},
    EventMultipliers: {[string]: number}
}

export type RollValidationConfig = {
    MaxRollsPerSecond: number,
    MaxRollsPerMinute: number,
    CooldownBetweenRolls: number,
    MaxConcurrentRolls: number,
    AntiCheatValidation: boolean
}

-- Service Response Types
export type RollServiceResponse<T> = {
    Success: boolean,
    Data: T?,
    ErrorMessage: string?,
    ProcessingTime: number,
    RequestID: string?
}

return {} 