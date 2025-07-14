--!strict
-- AnimeCharacters.luau
-- Database of anime characters with balanced stats and visual effects
-- Uses research-based rarity distribution and psychological appeal

local GameConstants = require(script.Parent.Parent.Constants.GameConstants)

-- Character database organized by series and rarity
local AnimeCharacters = {}

-- Naruto Series
AnimeCharacters.Naruto = {
	-- Common Cards (70% drop rate)
	{
		ID = "naruto_001",
		Name = "Naruto Uzumaki",
		Title = "Genin Ninja",
		Series = "Naruto",
		Rarity = "Common",
		Type = "Fighter",
		Stats = {
			Attack = 45,
			Defense = 35,
			Health = 80,
			Speed = 55,
			Energy = 3,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/naruto_genin.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Common,
			EffectType = "BasicShine",
			ImpactFrames = 2,
			ScreenShakeIntensity = GameConstants.ScreenShake.Light,
			ParticleCount = 10,
			SoundCategory = "Common",
			SpecialIntro = false
		},
		SpecialAbility = "Shadow Clone",
		AbilityDamage = 15,
		AbilityCooldown = 3,
		CollectionNumber = 1,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A young ninja with dreams of becoming Hokage.",
		FlavorText = "Believe it!",
		Artist = "Studio Team"
	},
	
	{
		ID = "sakura_001",
		Name = "Sakura Haruno",
		Title = "Medical Ninja",
		Series = "Naruto", 
		Rarity = "Common",
		Type = "Healer",
		Stats = {
			Attack = 30,
			Defense = 40,
			Health = 70,
			Speed = 45,
			Energy = 2,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/sakura_genin.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Common,
			EffectType = "BasicShine",
			ImpactFrames = 2,
			ScreenShakeIntensity = GameConstants.ScreenShake.Light,
			ParticleCount = 10,
			SoundCategory = "Common",
			SpecialIntro = false
		},
		SpecialAbility = "Medical Jutsu",
		AbilityDamage = 0, -- Healing ability
		AbilityCooldown = 4,
		CollectionNumber = 2,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A skilled medical ninja with incredible strength.",
		FlavorText = "Cha!",
		Artist = "Studio Team"
	},
	
	-- Uncommon Cards (20% drop rate)
	{
		ID = "sasuke_001",
		Name = "Sasuke Uchiha",
		Title = "Last Uchiha",
		Series = "Naruto",
		Rarity = "Uncommon",
		Type = "Assassin",
		Stats = {
			Attack = 65,
			Defense = 45,
			Health = 75,
			Speed = 80,
			Energy = 4,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/sasuke_sharingan.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Uncommon,
			EffectType = "GreenAura",
			ImpactFrames = 3,
			ScreenShakeIntensity = GameConstants.ScreenShake.Medium,
			ParticleCount = 20,
			SoundCategory = "Uncommon",
			SpecialIntro = false
		},
		SpecialAbility = "Sharingan",
		AbilityDamage = 25,
		AbilityCooldown = 3,
		CollectionNumber = 3,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "An elite ninja seeking power and revenge.",
		FlavorText = "I will restore my clan.",
		Artist = "Studio Team"
	},
	
	-- Rare Cards (7% drop rate)
	{
		ID = "kakashi_001",
		Name = "Kakashi Hatake",
		Title = "Copy Ninja",
		Series = "Naruto",
		Rarity = "Rare",
		Type = "Mage",
		Stats = {
			Attack = 85,
			Defense = 70,
			Health = 90,
			Speed = 75,
			Energy = 5,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/kakashi_sharingan.png",
		BackgroundImage = "rbxasset://textures/backgrounds/lightning.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Rare,
			EffectType = "BlueFlames",
			ImpactFrames = 4,
			ScreenShakeIntensity = GameConstants.ScreenShake.Medium,
			ParticleCount = 30,
			SoundCategory = "Rare",
			SpecialIntro = false
		},
		SpecialAbility = "Chidori",
		AbilityDamage = 40,
		AbilityCooldown = 4,
		CollectionNumber = 4,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "The infamous Copy Ninja who has mastered 1000 jutsu.",
		FlavorText = "In the ninja world, those who break the rules are scum, but those who abandon their friends are worse than scum.",
		Artist = "Studio Team"
	},
	
	-- Epic Cards (2.5% drop rate)
	{
		ID = "itachi_001",
		Name = "Itachi Uchiha",
		Title = "Prodigy of the Uchiha",
		Series = "Naruto",
		Rarity = "Epic",
		Type = "Mage",
		Stats = {
			Attack = 110,
			Defense = 85,
			Health = 100,
			Speed = 95,
			Energy = 6,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/itachi_akatsuki.png",
		BackgroundImage = "rbxasset://textures/backgrounds/genjutsu.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Epic,
			EffectType = "PurpleLightning",
			ImpactFrames = 6,
			ScreenShakeIntensity = GameConstants.ScreenShake.Heavy,
			ParticleCount = 50,
			SoundCategory = "Epic",
			SpecialIntro = false
		},
		SpecialAbility = "Tsukuyomi",
		AbilityDamage = 60,
		AbilityCooldown = 5,
		CollectionNumber = 5,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A legendary ninja who sacrificed everything for peace.",
		FlavorText = "Those who forgive themselves, and are able to accept their true nature... They are the strong ones.",
		Artist = "Studio Team"
	},
	
	-- Legendary Cards (0.5% drop rate)
	{
		ID = "naruto_002",
		Name = "Naruto Uzumaki",
		Title = "Seventh Hokage",
		Series = "Naruto",
		Rarity = "Legendary",
		Type = "Fighter",
		Stats = {
			Attack = 150,
			Defense = 120,
			Health = 180,
			Speed = 110,
			Energy = 8,
			Level = 1
		},
		Image = "rbxasset://textures/naruto/naruto_hokage.png",
		BackgroundImage = "rbxasset://textures/backgrounds/village_hidden_leaf.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Legendary,
			EffectType = "GoldenNova",
			ImpactFrames = 8,
			ScreenShakeIntensity = GameConstants.ScreenShake.Heavy,
			ParticleCount = 100,
			SoundCategory = "Legendary",
			SpecialIntro = false
		},
		SpecialAbility = "Rasengan Barrage",
		AbilityDamage = 80,
		AbilityCooldown = 6,
		CollectionNumber = 6,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "The Seventh Hokage who brought peace to the ninja world.",
		FlavorText = "I'm not gonna run away, I never go back on my word! That's my nindō: my ninja way!",
		Artist = "Studio Team"
	}
}

