--!strict
-- GameConstants.luau
-- All game constants in one place
-- Based on industry research and optimization data

local GameConstants = {}

-- Card Rarities
GameConstants.Rarity = {
	Common = "Common",
	Uncommon = "Uncommon", 
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
	Ultimate = "Ultimate"
}

-- Rarity Colors (Industry Standard)
GameConstants.RarityColors = {
	Common = Color3.fromRGB(255, 255, 255), -- #ffffff
	Uncommon = Color3.fromRGB(30, 255, 0), -- #1eff00
	Rare = Color3.fromRGB(0, 112, 221), -- #0070dd
	Epic = Color3.fromRGB(163, 53, 238), -- #a335ee
	Legendary = Color3.fromRGB(255, 128, 0), -- #ff8000
	Ultimate = Color3.fromRGB(255, 0, 255) -- #ff00ff (Custom)
}

-- Animation Timings (Based on Research)
GameConstants.AnimationTiming = {
	-- Card Animations
	CardDraw = 0.3, -- 250-400ms optimal
	CardPlay = 0.25, -- 200-350ms optimal
	CardReveal = 1.0, -- 0.8-1.2s for rarity reveal
	
	-- Attack Phases
	AttackAnticipation = 0.2, -- 200ms
	AttackStrike = 0.15, -- 150ms
	AttackReturn = 0.25, -- 250ms
	
	-- Impact Frames (60fps)
	LightImpact = 0.05, -- 3 frames
	MediumImpact = 0.1, -- 6 frames
	HeavyImpact = 0.2, -- 12 frames
	UltimateImpact = 0.3, -- 18 frames
	
	-- UI Transitions
	UIFadeIn = 0.15,
	UIFadeOut = 0.1,
	ScreenTransition = 0.3
}

-- Screen Shake Parameters (Trauma System)
GameConstants.ScreenShake = {
	TraumaPower = 2.5, -- 2-3 optimal
	DecayRate = 0.8, -- 0.8 standard
	MaxRotation = 0.1, -- 0.1 radians
	
	-- Intensity by impact
	Light = 0.1, -- 2-4 pixel displacement
	Medium = 0.3, -- 6-10 pixel displacement
	Heavy = 0.6, -- 12-20 pixel displacement
	Ultimate = 1.0 -- Maximum trauma
}

-- Audio Settings
GameConstants.Audio = {
	-- Volume levels
	MasterVolume = 0.8,
	SFXVolume = 0.7,
	MusicVolume = 0.5,
	
	-- Timing precision
	AudioSyncWindow = 0.002, -- 2ms for perceived simultaneity
	
	-- Frequency ranges
	SubBass = {20, 60}, -- Visceral impact
	MidBass = {60, 250}, -- Weight and power
	Presence = {1000, 4000}, -- Clarity and cut
	Brilliance = {4000, 16000} -- Sparkle and magic
}

-- Performance Settings
GameConstants.Performance = {
	-- Mobile optimization
	MaxConcurrentTweens = 50,
	MaxParticles = 100,
	TextureMemoryLimit = 50 * 1024 * 1024, -- 50MB
	
	-- Frame rate targets
	TargetFPS = 60,
	MinimumFPS = 30,
	
	-- LOD distances
	HighDetailRadius = 100,
	MediumDetailRadius = 300,
	LowDetailRadius = 500
}

GameConstants.Settings = {
	AutoSaveInterval = 300,
	DefaultVolume = 0.5
}

-- UI Sizing (Mobile-First)
GameConstants.UI = {
	-- Touch targets
	MinTouchTarget = 44, -- iOS minimum
	AndroidMinTouchTarget = 48, -- Android minimum
	
	-- Card sizing (percentage of screen width)
	CardWidthPercent = 0.22, -- 20-25% optimal
	CardAspectRatio = 3/4, -- 3:4 standard
	
	-- Safe areas
	TopSafeArea = 0.1, -- 10% of screen
	BottomSafeArea = 0.25, -- 25% for card hand
	SideSafeArea = 0.05, -- 5% each side
	
	-- Spacing
	CardSpacing = 8, -- 8px minimum
	UIMargin = 16, -- 16px standard
	ButtonPadding = 12 -- 12px standard
}

-- Game Balance
GameConstants.Balance = {
	-- Starting values
	StartingLevel = 1,
	StartingRolls = 0,
	StartingCards = 0,
	StartingCoins = 1000,
	
	-- Progression
	RollsPerLevel = 50, -- Estimated from research
	MaxLevel = 100,
	
	-- Pity system
	PityThreshold = 50, -- Rolls before pity kicks in
	PityIncrement = 0.1, -- 10% increase per roll
	
	-- Base drop rates (before pity)
	BaseDropRates = {
		Common = 0.70, -- 70%
		Uncommon = 0.20, -- 20%
		Rare = 0.07, -- 7%
		Epic = 0.025, -- 2.5%
		Legendary = 0.005, -- 0.5%
		Ultimate = 0.0001 -- 0.01%
	}
}

-- Battle System
GameConstants.Battle = {
	-- HP values
	PlayerHP = 100,
	EnemyBaseHP = 100,
	
	-- Turn timing
	TurnDuration = 30, -- 30 seconds per turn
	AnimationBuffer = 2, -- 2 seconds for animations
	
	-- Deck limits
	MinDeckSize = 20,
	MaxDeckSize = 40,
	HandSize = 5,
	
	-- Damage scaling
	BaseDamage = 10,
	LevelScaling = 1.1 -- 10% per level
}

-- Remote Events
GameConstants.RemoteEvents = {
	-- Card system
	RollCard = "RollCard",
	CardRolled = "CardRolled",
	
	-- Battle system
	StartBattle = "StartBattle",
	PlayCard = "PlayCard",
	EndBattle = "EndBattle",
	
	-- Player data
	PlayerDataChanged = "PlayerDataChanged",
	SavePlayerData = "SavePlayerData"
}

-- Debug Settings
GameConstants.Debug = {
	EnableLogging = true,
	LogLevel = "INFO", -- DEBUG, INFO, WARN, ERROR
	ShowFPS = true,
	ShowMemory = true,
	EnableCheats = false
}

-- Economy
-- Correct placement for the Economy table
GameConstants.Economy = {
	RollCosts = {
		Standard = 100,
		Premium = 500,
	},
	BulkDiscounts = {
		{Quantity = 10, DiscountPercent = 0.1},
		{Quantity = 50, DiscountPercent = 0.2},
		{Quantity = 100, DiscountPercent = 0.3}
	}
}

-- Rarity Data for effects
GameConstants.RarityData = {
	Common = {
		EffectIntensity = 0.3,
		Color = Color3.fromRGB(255, 255, 255)
	},
	Uncommon = {
		EffectIntensity = 0.4,
		Color = Color3.fromRGB(30, 255, 0)
	},
	Rare = {
		EffectIntensity = 0.5,
		Color = Color3.fromRGB(0, 112, 221)
	},
	Epic = {
		EffectIntensity = 0.7,
		Color = Color3.fromRGB(163, 53, 238)
	},
	Legendary = {
		EffectIntensity = 0.9,
		Color = Color3.fromRGB(255, 128, 0)
	},
	Ultimate = {
		EffectIntensity = 1.0,
		Color = Color3.fromRGB(255, 0, 255)
	},
	Mythical = {
		EffectIntensity = 0.95,
		Color = Color3.fromRGB(255, 0, 128)
	}
}

-- Export
return GameConstants 