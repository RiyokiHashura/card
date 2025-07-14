--!strict
-- PlayerDataTestService.luau
-- Test service for PlayerDataService functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local PlayerDataTestService = {}
PlayerDataTestService.__index = PlayerDataTestService
setmetatable(PlayerDataTestService, {__index = BaseService})

function PlayerDataTestService.new()
    local self = BaseService.new("PlayerDataTestService", {"PlayerDataService"})
    setmetatable(self, PlayerDataTestService)
    
    return self
end

function PlayerDataTestService:Initialize()
    self:_log("PlayerDataTestService initializing...")
end

function PlayerDataTestService:Start()
    self:_log("PlayerDataTestService starting...")
    
    --[[
    -- Wait for players to join for testing
    Players.PlayerAdded:Connect(function(player)
        wait(2) -- Wait for PlayerDataService to load the player
        self:_testPlayerDataOperations(player)
    end)
    --]]
end

function PlayerDataTestService:_testPlayerDataOperations(player: Player)
    self:_log("Testing PlayerDataService operations for " .. player.Name)
    
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Test 1: Get player data
    local playerData = playerDataService:GetPlayerData(player)
    if playerData then
        self:_log("✅ Successfully retrieved player data for " .. player.Name)
        self:_log("   - Level: " .. playerData.Stats.Level)
        self:_log("   - Coins: " .. playerData.Economy.Coins)
        self:_log("   - Gems: " .. playerData.Economy.Gems)
    else
        self:_logError("❌ Failed to retrieve player data for " .. player.Name)
        return
    end
    
    -- Test 2: Update player stats
    local success = playerDataService:UpdatePlayerStats(player, {
        BattlesWon = 5,
        BattlesLost = 2,
        TotalDamageDealt = 1500
    })
    if success then
        self:_log("✅ Successfully updated player stats")
        local updatedData = playerDataService:GetPlayerData(player)
        self:_log("   - Win Rate: " .. string.format("%.2f", updatedData.Stats.WinRate))
    else
        self:_logError("❌ Failed to update player stats")
    end
    
    -- Test 3: Add experience
    local initialLevel = playerData.Stats.Level
    local expSuccess = playerDataService:AddExperience(player, 250)
    if expSuccess then
        self:_log("✅ Successfully added experience")
        local updatedData = playerDataService:GetPlayerData(player)
        self:_log("   - New Level: " .. updatedData.Stats.Level)
        self:_log("   - Experience: " .. updatedData.Stats.Experience .. "/" .. updatedData.Stats.ExperienceToNext)
        
        if updatedData.Stats.Level > initialLevel then
            self:_log("   - 🎉 Level up detected! New level: " .. updatedData.Stats.Level)
        end
    else
        self:_logError("❌ Failed to add experience")
    end
    
    -- Test 4: Update economy
    local economySuccess = playerDataService:UpdatePlayerEconomy(player, "Coins", 500)
    if economySuccess then
        self:_log("✅ Successfully updated economy")
        local updatedData = playerDataService:GetPlayerData(player)
        self:_log("   - New Coins: " .. updatedData.Economy.Coins)
    else
        self:_logError("❌ Failed to update economy")
    end
    
    -- Test 5: Add card to collection
    local cardSuccess = playerDataService:AddCardToCollection(player, "naruto_001")
    if cardSuccess then
        self:_log("✅ Successfully added card to collection")
        local updatedData = playerDataService:GetPlayerData(player)
        self:_log("   - Total Cards: " .. updatedData.Collection.TotalCardsOwned)
        self:_log("   - Unique Cards: " .. updatedData.Collection.UniqueCardsOwned)
    else
        self:_logError("❌ Failed to add card to collection")
    end
    
    -- Test 6: Update pity data
    local pitySuccess = playerDataService:UpdatePityData(player, "Legendary", false)
    if pitySuccess then
        self:_log("✅ Successfully updated pity data")
        local updatedData = playerDataService:GetPlayerData(player)
        self:_log("   - Legendary Pity: " .. updatedData.PityData.LegendaryPity)
    else
        self:_logError("❌ Failed to update pity data")
    end
    
    -- Test 7: Get player session
    local session = playerDataService:GetPlayerSession(player)
    if session then
        self:_log("✅ Successfully retrieved player session")
        self:_log("   - Session Start: " .. os.date("%H:%M:%S", session.SessionStartTime))
        self:_log("   - Current Location: " .. session.CurrentLocation)
    else
        self:_logError("❌ Failed to retrieve player session")
    end
    
    -- Test 8: Save player data
    local saveResult = playerDataService:SavePlayerData(player)
    if saveResult.Success then
        self:_log("✅ Successfully saved player data")
        self:_log("   - Save Time: " .. os.date("%H:%M:%S", saveResult.SaveTime))
    else
        self:_logError("❌ Failed to save player data: " .. (saveResult.ErrorMessage or "Unknown error"))
    end
    
    -- Test performance data
    self:_log("📊 Performance Metrics:")
    self:_log("   - Load Operations: " .. (playerDataService._loadOperations or 0))
    self:_log("   - Save Operations: " .. (playerDataService._saveOperations or 0))
    
    self:_log("🎯 PlayerDataService testing completed for " .. player.Name)
