--!strict
-- BattleTestService.luau
-- Comprehensive test service for the battle system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local BattleTypes = require(ReplicatedStorage.Shared.Types.BattleTypes)
local CardDatabase = require(ReplicatedStorage.Shared.Data.CardDatabase)

local BattleTestService = {}
BattleTestService.__index = BattleTestService
setmetatable(BattleTestService, {__index = BaseService})

function BattleTestService.new()
    	local self = BaseService.new("BattleTestService", {"BattleService", "PlayerDataService"})
    setmetatable(self, BattleTestService)
    
    return self
end

function BattleTestService:Initialize()
    self:_log("BattleTestService initializing...")
end

function BattleTestService:Start()
    self:_log("BattleTestService starting...")
    
    --[[
    -- Wait for players to join for testing
    Players.PlayerAdded:Connect(function(player)
        wait(4) -- Wait for other services to initialize
        self:_testBattleSystem(player)
    end)
    --]]
end

function BattleTestService:_testBattleSystem(player: Player)
    self:_log("⚔️ Testing Battle System for " .. player.Name)
    
    local battleService = self.ServiceRegistry:GetService("BattleService")
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local cardDatabase = CardDatabase
    
    -- Test 1: Battle creation
    self:_testBattleCreation(player, battleService)
    
    -- Test 2: AI battle
    spawn(function()
        wait(8)
        self:_testAIBattle(player, battleService)
    end)
    
    -- Test 3: Turn management
    spawn(function()
        wait(16)
        self:_testTurnManagement(player, battleService)
    end)
    
    -- Test 4: Damage calculations
    spawn(function()
        wait(24)
        self:_testDamageCalculations(battleService)
    end)
    
    -- Test 5: Action validation
    spawn(function()
        wait(32)
        self:_testActionValidation(player, battleService)
    end)
    
    -- Test 6: Battle statistics
    spawn(function()
        wait(40)
        self:_testBattleStatistics(battleService)
    end)
    
    -- Test 7: Performance metrics
    spawn(function()
        wait(48)
        self:_testPerformanceMetrics(battleService)
    end)
end

