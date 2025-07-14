--!strict
-- CardRollTestService.luau
-- Comprehensive test service for CardRollService functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local RollTypes = require(ReplicatedStorage.Shared.Types.RollTypes)

local CardRollTestService = {}
CardRollTestService.__index = CardRollTestService
setmetatable(CardRollTestService, {__index = BaseService})

function CardRollTestService.new()
    local self = BaseService.new("CardRollTestService", {"CardRollService", "PlayerDataService"})
    setmetatable(self, CardRollTestService)
    
    return self
end

function CardRollTestService:Initialize()
    self:_log("CardRollTestService initializing...")
end

function CardRollTestService:Start()
    self:_log("CardRollTestService starting...")
    
    --[[
    -- Wait for players to join for testing
    Players.PlayerAdded:Connect(function(player)
        wait(3) -- Wait for other services to initialize
        self:_testCardRollOperations(player)
    end)
    --]]
end

function CardRollTestService:_testCardRollOperations(player: Player)
    self:_log("🎲 Testing CardRollService operations for " .. player.Name)
    
    local cardRollService = self.ServiceRegistry:GetService("CardRollService")
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Test 1: Basic roll functionality
    self:_testBasicRoll(player, cardRollService)
    
    -- Test 2: Pity system
    self:_testPitySystem(player, cardRollService)
    
    -- Test 3: Roll cost calculation
    self:_testRollCosts(cardRollService)
    
    -- Test 4: Roll validation
    self:_testRollValidation(player, cardRollService)
    
    -- Test 5: Roll simulation
    self:_testRollSimulation(player, cardRollService)
    
    -- Test 6: Psychological timing
    self:_testPsychologicalTiming(player, cardRollService)
    
    -- Test 7: Batch rolling
    self:_testBatchRolling(player, cardRollService)
    
    -- Test 8: Statistics tracking
    self:_testStatisticsTracking(player, cardRollService)
    
    self:_log("🎯 CardRollService testing completed for " .. player.Name)
end