-- Dragon Ball Series
AnimeCharacters.DragonBall = {
	-- Common Cards
	{
		ID = "goku_001",
		Name = "Son Goku",
		Title = "Saiyan Warrior",
		Series = "Dragon Ball",
		Rarity = "Common",
		Type = "Fighter",
		Stats = {
			Attack = 50,
			Defense = 40,
			Health = 85,
			Speed = 60,
			Energy = 3,
			Level = 1
		},
		Image = "rbxasset://textures/dragonball/goku_base.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Common,
			EffectType = "BasicShine",
			ImpactFrames = 2,
			ScreenShakeIntensity = GameConstants.ScreenShake.Light,
			ParticleCount = 10,
			SoundCategory = "Common",
			SpecialIntro = false
		},
		SpecialAbility = "Kamehameha",
		AbilityDamage = 20,
		AbilityCooldown = 3,
		CollectionNumber = 1,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A pure-hearted Saiyan warrior.",
		FlavorText = "I am the hope of the universe!",
		Artist = "Studio Team"
	},
	
	-- Ultimate Card (0.01% drop rate)
	{
		ID = "goku_002",
		Name = "Son Goku",
		Title = "Ultra Instinct",
		Series = "Dragon Ball",
		Rarity = "Ultimate",
		Type = "Fighter",
		Stats = {
			Attack = 200,
			Defense = 150,
			Health = 250,
			Speed = 180,
			Energy = 10,
			Level = 1
		},
		Image = "rbxasset://textures/dragonball/goku_ultra_instinct.png",
		BackgroundImage = "rbxasset://textures/backgrounds/universe.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Ultimate,
			EffectType = "RainbowCosmos",
			ImpactFrames = 12,
			ScreenShakeIntensity = GameConstants.ScreenShake.Ultimate,
			ParticleCount = 200,
			SoundCategory = "Ultimate",
			SpecialIntro = true
		},
		SpecialAbility = "Ultra Instinct",
		AbilityDamage = 120,
		AbilityCooldown = 8,
		CollectionNumber = 2,
		ReleaseDate = "2024-01-01",
		IsLimited = true,
		Description = "The ultimate form achieved through perfect instinct.",
		FlavorText = "This is the power of Ultra Instinct!",
		Artist = "Studio Team"
	}
}