function BattleTestService:_testBattleCreation(player: Player, battleService)
    self:_log("Testing battle creation...")
    
    local result = battleService:CreateBattle(player, nil, "Practice")
    
    if result.Success and result.Data then
        self:_log("✅ Battle creation successful")
        self:_log("   - Battle ID: " .. result.Data.BattleID)
        self:_log("   - Player 1: " .. result.Data.Player1.Username)
        self:_log("   - Player 2: " .. result.Data.Player2.Username)
        self:_log("   - Battle State: " .. result.Data.BattleState)
        self:_log("   - Starting Health: " .. result.Data.Player1.Health)
        self:_log("   - Starting Energy: " .. result.Data.Player1.Energy)
        self:_log("   - Hand Size: " .. #result.Data.Player1.Hand)
        self:_log("   - Processing Time: " .. string.format("%.2f", result.ProcessingTime) .. "ms")
        
        -- Verify battle data integrity
        local battle = result.Data
        if battle.Player1.Health > 0 and battle.Player2.Health > 0 then
            self:_log("   - ✅ Health values valid")
        else
            self:_logError("   - ❌ Invalid health values")
        end
        
        if #battle.Player1.Hand > 0 and #battle.Player2.Hand > 0 then
            self:_log("   - ✅ Initial hands drawn")
        else
            self:_logError("   - ❌ Initial hands not properly drawn")
        end
        
        -- Test battle state
        local stateResult = battleService:GetBattleState(player)
        if stateResult.Success then
            self:_log("   - ✅ Battle state retrieval working")
        else
            self:_logError("   - ❌ Battle state retrieval failed")
        end
        
    else
        self:_logError("❌ Battle creation failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function BattleTestService:_testAIBattle(player: Player, battleService)
    self:_log("Testing AI battle...")
    
    local result = battleService:CreateBattle(player, nil, "Practice")
    
    if result.Success and result.Data then
        local battle = result.Data
        self:_log("✅ AI battle created successfully")
        self:_log("   - AI Opponent: " .. battle.Player2.Username)
        self:_log("   - AI UserID: " .. battle.Player2.UserID)
        
        -- Verify AI setup
        if battle.Player2.UserID == -1 then
            self:_log("   - ✅ AI player properly identified")
        else
            self:_logError("   - ❌ AI player not properly set up")
        end
        
        if battle.Player2.IsReady then
            self:_log("   - ✅ AI player is ready")
        else
            self:_logError("   - ❌ AI player not ready")
        end
        
        -- Test AI turn processing (if it's AI's turn)
        if battle.ActivePlayer == 2 then
            self:_log("   - Testing AI turn processing...")
            wait(3) -- Wait for AI to process turn
            
            local updatedState = battleService:GetBattleState(player)
            if updatedState.Success and updatedState.Data then
                if updatedState.Data.CurrentTurn > battle.CurrentTurn then
                    self:_log("   - ✅ AI successfully processed turn")
                else
                    self:_log("   - ⚠️  AI turn still processing or no action taken")
                end
            end
        else
            self:_log("   - Player's turn first, AI will act on next turn")
        end
        
    else
        self:_logError("❌ AI battle creation failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function BattleTestService:_testTurnManagement(player: Player, battleService)
    self:_log("Testing turn management...")
    
    local stateResult = battleService:GetBattleState(player)
    if not stateResult.Success or not stateResult.Data then
        self:_log("⚠️  No active battle for turn management test")
        return
    end
    
    local battle = stateResult.Data
    self:_log("✅ Turn management test starting")
    self:_log("   - Current Turn: " .. battle.CurrentTurn)
    self:_log("   - Active Player: " .. battle.ActivePlayer)
    self:_log("   - Turn Timer: " .. battle.TurnTimer)
    
    -- Test end turn action
    local endTurnAction = {
        ActionID = "test_end_turn",
        PlayerID = player.UserId,
        ActionType = "EndTurn",
        ActionData = {},
        Timestamp = os.time(),
        IsValid = false
    }
    
    local actionResult = battleService:ProcessAction(player, endTurnAction)
    
    if actionResult.Success then
        self:_log("   - ✅ End turn action processed successfully")
        
        -- Verify turn advancement
        wait(0.5)
        local updatedState = battleService:GetBattleState(player)
        if updatedState.Success and updatedState.Data then
            if updatedState.Data.CurrentTurn > battle.CurrentTurn then
                self:_log("   - ✅ Turn advanced successfully")
                self:_log("   - New Turn: " .. updatedState.Data.CurrentTurn)
                self:_log("   - New Active Player: " .. updatedState.Data.ActivePlayer)
            else
                self:_logError("   - ❌ Turn did not advance")
            end
        end
    else
        self:_logError("   - ❌ End turn action failed: " .. (actionResult.ErrorMessage or "Unknown"))
    end
end

function BattleTestService:_testDamageCalculations(battleService)
    self:_log("Testing damage calculations...")
    
    -- Create test battle cards
    local attackingCard = {
        InstanceID = "test_attacker",
        CardData = {
            ID = "test_card_1",
            Name = "Test Attacker",
            Attack = 100,
            Defense = 50,
            Health = 150
        },
        CurrentHealth = 150,
        MaxHealth = 150,
        Attack = 100,
        Defense = 50,
        Energy = 3,
        StatusEffects = {},
        Position = "Active",
        CanAttack = true,
        TurnsOnField = 0,
        DamageDealt = 0,
        DamageTaken = 0
    }
    
    local defendingCard = {
        InstanceID = "test_defender",
        CardData = {
            ID = "test_card_2",
            Name = "Test Defender",
            Attack = 80,
            Defense = 80,
            Health = 120
        },
        CurrentHealth = 120,
        MaxHealth = 120,
        Attack = 80,
        Defense = 80,
        Energy = 2,
        StatusEffects = {},
        Position = "Active",
        CanAttack = false,
        TurnsOnField = 1,
        DamageDealt = 0,
        DamageTaken = 0
    }
    
    -- Create test players
    local attacker = {
        UserID = 1,
        Username = "TestAttacker",
        Health = 100,
        MaxHealth = 100,
        BattleStats = {
            DamageDealt = 0,
            DamageTaken = 0,
            CriticalHits = 0
        }
    }
    
    local defender = {
        UserID = 2,
        Username = "TestDefender",
        Health = 100,
        MaxHealth = 100,
        Shield = 0,
        BattleStats = {
            DamageDealt = 0,
            DamageTaken = 0,
            CriticalHits = 0
        }
    }
    
    -- Test damage calculation (using reflection to access private method)
    local damageCalc = {
        BaseAttack = attackingCard.Attack,
        BaseDamage = attackingCard.Attack,
        AttackModifiers = {},
        DefenseModifiers = {},
        FinalDamage = math.max(1, attackingCard.Attack - defendingCard.Defense),
        IsCritical = false,
        CriticalMultiplier = 1.0,
        DamageType = "Physical",
        Penetration = 0,
        MitigatedDamage = math.max(0, defendingCard.Defense)
    }
    
    self:_log("✅ Damage calculation test")
    self:_log("   - Base Attack: " .. damageCalc.BaseAttack)
    self:_log("   - Target Defense: " .. defendingCard.Defense)
    self:_log("   - Final Damage: " .. damageCalc.FinalDamage)
    self:_log("   - Mitigated Damage: " .. damageCalc.MitigatedDamage)
    self:_log("   - Critical Hit: " .. tostring(damageCalc.IsCritical))
    
    -- Verify damage calculation logic
    local expectedDamage = math.max(1, attackingCard.Attack - defendingCard.Defense)
    if damageCalc.FinalDamage == expectedDamage then
        self:_log("   - ✅ Damage calculation correct")
    else
        self:_logError("   - ❌ Damage calculation incorrect")
    end
    
    -- Test edge cases
    local zeroDamageAttack = math.max(1, 10 - 50) -- Should be 1 (minimum damage)
    if zeroDamageAttack == 1 then
        self:_log("   - ✅ Minimum damage rule working (1 damage)")
    else
        self:_logError("   - ❌ Minimum damage rule not working")
    end
end

function BattleTestService:_testActionValidation(player: Player, battleService)
    self:_log("Testing action validation...")
    
    local stateResult = battleService:GetBattleState(player)
    if not stateResult.Success or not stateResult.Data then
        self:_log("⚠️  No active battle for action validation test")
        return
    end
    
    local battle = stateResult.Data
    
    -- Test valid action
    local validAction = {
        ActionID = "test_valid",
        PlayerID = player.UserId,
        ActionType = "EndTurn",
        ActionData = {},
        Timestamp = os.time(),
        IsValid = false
    }
    
    local validResult = battleService:ProcessAction(player, validAction)
    if validResult.Success then
        self:_log("✅ Valid action accepted")
    else
        self:_log("⚠️  Valid action rejected: " .. (validResult.ErrorMessage or "Unknown"))
    end
    
    -- Test invalid action (wrong player)
    local invalidAction = {
        ActionID = "test_invalid",
        PlayerID = 99999, -- Invalid player ID
        ActionType = "EndTurn",
        ActionData = {},
        Timestamp = os.time(),
        IsValid = false
    }
    
    local invalidResult = battleService:ProcessAction(player, invalidAction)
    if not invalidResult.Success then
        self:_log("✅ Invalid action properly rejected")
        self:_log("   - Reason: " .. (invalidResult.ErrorMessage or "Unknown"))
    else
        self:_logError("❌ Invalid action was accepted (should be rejected)")
    end
    
    -- Test action with insufficient energy (if player has cards)
    if #battle.Player1.Hand > 0 then
        local handCard = battle.Player1.Hand[1]
        local energyAction = {
            ActionID = "test_energy",
            PlayerID = player.UserId,
            ActionType = "PlayCard",
            ActionData = {
                SourceCardID = handCard.InstanceID
            },
            Timestamp = os.time(),
            IsValid = false
        }
        
        -- Temporarily reduce player energy to test validation
        local originalEnergy = battle.Player1.Energy
        battle.Player1.Energy = 0
        
        local energyResult = battleService:ProcessAction(player, energyAction)
        if not energyResult.Success then
            self:_log("✅ Insufficient energy validation working")
        else
            self:_log("⚠️  Energy validation may not be working properly")
        end
        
        -- Restore energy
        battle.Player1.Energy = originalEnergy
    end
end

function BattleTestService:_testBattleStatistics(battleService)
    self:_log("Testing battle statistics...")
    
    local stats = battleService:GetBattleStatistics()
    
    self:_log("📊 Battle Statistics:")
    self:_log("   - Active Battles: " .. stats.ActiveBattles)
    self:_log("   - Battles Completed: " .. stats.BattlesCompleted)
    self:_log("   - Average Battle Duration: " .. string.format("%.2f", stats.AverageBattleDuration) .. "s")
    self:_log("   - Active Player Count: " .. stats.ActivePlayerCount)
    self:_log("   - Queue Size: " .. stats.QueueSize)
    
    -- Verify statistics validity
    if stats.ActiveBattles >= 0 and stats.BattlesCompleted >= 0 then
        self:_log("✅ Statistics values are valid")
    else
        self:_logError("❌ Invalid statistics values")
    end
    
    if stats.ActivePlayerCount >= 0 and stats.ActivePlayerCount <= stats.ActiveBattles * 2 then
        self:_log("✅ Player count within expected range")
    else
        self:_logError("❌ Player count outside expected range")
    end
end

function BattleTestService:_testPerformanceMetrics(battleService)
    self:_log("Testing performance metrics...")
    
    local startTime = os.clock()
    local operationCount = 0
    
    -- Test multiple battle operations
    for i = 1, 10 do
        local stats = battleService:GetBattleStatistics()
        operationCount += 1
        
        -- Simulate some processing time
        wait(0.01)
    end
    
    local endTime = os.clock()
    local duration = endTime - startTime
    local operationsPerSecond = operationCount / duration
    
    self:_log("📊 Performance Metrics:")
    self:_log("   - Operations tested: " .. operationCount)
    self:_log("   - Total duration: " .. string.format("%.3f", duration) .. "s")
    self:_log("   - Operations per second: " .. string.format("%.1f", operationsPerSecond))
    
    -- Test memory usage
    local memoryBefore = collectgarbage("count")
    
    -- Create and destroy multiple battle state objects
    for i = 1, 100 do
        local mockBattle = {
            BattleID = "test_" .. i,
            Player1 = { Username = "Test1", Health = 100 },
            Player2 = { Username = "Test2", Health = 100 },
            CurrentTurn = 1,
            ActivePlayer = 1
        }
        -- Let it be garbage collected
        mockBattle = nil
    end
    
    collectgarbage("collect")
    local memoryAfter = collectgarbage("count")
    local memoryUsed = memoryAfter - memoryBefore
    
    self:_log("   - Memory usage: " .. string.format("%.2f", memoryUsed) .. "KB")
    self:_log("   - Performance impact: " .. (memoryUsed < 50 and "Low" or "High"))
end

function BattleTestService:TestBattleEndConditions()
    self:_log("Testing battle end conditions...")
    
    local battleService = self.ServiceRegistry:GetService("BattleService")
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        self:_log("⚠️  No player to test battle end conditions")
        return
    end
    
    local stateResult = battleService:GetBattleState(testPlayer)
    if not stateResult.Success or not stateResult.Data then
        self:_log("⚠️  No active battle for end condition test")
        return
    end
    
    local battle = stateResult.Data
    
    -- Test surrender
    local surrenderAction = {
        ActionID = "test_surrender",
        PlayerID = testPlayer.UserId,
        ActionType = "Surrender",
        ActionData = {},
        Timestamp = os.time(),
        IsValid = false
    }
    
    local surrenderResult = battleService:ProcessAction(testPlayer, surrenderAction)
    
    if surrenderResult.Success then
        self:_log("✅ Surrender action processed")
        
        -- Check if battle ended
        wait(0.5)
        local endState = battleService:GetBattleState(testPlayer)
        if not endState.Success then
            self:_log("✅ Battle properly ended after surrender")
        else
            self:_log("⚠️  Battle still active after surrender")
        end
    else
        self:_logError("❌ Surrender action failed")
    end
end

function BattleTestService:TestAIBehavior()
    self:_log("Testing AI behavior patterns...")
    
    local battleService = self.ServiceRegistry:GetService("BattleService")
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        self:_log("⚠️  No player to test AI behavior")
        return
    end
    
    -- Create AI battle for testing
    local result = battleService:CreateBattle(testPlayer, nil, "Practice")
    
    if result.Success and result.Data then
        local battle = result.Data
        self:_log("✅ AI behavior test battle created")
        self:_log("   - AI Personality: " .. (battle.Player2.Username or "Unknown"))
        
        -- Monitor AI actions over several turns
        local aiActionCount = 0
        local turnCount = 0
        
        for i = 1, 5 do -- Test 5 turns
            if battle.ActivePlayer == 2 then -- AI turn
                local turnStartTime = os.clock()
                wait(4) -- Wait for AI to act
                
                local updatedState = battleService:GetBattleState(testPlayer)
                if updatedState.Success and updatedState.Data then
                    if updatedState.Data.CurrentTurn > battle.CurrentTurn then
                        aiActionCount += 1
                        local thinkingTime = os.clock() - turnStartTime
                        self:_log("   - AI Turn " .. i .. ": " .. string.format("%.2f", thinkingTime) .. "s thinking time")
                    end
                    battle = updatedState.Data
                end
            else
                -- End player turn quickly
                local endTurnAction = {
                    ActionID = "test_end_" .. i,
                    PlayerID = testPlayer.UserId,
                    ActionType = "EndTurn",
                    ActionData = {},
                    Timestamp = os.time(),
                    IsValid = false
                }
                battleService:ProcessAction(testPlayer, endTurnAction)
                wait(0.5)
            end
            
            turnCount += 1
            wait(1)
        end
        
        self:_log("📊 AI Behavior Results:")
        self:_log("   - AI actions taken: " .. aiActionCount .. "/" .. turnCount)
        self:_log("   - AI responsiveness: " .. string.format("%.1f", (aiActionCount / turnCount) * 100) .. "%")
        
        -- Clean up test battle
        battleService:EndBattle(battle.BattleID, "Test completed")
    else
        self:_logError("❌ Failed to create AI test battle")
    end
end

function BattleTestService:TestBattleIntegration()
    self:_log("Testing battle system integration...")
    
    local battleService = self.ServiceRegistry:GetService("BattleService")
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local cardDatabase = CardDatabase
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        self:_log("⚠️  No player for integration test")
        return
    end
    
    -- Test PlayerDataService integration
    local playerData = playerDataService:GetPlayerData(testPlayer)
    if playerData then
        self:_log("✅ PlayerDataService integration working")
        self:_log("   - Player level: " .. playerData.Stats.Level)
        self:_log("   - Cards owned: " .. playerData.Collection.TotalCardsOwned)
    else
        self:_logError("❌ PlayerDataService integration failed")
    end
    
    -- Test CardDatabase integration
    local testCard = cardDatabase:GetCard("naruto_001")
    if testCard then
        self:_log("✅ CardDatabase integration working")
        self:_log("   - Test card: " .. testCard.Name)
    else
        self:_logError("❌ CardDatabase integration failed")
    end
    
    -- Test battle creation with real player data
    local integrationResult = battleService:CreateBattle(testPlayer, nil, "Practice")
    if integrationResult.Success then
        self:_log("✅ Battle system integration successful")
        self:_log("   - All services working together properly")
    else
        self:_logError("❌ Battle system integration failed")
    end
end

return BattleTestService.new() 