function CardRollTestService:_testBasicRoll(player: Player, cardRollService)
    self:_log("Testing basic roll functionality...")
    
    local rollRequest = {
        Player = player,
        RollType = "Daily",
        Count = 1,
        UseGuarantee = false
    }
    
    local result = cardRollService:RollCards(rollRequest)
    
    if result.Success and result.Data then
        self:_log("✅ Basic roll successful")
        self:_log("   - Cards received: " .. result.Data.TotalCards)
        self:_log("   - Processing time: " .. string.format("%.2f", result.ProcessingTime) .. "ms")
        
        if #result.Data.Cards > 0 then
            local firstCard = result.Data.Cards[1]
            self:_log("   - First card: " .. firstCard.Card.Name .. " (" .. firstCard.Rarity .. ")")
            self:_log("   - Animation delay: " .. firstCard.AnimationDelay .. "ms")
            self:_log("   - Effect intensity: " .. string.format("%.2f", firstCard.EffectIntensity))
        end
    else
        self:_logError("❌ Basic roll failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRollTestService:_testPitySystem(player: Player, cardRollService)
    self:_log("Testing pity system...")
    
    local pityStatus = cardRollService:GetPityStatus(player)
    
    if pityStatus then
        self:_log("✅ Pity system status retrieved")
        
        for rarity, calculation in pairs(pityStatus) do
            self:_log("   - " .. rarity .. " pity:")
            self:_log("     • Current pity: " .. calculation.CurrentPity)
            self:_log("     • Current rate: " .. string.format("%.4f", calculation.CurrentRate))
            self:_log("     • Soft pity active: " .. tostring(calculation.SoftPityActive))
            self:_log("     • Hard pity active: " .. tostring(calculation.HardPityActive))
            self:_log("     • Next guarantee in: " .. calculation.NextGuaranteeIn)
        end
    else
        self:_logError("❌ Failed to retrieve pity status")
    end
end

function CardRollTestService:_testRollCosts(cardRollService)
    self:_log("Testing roll cost calculation...")
    
    local testCases = {
        {rollType = "Daily", count = 1},
        {rollType = "Premium", count = 1},
        {rollType = "Premium", count = 5},
        {rollType = "Premium", count = 10}
    }
    
    for _, testCase in ipairs(testCases) do
        local cost = cardRollService:GetRollCost(testCase.rollType, testCase.count)
        
        self:_log("✅ " .. testCase.rollType .. " roll cost (x" .. testCase.count .. "):")
        self:_log("   - Currency: " .. cost.Currency)
        self:_log("   - Amount: " .. cost.Amount)
        self:_log("   - Original: " .. cost.OriginalAmount)
        
        if cost.Discount and cost.Discount > 0 then
            self:_log("   - Discount: " .. string.format("%.1f", cost.Discount * 100) .. "%")
        end
    end
end

function CardRollTestService:_testRollValidation(player: Player, cardRollService)
    self:_log("Testing roll validation...")
    
    -- Test valid request
    local validRequest = {
        Player = player,
        RollType = "Daily",
        Count = 1,
        UseGuarantee = false
    }
    
    local validResult = cardRollService:RollCards(validRequest)
    if validResult.Success then
        self:_log("✅ Valid roll request accepted")
    else
        self:_log("⚠️  Valid roll request rejected: " .. (validResult.ErrorMessage or "Unknown"))
    end
    
    -- Test invalid request (too many cards)
    local invalidRequest = {
        Player = player,
        RollType = "Premium",
        Count = 100,
        UseGuarantee = false
    }
    
    local invalidResult = cardRollService:RollCards(invalidRequest)
    if not invalidResult.Success then
        self:_log("✅ Invalid roll request properly rejected")
        self:_log("   - Reason: " .. (invalidResult.ErrorMessage or "Unknown"))
    else
        self:_log("⚠️  Invalid roll request was accepted (should be rejected)")
    end
end

function CardRollTestService:_testRollSimulation(player: Player, cardRollService)
    self:_log("Testing roll simulation...")
    
    local simulationResults = cardRollService:SimulateRoll(player, 10)
    
    if simulationResults then
        self:_log("✅ Roll simulation successful")
        self:_log("   - Simulated results: " .. table.concat(simulationResults, ", "))
        
        -- Count rarities
        local rarityCounts = {}
        for _, rarity in ipairs(simulationResults) do
            rarityCounts[rarity] = (rarityCounts[rarity] or 0) + 1
        end
        
        self:_log("   - Rarity distribution:")
        for rarity, count in pairs(rarityCounts) do
            self:_log("     • " .. rarity .. ": " .. count)
        end
    else
        self:_logError("❌ Roll simulation failed")
    end
end

function CardRollTestService:_testPsychologicalTiming(player: Player, cardRollService)
    self:_log("Testing psychological timing...")
    
    local rollRequest = {
        Player = player,
        RollType = "Daily",
        Count = 3,
        UseGuarantee = false
    }
    
    local result = cardRollService:RollCards(rollRequest)
    
    if result.Success and result.Data then
        self:_log("✅ Psychological timing test successful")
        self:_log("   - Timing data:")
        self:_log("     • Optimal reveal time: " .. result.Data.TimingData.OptimalRevealTime .. "ms")
        self:_log("     • Psychological delay: " .. result.Data.TimingData.PsychologicalDelay .. "ms")
        
        self:_log("   - Card reveal timings:")
        for i, card in ipairs(result.Data.Cards) do
            self:_log("     • Card " .. i .. ": " .. card.AnimationDelay .. "ms")
        end
        
        -- Verify timing is within expected ranges
        local firstCard = result.Data.Cards[1]
        if firstCard.AnimationDelay >= 2000 and firstCard.AnimationDelay <= 8000 then
            self:_log("     ✅ Timing within psychological range")
        else
            self:_log("     ⚠️  Timing outside expected range")
        end
    else
        self:_logError("❌ Psychological timing test failed")
    end
end

function CardRollTestService:_testBatchRolling(player: Player, cardRollService)
    self:_log("Testing batch rolling...")
    
    local batchRequest = {
        Player = player,
        RollType = "Daily",
        Count = 5,
        UseGuarantee = false
    }
    
    local startTime = os.clock()
    local result = cardRollService:RollCards(batchRequest)
    local endTime = os.clock()
    
    if result.Success and result.Data then
        self:_log("✅ Batch rolling successful")
        self:_log("   - Cards rolled: " .. result.Data.TotalCards)
        self:_log("   - Processing time: " .. string.format("%.2f", (endTime - startTime) * 1000) .. "ms")
        self:_log("   - Pity used: " .. (#result.Data.PityUsed > 0 and "Yes" or "No"))
        
        -- Check rarity distribution
        local rarityCount = {}
        for _, card in ipairs(result.Data.Cards) do
            rarityCount[card.Rarity] = (rarityCount[card.Rarity] or 0) + 1
        end
        
        self:_log("   - Rarity distribution:")
        for rarity, count in pairs(rarityCount) do
            self:_log("     • " .. rarity .. ": " .. count)
        end
    else
        self:_logError("❌ Batch rolling failed: " .. (result.ErrorMessage or "Unknown"))
    end
end

function CardRollTestService:_testStatisticsTracking(player: Player, cardRollService)
    self:_log("Testing statistics tracking...")
    
    local stats = cardRollService:GetRollStatistics(player)
    
    if stats then
        self:_log("✅ Statistics tracking active")
        self:_log("   - Total rolls: " .. stats.TotalRolls)
        self:_log("   - Pity usage rate: " .. string.format("%.2f", stats.PityUsageRate))
        self:_log("   - Engagement score: " .. string.format("%.2f", stats.PlayerEngagementScore))
        
        if stats.RollsByRarity then
            self:_log("   - Rolls by rarity:")
            for rarity, count in pairs(stats.RollsByRarity) do
                self:_log("     • " .. rarity .. ": " .. count)
            end
        end
    else
        self:_log("⚠️  No statistics available (player may not have rolled yet)")
    end
end

function CardRollTestService:TestPitySystemProgression()
    self:_log("Testing pity system progression...")
    
    local testPlayer = Players:GetPlayers()[1]
    if not testPlayer then
        self:_log("⚠️  No player to test pity progression")
        return
    end
    
    local cardRollService = self.ServiceRegistry:GetService("CardRollService")
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Artificially increase pity counters for testing
    local playerData = playerDataService:GetPlayerData(testPlayer)
    if playerData then
        -- Set legendary pity to near guarantee
        playerData.PityData.LegendaryPity = 45
        playerDataService:UpdatePityData(testPlayer, "Legendary", false)
        
        self:_log("📊 Testing with high pity count (45)...")
        
        -- Roll a few times to see pity in action
        for i = 1, 3 do
            local rollRequest = {
                Player = testPlayer,
                RollType = "Daily",
                Count = 1,
                UseGuarantee = false
            }
            
            local result = cardRollService:RollCards(rollRequest)
            if result.Success and result.Data then
                local card = result.Data.Cards[1]
                self:_log("   Roll " .. i .. ": " .. card.Card.Name .. " (" .. card.Rarity .. ")")
                
                if card.IsPityResult then
                    self:_log("   🎯 Pity system activated!")
                    break
                end
            end
        end
    end
end

function CardRollTestService:TestPerformanceMetrics()
    self:_log("Testing performance metrics...")
    
    local cardRollService = self.ServiceRegistry:GetService("CardRollService")
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        self:_log("⚠️  No player to test performance")
        return
    end
    
    local startTime = os.clock()
    local totalRolls = 0
    
    -- Perform multiple rolls to test performance
    for i = 1, 10 do
        local rollRequest = {
            Player = testPlayer,
            RollType = "Daily",
            Count = 1,
            UseGuarantee = false
        }
        
        local result = cardRollService:RollCards(rollRequest)
        if result.Success then
            totalRolls += 1
        end
    end
    
    local endTime = os.clock()
    local duration = endTime - startTime
    
    self:_log("📊 Performance Metrics:")
    self:_log("   - Total rolls: " .. totalRolls)
    self:_log("   - Duration: " .. string.format("%.3f", duration) .. "s")
    self:_log("   - Rolls per second: " .. string.format("%.1f", totalRolls / duration))
    
    -- Test memory usage
    local memoryBefore = collectgarbage("count")
    
    -- Simulate heavy roll load
    for i = 1, 50 do
        local result = cardRollService:SimulateRoll(testPlayer, 5)
    end
    
    local memoryAfter = collectgarbage("count")
    local memoryUsed = memoryAfter - memoryBefore
    
    self:_log("   - Memory usage for 250 simulated rolls: " .. string.format("%.2f", memoryUsed) .. "KB")
end

function CardRollTestService:TestErrorHandling()
    self:_log("Testing error handling...")
    
    local cardRollService = self.ServiceRegistry:GetService("CardRollService")
    
    -- Test with nil player
    local nilPlayerRequest = {
        Player = nil,
        RollType = "Daily",
        Count = 1,
        UseGuarantee = false
    }
    
    local nilResult = cardRollService:RollCards(nilPlayerRequest)
    if not nilResult.Success then
        self:_log("✅ Nil player request properly handled")
    else
        self:_log("⚠️  Nil player request should have failed")
    end
    
    -- Test with invalid roll type
    local testPlayer = Players:GetPlayers()[1]
    if testPlayer then
        local invalidTypeRequest = {
            Player = testPlayer,
            RollType = "InvalidType",
            Count = 1,
            UseGuarantee = false
        }
        
        local invalidResult = cardRollService:RollCards(invalidTypeRequest)
        if not invalidResult.Success then
            self:_log("✅ Invalid roll type properly handled")
        else
            self:_log("⚠️  Invalid roll type should have failed")
        end
    end
end

return CardRollTestService.new() 