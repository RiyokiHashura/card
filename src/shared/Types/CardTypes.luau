--!strict
-- CardTypes.luau
-- Type definitions for the card system
-- Incorporates research-based rarity system and visual properties

local GameConstants = require(script.Parent.Parent.Constants.GameConstants)

-- Card rarity enum
export type CardRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Ultimate"

-- Card series/anime enum  
export type CardSeries = "Naruto" | "Dragon Ball" | "One Piece" | "Attack on Titan" | "Demon Slayer" | "Jujutsu Kaisen" | "My Hero Academia" | "Death Note" | "Fullmetal Alchemist" | "Hunter x Hunter"

-- Card type categories
export type CardType = "Fighter" | "Mage" | "Support" | "Tank" | "Assassin" | "Healer"

-- Visual effect data for card animations
export type CardVisualEffects = {
	BorderColor: Color3,
	EffectType: string,
	ImpactFrames: number,
	ScreenShakeIntensity: number,
	ParticleCount: number,
	SoundCategory: string,
	SpecialIntro: boolean?
}

-- Card statistics
export type CardStats = {
	Attack: number,
	Defense: number,
	Health: number,
	Speed: number,
	Energy: number, -- Cost to play the card
	Level: number -- Card level for upgrades
}

-- Complete card data structure
export type CardData = {
	-- Basic Info
	ID: string, -- Unique identifier (e.g., "naruto_001")
	Name: string, -- Character name
	Title: string?, -- Optional title (e.g., "The Seventh Hokage")
	Series: CardSeries,
	Rarity: CardRarity,
	Type: CardType,
	
	-- Stats
	Stats: CardStats,
	
	-- Visual Properties
	Image: string, -- Asset ID or path
	BackgroundImage: string?, -- Optional background for rare cards
	VisualEffects: CardVisualEffects,
	
	-- Gameplay
	SpecialAbility: string?, -- Description of special ability
	AbilityDamage: number?, -- Extra damage from ability
	AbilityCooldown: number?, -- Turns until ability can be used again
	
	-- Collection
	CollectionNumber: number, -- Number in series (1, 2, 3...)
	ReleaseDate: string, -- When card was added
	IsLimited: boolean, -- Limited time availability
	
	-- Metadata
	Description: string,
	FlavorText: string?, -- Lore/quote
	Artist: string?, -- Artist credit
	
	-- Technical
	ModelID: string?, -- 3D model reference if needed
	AnimationData: {[string]: any}? -- Animation configuration
}

-- Player's card instance (owned card with upgrades)
export type PlayerCard = {
	CardID: string, -- Reference to CardData.ID
	Level: number, -- Player's upgrade level for this card
	Experience: number, -- XP toward next level
	Quantity: number, -- How many copies player owns
	FirstObtained: number, -- Timestamp when first acquired
	IsFavorite: boolean, -- Player marked as favorite
	
	-- Calculated stats (base + level bonuses)
	CurrentStats: CardStats
}

-- Card pack/roll data
export type CardPack = {
	ID: string,
	Name: string,
	Description: string,
	Cost: number, -- In premium currency
	GuaranteedRarity: CardRarity?, -- Minimum rarity guaranteed
	CardCount: number, -- How many cards in pack
	Series: CardSeries?, -- Series-specific pack
	IsLimited: boolean, -- Limited time pack
	DropRates: {[CardRarity]: number} -- Override default drop rates
}

-- Roll result data
export type RollResult = {
	Cards: {CardData},
	TotalValue: number, -- Calculated value of roll
	HasPityBonus: boolean, -- Was pity system triggered
	IsGuaranteed: boolean, -- Was guaranteed rare
	Timestamp: number,
	PackUsed: string? -- Pack ID if from pack
}

-- Card deck for battles
export type CardDeck = {
	Name: string,
	Cards: {PlayerCard}, -- Up to 40 cards
	DateCreated: number,
	LastUsed: number,
	WinRate: number, -- Performance tracking
	TotalBattles: number
}

-- Battle card state
export type BattleCard = {
	PlayerCard: PlayerCard,
	CurrentHealth: number,
	StatusEffects: {string}, -- Active effects
	Cooldowns: {[string]: number}, -- Ability cooldowns
	Position: number, -- Position in battle lineup
	HasAttacked: boolean -- This turn
}

-- Card upgrade costs and requirements
export type CardUpgrade = {
	Level: number,
	ExperienceRequired: number,
	CostCoins: number,
	CostCards: number, -- Duplicate cards needed
	StatBonus: CardStats, -- Stat increase at this level
	UnlocksAbility: boolean? -- Does this level unlock special ability
}

-- Card collection progress
export type CollectionProgress = {
	SeriesName: CardSeries,
	TotalCards: number,
	OwnedCards: number,
	CompletionPercent: number,
	MissingCards: {string}, -- Card IDs not owned
	RarityBreakdown: {[CardRarity]: {owned: number, total: number}}
}

-- Card trading data (future feature)
export type TradeOffer = {
	ID: string,
	FromPlayer: number, -- UserID
	ToPlayer: number, -- UserID
	OfferedCards: {PlayerCard},
	RequestedCards: {PlayerCard},
	Status: "Pending" | "Accepted" | "Rejected" | "Expired",
	ExpiresAt: number,
	CreatedAt: number
}

-- Export utility type for validation
export type CardDataValidator = {
	IsValidRarity: (rarity: string) -> boolean,
	IsValidSeries: (series: string) -> boolean,
	IsValidType: (cardType: string) -> boolean,
	ValidateCardData: (card: CardData) -> boolean,
	ValidateStats: (stats: CardStats) -> boolean
}

return {} 