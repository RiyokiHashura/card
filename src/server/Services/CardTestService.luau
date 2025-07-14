--!strict
-- CardTestService.luau
-- Temporary service to test card database functionality
-- Displays card statistics and validates the system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local CardDatabase = require(ReplicatedStorage.Shared.Data.CardDatabase)

local CardTestService = {}
CardTestService.__index = CardTestService
setmetatable(CardTestService, {__index = BaseService})

function CardTestService.new()
	local self = BaseService.new("CardTestService", {})
	setmetatable(self, CardTestService)
	return self
end

function CardTestService:Initialize()
	self:_log("CardTestService initializing...")
	
	-- Test basic card lookup
	self:TestCardLookup()
	
	-- Test rarity distribution
	self:TestRarityDistribution()
	
	-- Test random card selection
	self:TestRandomCardSelection()
	
	-- Test pity system
	self:TestPitySystem()
	
	-- Display database statistics
	self:DisplayDatabaseStats()
end

function CardTestService:Start()
	self:_log("CardTestService started successfully!")
end

function CardTestService:TestCardLookup()
	self:_log("🔍 Testing card lookup...")
	
	-- Test getting specific cards
	local naruto = CardDatabase:GetCard("naruto_001")
	if naruto then
		self:_log("✅ Found Naruto card:", naruto.Name .. " (" .. naruto.Rarity .. ")")
	else
		self:_warn("❌ Failed to find Naruto card")
	end
	
	local goku = CardDatabase:GetCard("goku_002")
	if goku then
		self:_log("✅ Found Ultra Instinct Goku:", goku.Name .. " (" .. goku.Rarity .. ")")
	else
		self:_warn("❌ Failed to find Ultra Instinct Goku card")
	end
	
	-- Test invalid card
	local invalid = CardDatabase:GetCard("invalid_card")
	if not invalid then
		self:_log("✅ Correctly returned nil for invalid card")
	else
		self:_warn("❌ Should have returned nil for invalid card")
	end
end

function CardTestService:TestRarityDistribution()
	self:_log("🎲 Testing rarity distribution...")
	
	-- Get cards by rarity
	local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Ultimate"}
	
	for _, rarity in ipairs(rarities) do
		local cards = CardDatabase:GetCardsByRarity(rarity)
		self:_log(string.format("   %s cards: %d", rarity, #cards))
		
		-- Show some examples
		if #cards > 0 then
			for i = 1, math.min(3, #cards) do
				local card = cards[i]
				self:_log(string.format("     - %s (%s)", card.Name, card.Series))
			end
		end
	end
end

function CardTestService:TestRandomCardSelection()
	self:_log("🎰 Testing random card selection...")
	
	-- Test with default rates
	local testRolls = 100
	local results = {}
	
	for i = 1, testRolls do
		-- Get a random rarity based on drop rates first
		local randomRarity = self:_getRandomRarity()
		local card = CardDatabase:GetRandomCard(randomRarity)
		
		if card then
			if not results[card.Rarity] then
				results[card.Rarity] = 0
			end
			results[card.Rarity] = results[card.Rarity] + 1
		end
	end
	
	self:_log(string.format("Results from %d random rolls:", testRolls))
	for rarity, count in pairs(results) do
		local percentage = (count / testRolls) * 100
		local expectedPercentage = GameConstants.Balance.BaseDropRates[rarity] * 100
		self:_log(string.format("   %s: %d (%.1f%%) - Expected: %.1f%%", 
			rarity, count, percentage, expectedPercentage))
	end
end

function CardTestService:_getRandomRarity(): string
	local random = math.random()
	local cumulative = 0
	for rarity, rate in pairs(GameConstants.Balance.BaseDropRates) do
		cumulative = cumulative + rate
		if random <= cumulative then
			return rarity
		end
	end
	return "Common" -- Fallback
end

function CardTestService:TestPitySystem()
	self:_log("🎯 Testing pity system...")
	
	-- Test pity calculations
	local testCases = {
		{level = 1, rare = 0, epic = 0, legendary = 0},
		{level = 10, rare = 25, epic = 10, legendary = 20},
		{level = 20, rare = 50, epic = 60, legendary = 80},
		{level = 50, rare = 30, epic = 80, legendary = 90}
	}
	
	for _, testCase in ipairs(testCases) do
		local weights = CardDatabase:CalculateRarityWeights(
			testCase.level, testCase.rare, testCase.epic, testCase.legendary
		)
		
		self:_log(string.format("Level %d, Rolls since last (R:%d, E:%d, L:%d):", 
			testCase.level, testCase.rare, testCase.epic, testCase.legendary))
		
		for rarity, weight in pairs(weights) do
			self:_log(string.format("   %s: %.4f", rarity, weight))
		end
	end
end

function CardTestService:DisplayDatabaseStats()
	self:_log("📊 Card Database Statistics:")
	
	-- Overall stats
	local stats = CardDatabase:GetCollectionStats()
	self:_log(string.format("Total cards: %d", stats.totalCards))
	
	-- Rarity info
	local rarityInfo = CardDatabase:GetRarityInfo()
	self:_log("Rarity distribution:")
	for rarity, info in pairs(rarityInfo) do
		self:_log(string.format("   %s: %d cards (%.1f%%)", 
			rarity, info.count, info.percentage))
	end
	
	-- Series info
	local seriesInfo = CardDatabase:GetSeriesInfo()
	self:_log("Series distribution:")
	for series, info in pairs(seriesInfo) do
		self:_log(string.format("   %s: %d cards (%.1f%%)", 
			series, info.count, info.percentage))
	end
	
	-- Test search functionality
	local searchResults = CardDatabase:SearchCards("naruto")
	self:_log(string.format("Search results for 'naruto': %d cards", #searchResults))
	
	local gokuResults = CardDatabase:SearchCards("goku")
	self:_log(string.format("Search results for 'goku': %d cards", #gokuResults))
end

-- Test individual card validation
function CardTestService:TestCardValidation()
	self:_log("🔧 Testing card validation...")
	
	-- Get a valid card and test it
	local validCard = CardDatabase:GetCard("naruto_001")
	if validCard then
		local isValid = CardDatabase:ValidateCardData(validCard)
		if isValid then
			self:_log("✅ Valid card passed validation")
		else
			self:_warn("❌ Valid card failed validation")
		end
	end
	
	-- Test invalid card data
	local invalidCard = {
		ID = "", -- Invalid empty ID
		Name = "Test Card",
		Rarity = "InvalidRarity",
		Stats = {Attack = -10} -- Invalid negative attack
	}
	
	local isInvalid = CardDatabase:ValidateCardData(invalidCard)
	if not isInvalid then
		self:_log("✅ Invalid card correctly rejected")
	else
		self:_warn("❌ Invalid card incorrectly accepted")
	end
end

return CardTestService.new() 