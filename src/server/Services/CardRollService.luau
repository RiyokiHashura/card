--!strict
-- CardRollService.luau
-- Advanced card roll system with psychological timing and smart pity mechanics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local RollTypes = require(ReplicatedStorage.Shared.Types.RollTypes)
local CardTypes = require(ReplicatedStorage.Shared.Types.CardTypes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local TableUtils = require(ReplicatedStorage.Shared.Utils.TableUtils)
local CardDatabase = require(ReplicatedStorage.Shared.Data.CardDatabase)

type RollRequest = RollTypes.RollRequest
type RollResult = RollTypes.RollResult
type CardRollResult = RollTypes.CardRollResult
type PityConfig = RollTypes.PityConfig
type PityCalculation = RollTypes.PityCalculation
type RollServiceResponse<T> = RollTypes.RollServiceResponse<T>

local CardRollService = {}
CardRollService.__index = CardRollService
setmetatable(CardRollService, {__index = BaseService})

-- Pity System Configuration (Research-based)
local PITY_CONFIGS = {
    Common = {
        SoftPityStart = 0,
        HardPityLimit = 0,
        SoftPityIncrease = 0,
        BaseRate = 0.7,
        MaxRate = 0.7,
        RarityName = "Common"
    },
    Uncommon = {
        SoftPityStart = 0,
        HardPityLimit = 0,
        SoftPityIncrease = 0,
        BaseRate = 0.20,
        MaxRate = 0.20,
        RarityName = "Uncommon"
    },
    Rare = {
        SoftPityStart = 0,
        HardPityLimit = 0,
        SoftPityIncrease = 0,
        BaseRate = 0.07,
        MaxRate = 0.07,
        RarityName = "Rare"
    },
    Epic = {
        SoftPityStart = 8,
        HardPityLimit = 15,
        SoftPityIncrease = 0.08,
        BaseRate = 0.04,
        MaxRate = 0.6,
        RarityName = "Epic"
    },
    Legendary = {
        SoftPityStart = 25,
        HardPityLimit = 50,
        SoftPityIncrease = 0.06,
        BaseRate = 0.006,
        MaxRate = 0.32,
        RarityName = "Legendary"
    },
    Mythical = {
        SoftPityStart = 60,
        HardPityLimit = 90,
        SoftPityIncrease = 0.04,
        BaseRate = 0.001,
        MaxRate = 0.5,
        RarityName = "Mythical"
    },
    Ultimate = {
        SoftPityStart = 80,
        HardPityLimit = 120,
        SoftPityIncrease = 0.03,
        BaseRate = 0.0001,
        MaxRate = 1.0,
        RarityName = "Ultimate"
    }
}

-- Psychological Timing Configuration
local TIMING_CONFIG = {
    OptimalRevealBase = 2000, -- 2 seconds optimal reveal time
    PsychologicalDelayMin = 500,
    PsychologicalDelayMax = 1500,
    RarityDelayMultiplier = {
        Common = 1.0,
        Rare = 1.2,
        Epic = 1.5,
        Legendary = 2.0,
        Mythical = 2.5,
        Ultimate = 3.0
    },
    AnticipationBuildupTime = 1000,
    SatisfactionHoldTime = 800
}

function CardRollService.new()
    	local self = BaseService.new("CardRollService", {"PlayerDataService"})
    setmetatable(self, CardRollService)
    
    -- Roll tracking
    self._activeRolls = {} :: {[string]: RollRequest}
    self._rollQueue = {} :: {RollTypes.RollQueueItem}
    self._rollStatistics = {} :: {[number]: RollTypes.RollStatistics}
    self._lastRollTimes = {} :: {[number]: number}
    
    -- Performance tracking
    self._rollsProcessed = 0
    self._averageProcessTime = 0
    self._concurrentRolls = 0
    
    -- Random seed for consistent but fair results
    self._randomSeed = os.time()
    
    return self
end

function CardRollService:Initialize()
    self:_log("CardRollService initializing...")
    
    -- Validate pity configurations
    for rarity, config in pairs(PITY_CONFIGS) do
        if config.SoftPityStart >= config.HardPityLimit and config.HardPityLimit > 0 then
            self:_logError("Invalid pity config for " .. rarity)
        end
    end
    
    -- Initialize roll processing
    self._rollProcessingConnection = RunService.Heartbeat:Connect(function()
        self:_processRollQueue()
    end)
    
    self:_log("CardRollService initialized successfully")
end

function CardRollService:Start()
    self:_log("CardRollService starting...")
    
    -- Set up remote events for client communication
    self:_setupRemoteEvents()
    
    -- Start roll analytics
    self:_startAnalytics()
    
    self:_log("CardRollService started successfully")
end

function CardRollService:Stop()
    self:_log("CardRollService stopping...")
    
    -- Process remaining rolls
    while #self._rollQueue > 0 do
        self:_processRollQueue()
        wait(0.1)
    end
    
    -- Clean up connections
    if self._rollProcessingConnection then
        self._rollProcessingConnection:Disconnect()
    end
    
    self:_log("CardRollService stopped")
end

-- Public Methods

function CardRollService:RollCards(request: RollRequest): RollServiceResponse<RollResult>
    local startTime = os.clock()
    local requestID = HttpService:GenerateGUID(false)
    
    -- Validate request
    local validation = self:_validateRollRequest(request)
    if not validation.IsValid then
        return {
            Success = false,
            ErrorMessage = validation.ErrorReason,
            ProcessingTime = (os.clock() - startTime) * 1000,
            RequestID = requestID
        }
    end
    
    -- Process the roll
    local rollResult = self:_processRoll(request, requestID)
    
    if rollResult.Success then
        -- Update player data
        self:_updatePlayerDataAfterRoll(request.Player, rollResult)
        
        -- Track statistics
        self:_updateRollStatistics(request.Player, rollResult)
    end
    
    return {
        Success = rollResult.Success,
        Data = rollResult,
        ErrorMessage = rollResult.ErrorMessage,
        ProcessingTime = (os.clock() - startTime) * 1000,
        RequestID = requestID
    }
end

function CardRollService:GetPityStatus(player: Player): RollTypes.PitySystemState
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local playerData = playerDataService:GetPlayerData(player)
    
    if not playerData then
        return {}
    end
    
    local pityState = {}
    
    for rarity, config in pairs(PITY_CONFIGS) do
        local pityField = rarity .. "Pity"
        local currentPity = playerData.PityData[pityField] or 0
        
        local calculation = self:_calculatePityRates(rarity, currentPity)
        pityState[rarity] = calculation
    end
    
    return pityState
end

function CardRollService:GetRollCost(rollType: RollTypes.RollType, count: number): RollTypes.RollCost
    local baseCost = 0
    local currency = "Coins"
    
    if rollType == "Daily" then
        baseCost = 0
        currency = "DailyRolls"
    elseif rollType == "Premium" then
        baseCost = GameConstants.Economy.PremiumRollCost
        currency = "Gems"
    elseif rollType == "Bonus" then
        baseCost = GameConstants.Economy.BonusRollCost
        currency = "Coins"
    end
    
    local totalCost = baseCost * count
    local discount = self:_calculateBulkDiscount(count)
    local finalCost = math.floor(totalCost * (1 - discount))
    
    return {
        Currency = currency,
        Amount = finalCost,
        OriginalAmount = totalCost,
        Discount = discount
    }
end

function CardRollService:SimulateRoll(player: Player, count: number): {string}
    -- Simulate rolls without actually giving cards (for UI preview)
    local results = {}
    
    for i = 1, count do
        local rarity = self:_rollRarity(player, true) -- simulate = true
        table.insert(results, rarity)
    end
    
    return results
end

function CardRollService:GetRollStatistics(player: Player): RollTypes.RollStatistics?
    local userID = player.UserId
    return self._rollStatistics[userID]
end

-- Private Methods

function CardRollService:_setupRemoteEvents()
    local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
    
    -- Handle card roll requests from client
    RemoteEventHandler:ConnectRemoteEvent("RequestCardRoll", function(player: Player, rollType: string?)
        self:_handleClientCardRoll(player, rollType or "Standard")
    end)
    
    -- Pre-create remote events for sending results back to client
    RemoteEventHandler:GetRemoteEvent("CardRollResult")
    RemoteEventHandler:GetRemoteEvent("CardRollError")
    
    self:_log("Remote events set up for card rolling")
end

function CardRollService:_handleClientCardRoll(player: Player, rollType: string)
    -- Create roll request
    local request: RollRequest = {
        Player = player,
        RollType = rollType,
        Count = 1, -- Single card roll for now
        Timestamp = os.time(),
        SessionID = tostring(player.UserId) .. "_" .. os.time()
    }
    
    -- Process the roll
    local result = self:RollCards(request)
    
    if result.Success and result.Data then
        -- Send result back to client
        local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
        RemoteEventHandler:FireClient(player, "CardRollResult", result.Data)
        
        self:_log("Card roll completed for player " .. player.Name .. ": " .. (result.Data.Cards[1] and result.Data.Cards[1].Card.Name or "Unknown"))
    else
        -- Send error back to client
        local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
        RemoteEventHandler:FireClient(player, "CardRollError", result.ErrorMessage or "Unknown error")
        
        self:_logError("Card roll failed for player " .. player.Name .. ": " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRollService:_validateRollRequest(request: RollRequest): RollTypes.RollValidation
	local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
	if not playerDataService then
		return {IsValid = false, ErrorReason = "PlayerDataService not found"}
	end

	local playerData = playerDataService:GetPlayerData(request.Player)
	if not playerData then
		return {IsValid = false, ErrorReason = "Player data not found"}
	end

	-- Get roll cost from constants
	local rollCost = GameConstants.Economy.RollCosts[request.RollType] or GameConstants.Economy.RollCosts.Standard
	if not rollCost then
		return {IsValid = false, ErrorReason = "Invalid roll type"}
	end
	
	-- Check if player has enough currency (using Gems now)
	if playerData.Gems < rollCost then
		return {IsValid = false, ErrorReason = "Not enough Gems"}
	end

	-- Rate limiting check
	if self:_isRateLimited(request.Player) then
		return {IsValid = false, ErrorReason = "Rate limit exceeded"}
	end
    
    return {
        IsValid = true,
        CanAfford = true,
        HasRollsRemaining = true,
        CooldownRemaining = 0
    }
end

function CardRollService:_isRateLimited(player: Player): boolean
	local playerID = player.UserId
	local currentTime = os.time()
	
	local lastRollTime = self._lastRollTimes[playerID]
	if lastRollTime and (currentTime - lastRollTime) < 1 then -- 1-second cooldown
		return true
	end
	
	self._lastRollTimes[playerID] = currentTime
	return false
end

function CardRollService:_processRoll(request: RollRequest, requestID: string): RollResult
    local startTime = os.clock()
    self._concurrentRolls += 1
    
    local results = {}
    local pityUsed = {}
    local totalCost = self:GetRollCost(request.RollType, request.Count)
    
    -- Generate cards
    for i = 1, request.Count do
        local cardResult = self:_generateCardRoll(request.Player, i, request.RollType)
        table.insert(results, cardResult)
        
        if cardResult.IsPityResult then
            table.insert(pityUsed, cardResult.Rarity)
        end
    end
    
    -- Calculate timing data
    local timingData = self:_calculateRollTiming(results)
    
    self._concurrentRolls -= 1
    self._rollsProcessed += 1
    
    return {
        Success = true,
        Cards = results,
        TotalCards = #results,
        PityUsed = pityUsed,
        GuaranteeUsed = #pityUsed > 0,
        RollCost = totalCost,
        TimingData = timingData
    }
end

function CardRollService:_generateCardRoll(player: Player, position: number, rollType: RollTypes.RollType): CardRollResult
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    	local cardDatabase = CardDatabase
    
    -- Roll for rarity
    local rarity, isPityResult = self:_rollRarity(player, false)
    
    -- Get random card of this rarity
    local card = cardDatabase:GetRandomCard(rarity)
    if not card then
    	self:_logError("No card found for rarity: " .. rarity .. ". Falling back to Common.")
    	card = cardDatabase:GetRandomCard("Common")
    end
    
    -- Check if player already has this card
    local playerData = playerDataService:GetPlayerData(player)
    local isNew = not playerData or not playerData.Cards or not playerData.Cards[card.ID]
    
    -- Get current pity count
    local pityCount = (playerData and playerData.Pity and playerData.Pity[rarity]) or 0
    
    -- Calculate animation delay (psychological timing)
    local baseDelay = TIMING_CONFIG.OptimalRevealBase
    local rarityMultiplier = TIMING_CONFIG.RarityDelayMultiplier[rarity] or 1.0
    local positionDelay = (position - 1) * 200 -- Stagger reveals
    local psychDelay = math.random(TIMING_CONFIG.PsychologicalDelayMin, TIMING_CONFIG.PsychologicalDelayMax)
    
    local animationDelay = baseDelay * rarityMultiplier + positionDelay + psychDelay
    
    -- Calculate effect intensity
    local effectIntensity = self:_calculateEffectIntensity(rarity, isNew, isPityResult)
    
    return {
        Card = card,
        Rarity = rarity,
        IsNew = isNew,
        IsPityResult = isPityResult,
        PityCount = pityCount,
        RollPosition = position,
        AnimationDelay = animationDelay,
        EffectIntensity = effectIntensity
    }
end

function CardRollService:_rollRarity(player: Player, simulate: boolean): (string, boolean)
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local playerData = playerDataService:GetPlayerData(player)
    
    if not playerData then
        return "Common", false
    end
    
    -- Check for guaranteed rarities first (hard pity)
    for rarity, config in pairs(PITY_CONFIGS) do
        if config.HardPityLimit > 0 then
            local currentPity = (playerData and playerData.Pity and playerData.Pity[rarity]) or 0
            
            if currentPity >= config.HardPityLimit then
                if not simulate then
                    playerDataService:UpdatePityData(player, rarity, true)
                end
                return rarity, true
            end
        end
    end
    
    -- Generate random number
    local random = math.random()
    local cumulativeRate = 0
    
    -- Check rarities in order of rarity (Ultimate -> Common)
    local rarityOrder = {"Ultimate", "Legendary", "Epic", "Rare", "Common"}
    
    for _, rarity in ipairs(rarityOrder) do
        local currentPity = (playerData and playerData.Pity and playerData.Pity[rarity]) or 0
        local pityCalc = self:_calculatePityRates(rarity, currentPity)
        cumulativeRate += pityCalc.CurrentRate
        
        if random <= cumulativeRate then
            if not simulate then
                playerDataService:UpdatePityData(player, rarity, true)
            end
            -- Check if this was a pity result
   			local config = PITY_CONFIGS[rarity]
    		local wasPity = currentPity >= config.SoftPityStart
            return rarity, wasPity
        end
    end
    
    -- Fallback to Common
    if not simulate then
    	playerDataService:UpdatePityData(player, "Common", false)
    end
    return "Common", false
end

function CardRollService:_calculatePityRates(rarity: string, currentPity: number): PityCalculation
    local config = PITY_CONFIGS[rarity]
    if not config then
        return {
            CurrentPity = currentPity,
            SoftPityActive = false,
            HardPityActive = false,
            CurrentRate = 0,
            BaseRate = 0,
            NextGuaranteeIn = 999
        }
    end
    
    local currentRate = config.BaseRate
    local softPityActive = currentPity >= config.SoftPityStart
    local hardPityActive = config.HardPityLimit > 0 and currentPity >= config.HardPityLimit
    
    -- Apply soft pity
    if softPityActive and not hardPityActive then
        local softPityStacks = currentPity - config.SoftPityStart
        local rateIncrease = softPityStacks * config.SoftPityIncrease
        currentRate = math.min(config.MaxRate, config.BaseRate + rateIncrease)
    end
    
    -- Hard pity guarantees the item
    if hardPityActive then
        currentRate = 1.0
    end
    
    local nextGuaranteeIn = config.HardPityLimit > 0 and (config.HardPityLimit - currentPity) or 999
    
    return {
        CurrentPity = currentPity,
        SoftPityActive = softPityActive,
        HardPityActive = hardPityActive,
        CurrentRate = currentRate,
        BaseRate = config.BaseRate,
        NextGuaranteeIn = nextGuaranteeIn
    }
end

function CardRollService:_wasPityUsed(rarity: string, pityCount: number): boolean
    local config = PITY_CONFIGS[rarity]
    if not config then
        return false
    end
    
    -- If hard pity was reached, it was definitely used
    if config.HardPityLimit > 0 and pityCount >= config.HardPityLimit then
        return true
    end
    
    -- If soft pity was active, there's a chance it was used
    if pityCount >= config.SoftPityStart then
        return true
    end
    
    return false
end

function CardRollService:_calculateRollTiming(results: {CardRollResult}): RollTypes.RollTimingData
    local currentTime = os.time()
    local totalDelay = 0
    
    for _, result in ipairs(results) do
        totalDelay += result.AnimationDelay
    end
    
    local averageDelay = totalDelay / #results
    local psychDelay = math.random(TIMING_CONFIG.PsychologicalDelayMin, TIMING_CONFIG.PsychologicalDelayMax)
    
    return {
        RequestTime = currentTime,
        ProcessTime = 50, -- Simulated process time
        ResponseTime = currentTime + averageDelay / 1000,
        OptimalRevealTime = TIMING_CONFIG.OptimalRevealBase,
        PsychologicalDelay = psychDelay
    }
end

function CardRollService:_calculateEffectIntensity(rarity: string, isNew: boolean, isPityResult: boolean): number
    local baseIntensity = GameConstants.RarityData[rarity] and GameConstants.RarityData[rarity].EffectIntensity or 0.5
    
    -- Boost intensity for new cards
    if isNew then
        baseIntensity += 0.2
    end
    
    -- Boost intensity for pity results
    if isPityResult then
        baseIntensity += 0.3
    end
    
    return math.min(1.0, baseIntensity)
end

function CardRollService:_calculateBulkDiscount(count: number): number
    if not GameConstants or not GameConstants.Economy or not GameConstants.Economy.BulkDiscounts then
        return 0
    end
    
    local bulkDiscounts = GameConstants.Economy.BulkDiscounts
    
    for i = #bulkDiscounts, 1, -1 do
        local discount = bulkDiscounts[i]
        if count >= discount.Quantity then
            return discount.DiscountPercent
        end
    end
    
    return 0
end

function CardRollService:_updatePlayerDataAfterRoll(player: Player, rollResult: RollResult)
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Add cards to collection
    for _, cardResult in ipairs(rollResult.Cards) do
        playerDataService:AddCardToCollection(player, cardResult.Card.ID)
    end
    
    -- Update economy
    local cost = rollResult.RollCost
    playerDataService:UpdatePlayerEconomy(player, cost.Currency, -cost.Amount)
    
    -- Update stats
    local stats = {
        TotalRolls = {Increment = rollResult.TotalCards}
    }
    
    if cost.Currency == "DailyRolls" then
        stats.DailyRollsUsed = {Increment = rollResult.TotalCards}
    end
    
    playerDataService:UpdatePlayerStats(player, stats)
    
    -- Pity is updated within the roll itself
    
    self:_log("Updated player data after roll for " .. player.Name)
end

function CardRollService:_updateRollStatistics(player: Player, rollResult: RollResult)
    local userID = player.UserId
    
    if not self._rollStatistics[userID] then
        self._rollStatistics[userID] = {
            TotalRolls = 0,
            RollsByRarity = {},
            AverageRollsPerRarity = {},
            PityUsageRate = 0,
            OptimalTimingHitRate = 0,
            PlayerEngagementScore = 0
        }
    end
    
    local stats = self._rollStatistics[userID]
    stats.TotalRolls += rollResult.TotalCards
    
    -- Track rarity distribution
    for _, cardResult in ipairs(rollResult.Cards) do
        local rarity = cardResult.Rarity
        stats.RollsByRarity[rarity] = (stats.RollsByRarity[rarity] or 0) + 1
    end
    
    -- Update pity usage rate
    local pityUsageCount = #rollResult.PityUsed
    if pityUsageCount > 0 then
        stats.PityUsageRate = (stats.PityUsageRate + pityUsageCount / rollResult.TotalCards) / 2
    end
    
    -- Calculate engagement score based on timing and results
    local engagementBonus = 0
    for _, cardResult in ipairs(rollResult.Cards) do
        if cardResult.IsNew then
            engagementBonus += 0.1
        end
        if cardResult.IsPityResult then
            engagementBonus += 0.2
        end
    end
    
    stats.PlayerEngagementScore = math.min(1.0, stats.PlayerEngagementScore + engagementBonus)
end

function CardRollService:_processRollQueue()
    -- Process roll queue for high-load scenarios
    if #self._rollQueue == 0 then
        return
    end
    
    -- Sort by priority
    table.sort(self._rollQueue, function(a, b)
        return a.Priority > b.Priority
    end)
    
    -- Process highest priority roll
    local queueItem = table.remove(self._rollQueue, 1)
    if queueItem then
        -- Process the roll
        spawn(function()
            self:RollCards(queueItem.Request)
        end)
    end
end

function CardRollService:_startAnalytics()
    -- Start analytics tracking
    spawn(function()
        while true do
            wait(300) -- Every 5 minutes
            
            -- Log performance metrics
            self:_log("Roll Statistics:")
            self:_log("  - Total Rolls Processed: " .. self._rollsProcessed)
            self:_log("  - Concurrent Rolls: " .. self._concurrentRolls)
            self:_log("  - Queue Size: " .. #self._rollQueue)
            
            -- Player statistics
            local totalPlayers = 0
            for _ in pairs(self._rollStatistics) do
                totalPlayers += 1
            end
            
            self:_log("  - Active Players: " .. totalPlayers)
        end
    end)
end

return CardRollService.new() 