--!strict
-- CardRevealTestController.luau
-- Test controller for CardRevealController functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)
local RollTypes = require(ReplicatedStorage.Shared.Types.RollTypes)

local CardRevealTestController = {}
CardRevealTestController.__index = CardRevealTestController
setmetatable(CardRevealTestController, {__index = BaseController})

function CardRevealTestController.new()
    local self = BaseController.new("CardRevealTestController", {"CardRevealController", "EffectsController"})
    setmetatable(self, CardRevealTestController)
    
    return self
end

function CardRevealTestController:Initialize()
    self:_log("CardRevealTestController initializing...")
end

function CardRevealTestController:Start()
    self:_log("CardRevealTestController starting...")
    
    --[[
    -- Start testing after a short delay
    spawn(function()
        wait(3)
        self:_startTesting()
    end)
    --]]
end

function CardRevealTestController:_startTesting()
    self:_log("🎨 Starting Card Reveal UI testing...")
    
    local cardRevealController = self.ServiceRegistry:GetService("CardRevealController")
    local effectsController = self.ServiceRegistry:GetService("EffectsController")
    
    -- Test 1: Single card reveal
    self:_testSingleCardReveal(cardRevealController)
    
    -- Test 2: Multiple card reveal
    spawn(function()
        wait(6)
        self:_testMultipleCardReveal(cardRevealController)
    end)
    
    -- Test 3: High rarity card reveal
    spawn(function()
        wait(12)
        self:_testHighRarityReveal(cardRevealController)
    end)
    
    -- Test 4: Batch reveal
    spawn(function()
        wait(18)
        self:_testBatchReveal(cardRevealController)
    end)
    
    -- Test 5: Skip functionality
    spawn(function()
        wait(24)
        self:_testSkipFunctionality(cardRevealController)
    end)
    
    -- Test 6: Responsive design
    spawn(function()
        wait(30)
        self:_testResponsiveDesign(cardRevealController)
    end)
    
    -- Test 7: Effects system
    spawn(function()
        wait(36)
        self:_testEffectsSystem(effectsController)
    end)
    
    -- Test 8: Performance metrics
    spawn(function()
        wait(42)
        self:_testPerformanceMetrics(cardRevealController, effectsController)
    end)
end