end

function PlayerDataTestService:TestBatchOperations()
    self:_log("Testing batch operations on PlayerDataService...")
    
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Test with multiple players
    local players = Players:GetPlayers()
    if #players == 0 then
        self:_log("⚠️  No players to test batch operations")
        return
    end
    
    local startTime = os.clock()
    
    for _, player in pairs(players) do
        -- Simulate typical player operations
        playerDataService:UpdatePlayerStats(player, {
            TotalRolls = math.random(1, 100),
            BattlesWon = math.random(1, 50),
            BattlesLost = math.random(1, 30)
        })
        
        playerDataService:AddExperience(player, math.random(50, 200))
        playerDataService:UpdatePlayerEconomy(player, "Coins", math.random(100, 500))
        
        -- Add some random cards
        for i = 1, math.random(1, 5) do
            local cardID = "test_card_" .. tostring(math.random(1, 100))
            playerDataService:AddCardToCollection(player, cardID)
        end
    end
    
    local endTime = os.clock()
    local duration = endTime - startTime
    
    self:_log("✅ Batch operations completed")
    self:_log("   - Players processed: " .. #players)
    self:_log("   - Duration: " .. string.format("%.3f", duration) .. "s")
    self:_log("   - Operations per second: " .. string.format("%.1f", (#players * 4) / duration))
end

function PlayerDataTestService:TestDataValidation()
    self:_log("Testing data validation...")
    
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        self:_log("⚠️  No player to test data validation")
        return
    end
    
    -- Test invalid operations
    local invalidStats = playerDataService:UpdatePlayerStats(testPlayer, {
        InvalidField = "test",
        Level = "not_a_number"
    })
    
    local invalidEconomy = playerDataService:UpdatePlayerEconomy(testPlayer, "InvalidCurrency", 100)
    
    self:_log("✅ Data validation test completed")
    self:_log("   - Invalid stats update handled: " .. tostring(not invalidStats))
    self:_log("   - Invalid economy update handled: " .. tostring(not invalidEconomy))
end

function PlayerDataTestService:TestMemoryUsage()
    self:_log("Testing memory usage...")
    
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Get cache size
    local cacheSize = 0
    for _ in pairs(playerDataService._playerDataCache) do
        cacheSize += 1
    end
    
    local sessionSize = 0
    for _ in pairs(playerDataService._playerSessions) do
        sessionSize += 1
    end
    
    self:_log("📊 Memory Usage:")
    self:_log("   - Cached player data: " .. cacheSize)
    self:_log("   - Active sessions: " .. sessionSize)
    self:_log("   - Save queue size: " .. self:_getTableSize(playerDataService._saveQueue))
end

function PlayerDataTestService:_getTableSize(t: table): number
    local count = 0
    for _ in pairs(t) do
        count += 1
    end
    return count
end

return PlayerDataTestService.new() 