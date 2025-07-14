--!strict
-- PlayerTypes.luau
-- Comprehensive type definitions for player data management

local CardTypes = require(script.Parent.CardTypes)

-- Player Statistics
export type PlayerStats = {
    Level: number,
    Experience: number,
    ExperienceToNext: number,
    TotalRolls: number,
    RollsToNextPity: number,
    BattlesWon: number,
    BattlesLost: number,
    WinRate: number,
    HighestWinStreak: number,
    CurrentWinStreak: number,
    TotalDamageDealt: number,
    TotalDamageReceived: number,
    FavoriteCard: string?, -- Card ID
    PlayTime: number, -- in seconds
    FirstLoginTime: number, -- Unix timestamp
    LastLoginTime: number, -- Unix timestamp
    LoginStreak: number,
    DailyRollsUsed: number,
    DailyRollsResetTime: number -- Unix timestamp
}

-- Card Collection Data
export type CardCollection = {
    OwnedCards: {[string]: CardInstance}, -- Card ID -> CardInstance
    CardCounts: {[string]: number}, -- Card ID -> count
    TotalCardsOwned: number,
    UniqueCardsOwned: number,
    FavoriteCards: {string}, -- Array of Card IDs
    RecentlyObtained: {string}, -- Array of Card IDs with timestamps
    CollectionValue: number -- Total value of collection
}

-- Individual Card Instance
export type CardInstance = {
    ID: string,
    CardID: string, -- Reference to CardData
    ObtainedTime: number, -- Unix timestamp
    TimesUsed: number,
    WinsWithCard: number,
    LossesWithCard: number,
    DamageDealt: number,
    IsNew: boolean,
    IsFavorite: boolean
}

-- Player Progression
export type PlayerProgression = {
    CurrentDeck: {string}, -- Array of Card IDs (max 5)
    UnlockedFeatures: {string}, -- Array of feature names
    Achievements: {string}, -- Array of achievement IDs
    QuestProgress: {[string]: number}, -- Quest ID -> progress
    CompletedQuests: {string}, -- Array of quest IDs
    TutorialProgress: {[string]: boolean}, -- Tutorial step -> completed
    LastSeenNews: string?, -- News ID
    Settings: PlayerSettings
}

-- Player Settings
export type PlayerSettings = {
    SoundEnabled: boolean,
    MusicEnabled: boolean,
    SoundVolume: number,
    MusicVolume: number,
    ScreenShakeEnabled: boolean,
    ScreenShakeIntensity: number,
    AutoPlay: boolean,
    SkipAnimations: boolean,
    ShowDamageNumbers: boolean,
    ShowCardTooltips: boolean,
    ChatEnabled: boolean,
    FriendRequestsEnabled: boolean,
    DataCollectionConsent: boolean
}

-- Pity System Data
export type PityData = {
    CommonPity: number,
    RarePity: number,
    EpicPity: number,
    LegendaryPity: number,
    MythicalPity: number,
    UltimatePity: number,
    LastLegendaryRoll: number,
    LastMythicalRoll: number,
    LastUltimateRoll: number,
    GuaranteedNext: string?, -- Rarity type
    RollHistory: {RollResult} -- Last 100 rolls
}

-- Roll Result
export type RollResult = {
    CardID: string,
    Rarity: string,
    RollTime: number,
    PityUsed: boolean,
    RollType: string -- "daily", "premium", "bonus"
}

-- Complete Player Data
export type PlayerData = {
    UserID: number,
    Username: string,
    Stats: PlayerStats,
    Collection: CardCollection,
    Progression: PlayerProgression,
    PityData: PityData,
    Economy: PlayerEconomy,
    Social: PlayerSocial,
    DataVersion: number,
    LastSaveTime: number,
    IsDirty: boolean -- For save optimization
}

-- Player Economy
export type PlayerEconomy = {
    Coins: number,
    Gems: number,
    DailyRolls: number,
    PremiumRolls: number,
    BattleTokens: number,
    LastDailyReward: number,
    LastWeeklyReward: number,
    PurchaseHistory: {PurchaseRecord},
    SpentTotal: number,
    EarnedTotal: number
}

-- Purchase Record
export type PurchaseRecord = {
    ProductID: string,
    ProductName: string,
    Price: number,
    Currency: string,
    PurchaseTime: number,
    DevProductID: number?
}

-- Player Social Data
export type PlayerSocial = {
    Friends: {number}, -- Array of UserIDs
    BlockedUsers: {number}, -- Array of UserIDs
    GuildID: string?,
    GuildRank: string?,
    RecentOpponents: {RecentOpponent},
    Reputation: number,
    ReportsMade: number,
    ReportsReceived: number,
    LastReportTime: number
}

-- Recent Opponent
export type RecentOpponent = {
    UserID: number,
    Username: string,
    BattleTime: number,
    BattleResult: string, -- "win", "loss", "draw"
    BattleRating: number?
}

-- Data Service Response Types
export type DataServiceResponse<T> = {
    Success: boolean,
    Data: T?,
    ErrorMessage: string?
}

export type SaveResult = {
    Success: boolean,
    SaveTime: number,
    ErrorMessage: string?
}

-- Player Session Data (runtime only)
export type PlayerSession = {
    UserID: number,
    SessionStartTime: number,
    LastActivityTime: number,
    ActiveBattleID: string?,
    CurrentLocation: string, -- "lobby", "battle", "collection", etc.
    PendingNotifications: {string},
    TempData: {[string]: any},
    IsAFK: boolean,
    AFKStartTime: number?
}

return {} 