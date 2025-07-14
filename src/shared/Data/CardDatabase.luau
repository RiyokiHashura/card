--!strict
-- CardDatabase.luau
-- Main interface for card database with validation and rarity management
-- Incorporates research-based drop rates and psychological timing

local GameConstants = require(script.Parent.Parent.Constants.GameConstants)
local CardTypes = require(script.Parent.Parent.Types.CardTypes)
local AnimeCharacters = require(script.Parent.AnimeCharacters)
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)

local CardDatabase = {}

-- Private card registry
local cardRegistry: {[string]: CardTypes.CardData} = {}
local rarityGroups: {[string]: {CardTypes.CardData}} = {}
local seriesGroups: {[string]: {CardTypes.CardData}} = {}
local typeGroups: {[string]: {CardTypes.CardData}} = {}

-- Initialize the database
local function initializeDatabase()
	-- Clear existing data
	table.clear(cardRegistry)
	table.clear(rarityGroups)
	table.clear(seriesGroups)
	table.clear(typeGroups)
	
	-- Load all characters
	local allCharacters = AnimeCharacters:GetAllCharacters()
	
	-- Register each card and organize by groups
	for _, cardData in ipairs(allCharacters) do
		-- Validate card data
		if CardDatabase:ValidateCardData(cardData) then
			-- Register card
			cardRegistry[cardData.ID] = cardData
			
			-- Group by rarity
			if not rarityGroups[cardData.Rarity] then
				rarityGroups[cardData.Rarity] = {}
			end
			table.insert(rarityGroups[cardData.Rarity], cardData)
			
			-- Group by series
			if not seriesGroups[cardData.Series] then
				seriesGroups[cardData.Series] = {}
			end
			table.insert(seriesGroups[cardData.Series], cardData)
			
			-- Group by type
			if not typeGroups[cardData.Type] then
				typeGroups[cardData.Type] = {}
			end
			table.insert(typeGroups[cardData.Type], cardData)
		else
			warn("Invalid card data for ID:", cardData.ID)
		end
	end
	
	print("📋 Card Database initialized with", TableUtils.getSize(cardRegistry), "cards")
	
	-- Print statistics
	for rarity, cards in pairs(rarityGroups) do
		print(string.format("   %s: %d cards", rarity, #cards))
	end
end

-- Card lookup functions
function CardDatabase:GetCard(cardID: string): CardTypes.CardData?
	return cardRegistry[cardID]
end

function CardDatabase:GetAllCards(): {[string]: CardTypes.CardData}
	return TableUtils.deepCopy(cardRegistry)
end

function CardDatabase:GetCardsByRarity(rarity: CardTypes.CardRarity): {CardTypes.CardData}
	return TableUtils.deepCopy(rarityGroups[rarity] or {})
end

function CardDatabase:GetCardsBySeries(series: CardTypes.CardSeries): {CardTypes.CardData}
	return TableUtils.deepCopy(seriesGroups[series] or {})
end

function CardDatabase:GetCardsByType(cardType: CardTypes.CardType): {CardTypes.CardData}
	return TableUtils.deepCopy(typeGroups[cardType] or {})
end

-- Random card selection with weighted probabilities
function CardDatabase:GetRandomCard(rarity: string): CardTypes.CardData?
	if not rarityGroups[rarity] then
		warn("No cards found for rarity: " .. rarity)
		
		-- Fallback to Common if the requested rarity has no cards
		if rarityGroups["Common"] and #rarityGroups["Common"] > 0 then
			local cardsOfRarity = rarityGroups["Common"]
			local randomIndex = math.random(1, #cardsOfRarity)
			return cardsOfRarity[randomIndex]
		end
		
		return nil
	end
	
	local cardsOfRarity = rarityGroups[rarity]
	if #cardsOfRarity == 0 then
		warn("No cards in rarity table: " .. rarity)
		return nil
	end
	
	local randomIndex = math.random(1, #cardsOfRarity)
	return cardsOfRarity[randomIndex]
end

-- Get multiple random cards (for packs)
function CardDatabase:GetRandomCards(count: number, rarityWeights: {[string]: number}?): {CardTypes.CardData}
	local cards = {}
	
	for i = 1, count do
		local card = self:GetRandomCard(rarityWeights)
		if card then
			table.insert(cards, card)
		end
	end
	
	return cards
end

-- Rarity calculation with pity system
function CardDatabase:CalculateRarityWeights(playerLevel: number, rollsSinceLastRare: number, rollsSinceLastEpic: number, rollsSinceLastLegendary: number): {[string]: number}
	local weights = TableUtils.deepCopy(GameConstants.Balance.BaseDropRates)
	
	-- Level-based improvements (research shows players expect progression)
	local levelBonus = math.min(playerLevel * 0.005, 0.1) -- Cap at 10% bonus
	weights.Rare = weights.Rare + levelBonus
	weights.Epic = weights.Epic + (levelBonus * 0.5)
	weights.Legendary = weights.Legendary + (levelBonus * 0.2)
	
	-- Pity system (based on research: prevent frustration, encourage continued play)
	-- Rare pity kicks in after 20 rolls
	if rollsSinceLastRare >= 20 then
		local rarePityBonus = math.min((rollsSinceLastRare - 20) * 0.02, 0.3) -- Up to 30% bonus
		weights.Rare = weights.Rare + rarePityBonus
		weights.Common = weights.Common - rarePityBonus -- Reduce common to compensate
	end
	
	-- Epic pity kicks in after 50 rolls  
	if rollsSinceLastEpic >= 50 then
		local epicPityBonus = math.min((rollsSinceLastEpic - 50) * 0.005, 0.1) -- Up to 10% bonus
		weights.Epic = weights.Epic + epicPityBonus
		weights.Common = weights.Common - epicPityBonus
	end
	
	-- Legendary pity (research shows 74-90 roll guarantee optimal)
	if rollsSinceLastLegendary >= 74 then
		local legendaryPityBonus = math.min((rollsSinceLastLegendary - 74) * 0.02, 0.32) -- Soft pity 32%
		weights.Legendary = weights.Legendary + legendaryPityBonus
		weights.Common = weights.Common - (legendaryPityBonus * 0.5)
		weights.Uncommon = weights.Uncommon - (legendaryPityBonus * 0.3)
		weights.Rare = weights.Rare - (legendaryPityBonus * 0.2)
	end
	
	-- Guaranteed legendary at 90 rolls (based on Genshin research)
	if rollsSinceLastLegendary >= 90 then
		weights.Legendary = 1.0
		weights.Common = 0
		weights.Uncommon = 0
		weights.Rare = 0
		weights.Epic = 0
		weights.Ultimate = 0
	end
	
	-- Ultimate rarity is extremely rare and not affected by pity
	-- Only available from special events or perfect luck
	
	-- Ensure weights don't go below 0
	for rarity, weight in pairs(weights) do
		weights[rarity] = math.max(weight, 0)
	end
	
	return weights
end

-- Card validation
function CardDatabase:ValidateCardData(cardData: CardTypes.CardData): boolean
	-- Check required fields
	if not cardData.ID or type(cardData.ID) ~= "string" or cardData.ID == "" then
		return false
	end
	
	if not cardData.Name or type(cardData.Name) ~= "string" or cardData.Name == "" then
		return false
	end
	
	-- Validate rarity
	if not self:IsValidRarity(cardData.Rarity) then
		return false
	end
	
	-- Validate series
	if not self:IsValidSeries(cardData.Series) then
		return false
	end
	
	-- Validate type
	if not self:IsValidType(cardData.Type) then
		return false
	end
	
	-- Validate stats
	if not self:ValidateStats(cardData.Stats) then
		return false
	end
	
	-- Validate visual effects
	if not self:ValidateVisualEffects(cardData.VisualEffects) then
		return false
	end
	
	return true
end

function CardDatabase:IsValidRarity(rarity: string): boolean
	return TableUtils.find(TableUtils.getValues(GameConstants.Rarity), function(validRarity)
		return validRarity == rarity
	end) ~= nil
end

function CardDatabase:IsValidSeries(series: string): boolean
	local validSeries = {"Naruto", "Dragon Ball", "One Piece", "Attack on Titan", "Demon Slayer", "Jujutsu Kaisen", "My Hero Academia", "Death Note", "Fullmetal Alchemist", "Hunter x Hunter"}
	return TableUtils.find(validSeries, function(validSeriesName)
		return validSeriesName == series
	end) ~= nil
end

function CardDatabase:IsValidType(cardType: string): boolean
	local validTypes = {"Fighter", "Mage", "Support", "Tank", "Assassin", "Healer"}
	return TableUtils.find(validTypes, function(validType)
		return validType == cardType
	end) ~= nil
end

function CardDatabase:ValidateStats(stats: CardTypes.CardStats): boolean
	-- Check all stats exist and are numbers
	local requiredStats = {"Attack", "Defense", "Health", "Speed", "Energy", "Level"}
	
	for _, statName in ipairs(requiredStats) do
		if not stats[statName] or type(stats[statName]) ~= "number" then
			return false
		end
	end
	
	-- Validate ranges (based on card balance research)
	if stats.Attack < 0 or stats.Attack > 250 then return false end
	if stats.Defense < 0 or stats.Defense > 200 then return false end
	if stats.Health < 0 or stats.Health > 300 then return false end
	if stats.Speed < 0 or stats.Speed > 200 then return false end
	if stats.Energy < 0 or stats.Energy > 15 then return false end
	if stats.Level < 1 or stats.Level > 100 then return false end
	
	return true
end

function CardDatabase:ValidateVisualEffects(effects: CardTypes.CardVisualEffects): boolean
	-- Check all required fields exist
	if not effects.BorderColor or typeof(effects.BorderColor) ~= "Color3" then
		return false
	end
	
	if not effects.EffectType or type(effects.EffectType) ~= "string" then
		return false
	end
	
	if not effects.ImpactFrames or type(effects.ImpactFrames) ~= "number" or effects.ImpactFrames < 1 then
		return false
	end
	
	if not effects.ScreenShakeIntensity or type(effects.ScreenShakeIntensity) ~= "number" or effects.ScreenShakeIntensity < 0 then
		return false
	end
	
	if not effects.ParticleCount or type(effects.ParticleCount) ~= "number" or effects.ParticleCount < 0 then
		return false
	end
	
	if not effects.SoundCategory or type(effects.SoundCategory) ~= "string" then
		return false
	end
	
	return true
end

-- Card rarity information
function CardDatabase:GetRarityInfo(): {[string]: {count: number, percentage: number}}
	local info = {}
	local totalCards = TableUtils.getSize(cardRegistry)
	
	for rarity, cards in pairs(rarityGroups) do
		info[rarity] = {
			count = #cards,
			percentage = totalCards > 0 and (#cards / totalCards * 100) or 0
		}
	end
	
	return info
end

-- Series information
function CardDatabase:GetSeriesInfo(): {[string]: {count: number, percentage: number}}
	local info = {}
	local totalCards = TableUtils.getSize(cardRegistry)
	
	for series, cards in pairs(seriesGroups) do
		info[series] = {
			count = #cards,
			percentage = totalCards > 0 and (#cards / totalCards * 100) or 0
		}
	end
	
	return info
end

-- Card search functionality
function CardDatabase:SearchCards(query: string): {CardTypes.CardData}
	local results = {}
	local lowerQuery = string.lower(query)
	
	for _, card in pairs(cardRegistry) do
		-- Search in name, title, description, and flavor text
		local searchFields = {
			string.lower(card.Name),
			string.lower(card.Title or ""),
			string.lower(card.Description),
			string.lower(card.FlavorText or ""),
			string.lower(card.Series),
			string.lower(card.Type),
			string.lower(card.Rarity)
		}
		
		for _, field in ipairs(searchFields) do
			if string.find(field, lowerQuery) then
				table.insert(results, card)
				break
			end
		end
	end
	
	return results
end

-- Card collection statistics
function CardDatabase:GetCollectionStats(): {totalCards: number, byRarity: {[string]: number}, bySeries: {[string]: number}}
	return {
		totalCards = TableUtils.getSize(cardRegistry),
		byRarity = TableUtils.map(TableUtils.getKeys(rarityGroups), function(rarity)
			return #rarityGroups[rarity]
		end),
		bySeries = TableUtils.map(TableUtils.getKeys(seriesGroups), function(series)
			return #seriesGroups[series]
		end)
	}
end

-- Initialize database on module load
initializeDatabase()

-- Export
return CardDatabase 