-- One Piece Series
AnimeCharacters.OnePiece = {
	-- Common Cards
	{
		ID = "luffy_001",
		Name = "Monkey D. Luffy",
		Title = "Straw Hat Captain",
		Series = "One Piece",
		Rarity = "Common",
		Type = "Fighter",
		Stats = {
			Attack = 48,
			Defense = 35,
			Health = 90,
			Speed = 65,
			Energy = 3,
			Level = 1
		},
		Image = "rbxasset://textures/onepiece/luffy_base.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Common,
			EffectType = "BasicShine",
			ImpactFrames = 2,
			ScreenShakeIntensity = GameConstants.ScreenShake.Light,
			ParticleCount = 10,
			SoundCategory = "Common",
			SpecialIntro = false
		},
		SpecialAbility = "Gum Gum Pistol",
		AbilityDamage = 18,
		AbilityCooldown = 2,
		CollectionNumber = 1,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A rubber man with dreams of becoming Pirate King.",
		FlavorText = "I'm gonna be King of the Pirates!",
		Artist = "Studio Team"
	},
	
	-- Legendary Cards
	{
		ID = "luffy_002",
		Name = "Monkey D. Luffy",
		Title = "Gear Fifth",
		Series = "One Piece",
		Rarity = "Legendary",
		Type = "Fighter",
		Stats = {
			Attack = 145,
			Defense = 110,
			Health = 200,
			Speed = 130,
			Energy = 8,
			Level = 1
		},
		Image = "rbxasset://textures/onepiece/luffy_gear5.png",
		BackgroundImage = "rbxasset://textures/backgrounds/liberation.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Legendary,
			EffectType = "GoldenNova",
			ImpactFrames = 8,
			ScreenShakeIntensity = GameConstants.ScreenShake.Heavy,
			ParticleCount = 100,
			SoundCategory = "Legendary",
			SpecialIntro = false
		},
		SpecialAbility = "Bajrang Gun",
		AbilityDamage = 90,
		AbilityCooldown = 7,
		CollectionNumber = 2,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "The awakened form of the legendary Sun God Nika.",
		FlavorText = "The most ridiculous power in the world!",
		Artist = "Studio Team"
	}
}

-- Attack on Titan Series
AnimeCharacters.AttackOnTitan = {
	-- Uncommon Cards
	{
		ID = "eren_001",
		Name = "Eren Yeager",
		Title = "Attack Titan",
		Series = "Attack on Titan",
		Rarity = "Uncommon",
		Type = "Tank",
		Stats = {
			Attack = 70,
			Defense = 60,
			Health = 120,
			Speed = 40,
			Energy = 5,
			Level = 1
		},
		Image = "rbxasset://textures/aot/eren_titan.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Uncommon,
			EffectType = "GreenAura",
			ImpactFrames = 3,
			ScreenShakeIntensity = GameConstants.ScreenShake.Medium,
			ParticleCount = 20,
			SoundCategory = "Uncommon",
			SpecialIntro = false
		},
		SpecialAbility = "Titan Transformation",
		AbilityDamage = 35,
		AbilityCooldown = 5,
		CollectionNumber = 1,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A young soldier who can transform into a Titan.",
		FlavorText = "I will destroy every last Titan!",
		Artist = "Studio Team"
	}
}

-- Demon Slayer Series  
AnimeCharacters.DemonSlayer = {
	-- Rare Cards
	{
		ID = "tanjiro_001",
		Name = "Tanjiro Kamado",
		Title = "Water Breathing",
		Series = "Demon Slayer",
		Rarity = "Rare",
		Type = "Fighter",
		Stats = {
			Attack = 80,
			Defense = 65,
			Health = 95,
			Speed = 85,
			Energy = 4,
			Level = 1
		},
		Image = "rbxasset://textures/demonslayer/tanjiro_water.png",
		BackgroundImage = "rbxasset://textures/backgrounds/water_waves.png",
		VisualEffects = {
			BorderColor = GameConstants.RarityColors.Rare,
			EffectType = "BlueFlames",
			ImpactFrames = 4,
			ScreenShakeIntensity = GameConstants.ScreenShake.Medium,
			ParticleCount = 30,
			SoundCategory = "Rare",
			SpecialIntro = false
		},
		SpecialAbility = "Water Breathing: Tenth Form",
		AbilityDamage = 45,
		AbilityCooldown = 4,
		CollectionNumber = 1,
		ReleaseDate = "2024-01-01",
		IsLimited = false,
		Description = "A kind-hearted demon slayer seeking to cure his sister.",
		FlavorText = "I will not let anyone else die!",
		Artist = "Studio Team"
	}
}

-- Get all characters as flat array
function AnimeCharacters:GetAllCharacters()
	local allCharacters = {}
	
	for seriesName, characters in pairs(self) do
		if type(characters) == "table" and seriesName ~= "GetAllCharacters" and seriesName ~= "GetCharactersByRarity" and seriesName ~= "GetCharactersBySeries" then
			for _, character in ipairs(characters) do
				table.insert(allCharacters, character)
			end
		end
	end
	
	return allCharacters
end

-- Get characters by rarity
function AnimeCharacters:GetCharactersByRarity(rarity: string)
	local characters = {}
	local allCharacters = self:GetAllCharacters()
	
	for _, character in ipairs(allCharacters) do
		if character.Rarity == rarity then
			table.insert(characters, character)
		end
	end
	
	return characters
end

-- Get characters by series
function AnimeCharacters:GetCharactersBySeries(series: string)
	local characters = {}
	local allCharacters = self:GetAllCharacters()
	
	for _, character in ipairs(allCharacters) do
		if character.Series == series then
			table.insert(characters, character)
		end
	end
	
	return characters
end

return AnimeCharacters