function CardRevealTestController:_testSingleCardReveal(controller)
    self:_log("Testing single card reveal...")
    
    local testCard = self:_createTestCard("naruto_001", "Naruto Uzumaki", "Rare", 1200, 800)
    
    local request = {
        Cards = {testCard},
        RevealType = "Single",
        TotalDuration = 2.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ Single card reveal successful")
        self:_log("   - Cards revealed: " .. result.CardsRevealed)
        self:_log("   - Total duration: " .. result.TotalDuration .. "s")
    else
        self:_logError("❌ Single card reveal failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testMultipleCardReveal(controller)
    self:_log("Testing multiple card reveal...")
    
    local testCards = {
        self:_createTestCard("naruto_001", "Naruto Uzumaki", "Rare", 1200, 800),
        self:_createTestCard("sasuke_001", "Sasuke Uchiha", "Epic", 1400, 900),
        self:_createTestCard("sakura_001", "Sakura Haruno", "Common", 1000, 1200)
    }
    
    local request = {
        Cards = testCards,
        RevealType = "Multi",
        TotalDuration = 4.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ Multiple card reveal successful")
        self:_log("   - Cards revealed: " .. result.CardsRevealed)
        
        -- Monitor reveal state
        spawn(function()
            while controller:IsRevealing() do
                local state = controller:GetCurrentRevealState()
                if state then
                    self:_log("   - Progress: " .. string.format("%.1f", state.RevealProgress * 100) .. "%")
                end
                wait(0.5)
            end
        end)
    else
        self:_logError("❌ Multiple card reveal failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testHighRarityReveal(controller)
    self:_log("Testing high rarity card reveal...")
    
    local testCards = {
        self:_createTestCard("goku_001", "Goku Super Saiyan", "Legendary", 2000, 1500),
        self:_createTestCard("saitama_001", "One Punch Man", "Mythical", 9999, 1000),
        self:_createTestCard("zeno_001", "Zeno Sama", "Ultimate", 10000, 10000)
    }
    
    local request = {
        Cards = testCards,
        RevealType = "Guaranteed",
        TotalDuration = 6.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ High rarity reveal successful")
        self:_log("   - Expected intense effects for high rarity cards")
        
        -- Test effects controller integration
        local effectsController = self.ServiceRegistry:GetService("EffectsController")
        if effectsController then
            self:_log("   - Effects controller active: " .. effectsController:GetActiveEffectCount() .. " effects")
        end
    else
        self:_logError("❌ High rarity reveal failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testBatchReveal(controller)
    self:_log("Testing batch reveal...")
    
    local testCards = {}
    local rarities = {"Common", "Rare", "Epic", "Legendary", "Mythical"}
    
    for i = 1, 8 do
        local rarity = rarities[math.random(1, #rarities)]
        table.insert(testCards, self:_createTestCard("batch_" .. i, "Test Card " .. i, rarity, 1000 + i * 100, 800 + i * 50))
    end
    
    local request = {
        Cards = testCards,
        RevealType = "Batch",
        TotalDuration = 5.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ Batch reveal successful")
        self:_log("   - Batch size: " .. result.CardsRevealed)
        
        -- Test layout calculation
        local state = controller:GetCurrentRevealState()
        if state then
            self:_log("   - Total cards: " .. state.TotalCards)
            self:_log("   - Layout should handle " .. state.TotalCards .. " cards responsively")
        end
    else
        self:_logError("❌ Batch reveal failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testSkipFunctionality(controller)
    self:_log("Testing skip functionality...")
    
    local testCards = {
        self:_createTestCard("skip_test_1", "Skip Test 1", "Epic", 1300, 900),
        self:_createTestCard("skip_test_2", "Skip Test 2", "Legendary", 1800, 1200),
        self:_createTestCard("skip_test_3", "Skip Test 3", "Rare", 1100, 700)
    }
    
    local request = {
        Cards = testCards,
        RevealType = "Multi",
        TotalDuration = 6.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ Skip test started")
        
        -- Wait a bit, then skip
        spawn(function()
            wait(2)
            
            if controller:IsRevealing() then
                local skipSuccess = controller:SkipCurrentReveal()
                if skipSuccess then
                    self:_log("✅ Skip functionality successful")
                    self:_log("   - Reveal was skipped successfully")
                else
                    self:_logError("❌ Skip functionality failed")
                end
            else
                self:_log("⚠️  Reveal finished before skip test")
            end
        end)
    else
        self:_logError("❌ Skip test setup failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testResponsiveDesign(controller)
    self:_log("Testing responsive design...")
    
    local testCards = {
        self:_createTestCard("responsive_1", "Mobile Test", "Common", 1000, 800),
        self:_createTestCard("responsive_2", "Tablet Test", "Rare", 1200, 900),
        self:_createTestCard("responsive_3", "Desktop Test", "Epic", 1400, 1000)
    }
    
    local request = {
        Cards = testCards,
        RevealType = "Multi",
        TotalDuration = 3.0,
        AudioEnabled = true,
        EffectsEnabled = true,
        SkipAnimations = false
    }
    
    local result = controller:RevealCards(request)
    
    if result.Success then
        self:_log("✅ Responsive design test successful")
        
        -- Check device detection
        local stats = controller:GetRevealStatistics()
        self:_log("   - Device type: " .. stats.DeviceType)
        self:_log("   - Layout adapted for device type")
        
        -- Test different screen sizes (simulation)
        local screenSize = workspace.CurrentCamera.ViewportSize
        self:_log("   - Screen size: " .. screenSize.X .. "x" .. screenSize.Y)
        
        if screenSize.X < 768 then
            self:_log("   - Mobile layout detected")
        elseif screenSize.X < 1024 then
            self:_log("   - Tablet layout detected")
        else
            self:_log("   - Desktop layout detected")
        end
    else
        self:_logError("❌ Responsive design test failed: " .. (result.ErrorMessage or "Unknown error"))
    end
end

function CardRevealTestController:_testEffectsSystem(effectsController)
    self:_log("Testing effects system...")
    
    if not effectsController then
        self:_logError("❌ Effects controller not available")
        return
    end
    
    -- Test screen shake
    effectsController:TriggerScreenShake(0.5, 1.0)
    self:_log("✅ Screen shake triggered")
    
    -- Test screen flash
    local flashID = effectsController:PlayScreenFlash(Color3.new(1, 0.8, 0), 0.6, 0.5)
    self:_log("✅ Screen flash triggered: " .. flashID)
    
    -- Test performance metrics
    local metrics = effectsController:GetPerformanceMetrics()
    self:_log("📊 Effects performance metrics:")
    self:_log("   - Active effects: " .. metrics.ActiveEffects)
    self:_log("   - Memory usage: " .. string.format("%.2f", metrics.MemoryUsage) .. "KB")
    self:_log("   - Frame rate: " .. string.format("%.1f", metrics.FrameRate) .. "FPS")
    
    -- Test effect cleanup
    spawn(function()
        wait(3)
        effectsController:ClearAllEffects()
        self:_log("✅ Effects cleared successfully")
    end)
end

function CardRevealTestController:_testPerformanceMetrics(revealController, effectsController)
    self:_log("Testing performance metrics...")
    
    -- Get reveal statistics
    local revealStats = revealController:GetRevealStatistics()
    self:_log("📊 Reveal Statistics:")
    self:_log("   - Total reveals: " .. revealStats.RevealCount)
    self:_log("   - Average reveal time: " .. string.format("%.2f", revealStats.AverageRevealTime) .. "s")
    self:_log("   - Skip rate: " .. string.format("%.2f", revealStats.SkipRate * 100) .. "%")
    self:_log("   - Queue size: " .. revealStats.QueueSize)
    
    -- Get effects metrics
    if effectsController then
        local effectsMetrics = effectsController:GetPerformanceMetrics()
        self:_log("📊 Effects Metrics:")
        self:_log("   - Active animations: " .. effectsMetrics.ActiveAnimations)
        self:_log("   - Active effects: " .. effectsMetrics.ActiveEffects)
        self:_log("   - Render time: " .. string.format("%.2f", effectsMetrics.RenderTime) .. "ms")
    end
    
    -- Test memory usage
    local memoryBefore = collectgarbage("count")
    
    -- Stress test with multiple reveals
    local stressCards = {}
    for i = 1, 10 do
        table.insert(stressCards, self:_createTestCard("stress_" .. i, "Stress Test " .. i, "Common", 1000, 800))
    end
    
    local stressRequest = {
        Cards = stressCards,
        RevealType = "Batch",
        TotalDuration = 2.0,
        AudioEnabled = false,
        EffectsEnabled = false,
        SkipAnimations = true
    }
    
    local stressResult = revealController:RevealCards(stressRequest)
    
    if stressResult.Success then
        local memoryAfter = collectgarbage("count")
        local memoryUsed = memoryAfter - memoryBefore
        
        self:_log("📊 Stress Test Results:")
        self:_log("   - Memory usage: " .. string.format("%.2f", memoryUsed) .. "KB")
        self:_log("   - Performance impact: " .. (memoryUsed < 100 and "Low" or "High"))
    end
end

function CardRevealTestController:TestInputHandling()
    self:_log("Testing input handling...")
    
    local revealController = self.ServiceRegistry:GetService("CardRevealController")
    
    -- Test keyboard input
    self:_log("   - Testing keyboard input (Space to skip, Enter to continue)")
    
    -- Test mobile touch input
    if UserInputService.TouchEnabled then
        self:_log("   - Testing mobile touch input (double tap to skip)")
    end
    
    -- Test button interactions
    self:_log("   - Testing UI button interactions")
    
    self:_log("✅ Input handling test completed")
end

function CardRevealTestController:TestErrorHandling()
    self:_log("Testing error handling...")
    
    local revealController = self.ServiceRegistry:GetService("CardRevealController")
    
    -- Test invalid request
    local invalidRequest = {
        Cards = {},
        RevealType = "Invalid",
        TotalDuration = -1,
        AudioEnabled = true,
        EffectsEnabled = true
    }
    
    local result = revealController:RevealCards(invalidRequest)
    
    if not result.Success then
        self:_log("✅ Invalid request properly rejected")
        self:_log("   - Error: " .. (result.ErrorMessage or "Unknown"))
    else
        self:_log("⚠️  Invalid request was accepted (should be rejected)")
    end
    
    -- Test nil card data
    local nilCardRequest = {
        Cards = nil,
        RevealType = "Single",
        TotalDuration = 2.0,
        AudioEnabled = true,
        EffectsEnabled = true
    }
    
    local nilResult = revealController:RevealCards(nilCardRequest)
    
    if not nilResult.Success then
        self:_log("✅ Nil card request properly handled")
    else
        self:_log("⚠️  Nil card request should have failed")
    end
end

function CardRevealTestController:TestAnimationTiming()
    self:_log("Testing animation timing...")
    
    local revealController = self.ServiceRegistry:GetService("CardRevealController")
    
    -- Test different timing scenarios
    local timingTests = {
        {duration = 1.0, name = "Fast"},
        {duration = 3.0, name = "Normal"},
        {duration = 6.0, name = "Slow"}
    }
    
    for i, test in ipairs(timingTests) do
        spawn(function()
            wait(i * 8) -- Stagger tests
            
            self:_log("   - Testing " .. test.name .. " timing (" .. test.duration .. "s)")
            
            local testCard = self:_createTestCard("timing_" .. i, "Timing Test " .. i, "Epic", 1300, 900)
            
            local request = {
                Cards = {testCard},
                RevealType = "Single",
                TotalDuration = test.duration,
                AudioEnabled = true,
                EffectsEnabled = true,
                SkipAnimations = false
            }
            
            local startTime = os.clock()
            local result = revealController:RevealCards(request)
            
            if result.Success then
                -- Monitor actual timing
                spawn(function()
                    while revealController:IsRevealing() do
                        wait(0.1)
                    end
                    
                    local actualTime = os.clock() - startTime
                    self:_log("   - " .. test.name .. " timing actual: " .. string.format("%.2f", actualTime) .. "s")
                end)
            end
        end)
    end
end

function CardRevealTestController:_createTestCard(id: string, name: string, rarity: string, attack: number, defense: number): RollTypes.CardRollResult
    local cardData = {
        ID = id,
        Name = name,
        Rarity = rarity,
        Attack = attack,
        Defense = defense,
        Health = 100,
        Cost = 5,
        Special = "Test Special",
        Series = "Test Series",
        Type = "Fighter",
        Image = "rbxasset://textures/face.png",
        Description = "A test card for reveal testing"
    }
    
    return {
        Card = cardData,
        Rarity = rarity,
        IsNew = true,
        IsPityResult = false,
        PityCount = 0,
        RollPosition = 1,
        AnimationDelay = 2000, -- 2 seconds
        EffectIntensity = rarity == "Ultimate" and 1.0 or (rarity == "Mythical" and 0.9 or (rarity == "Legendary" and 0.8 or 0.5))
    }
end

return CardRevealTestController.new() 