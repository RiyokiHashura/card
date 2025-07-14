--!strict
-- CardRevealController.luau
-- Main controller for card reveal UI system with psychological timing and responsive design

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)
local RollTypes = require(ReplicatedStorage.Shared.Types.RollTypes)
local UIUtils = require(ReplicatedStorage.Shared.Utils.UIUtils)
local UIConstants = require(ReplicatedStorage.Shared.Constants.UIConstants)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)

type CardRevealRequest = UITypes.CardRevealRequest
type CardRevealResult = UITypes.CardRevealResult
type CardRevealState = UITypes.CardRevealState
type RevealUIElements = UITypes.RevealUIElements
type CardDisplayElement = UITypes.CardDisplayElement
type CardLayoutConfig = UITypes.CardLayoutConfig

local CardRevealController = {}
CardRevealController.__index = CardRevealController
setmetatable(CardRevealController, {__index = BaseController})

-- UI Configuration
local UI_CONFIG = {
    CardSize = UDim2.new(0, 200, 0, 280),
    CardSpacing = 20,
    MaxCardsPerRow = 5,
    AnimationDuration = 0.8,
    RevealDelay = 0.3,
    SkipThreshold = 0.5,
    ResponsiveBreakpoints = {
        Mobile = 768,
        Tablet = 1024,
        Desktop = 1920
    }
}

-- Reveal State
local REVEAL_STATES = {
    IDLE = "Idle",
    PREPARING = "Preparing",
    REVEALING = "Revealing",
    COMPLETED = "Completed",
    SKIPPED = "Skipped"
}

function CardRevealController.new()
    local self = BaseController.new("CardRevealController", {"EffectsController"})
    setmetatable(self, CardRevealController)
    
    -- UI State
    self._currentState = REVEAL_STATES.IDLE
    self._revealQueue = {} :: {CardRevealRequest}
    self._currentReveal = nil :: CardRevealRequest?
    self._revealState = nil :: CardRevealState?
    
    -- UI Elements
    self._uiElements = nil :: RevealUIElements?
    self._cardDisplays = {} :: {CardDisplayElement}
    
    -- Input handling
    self._inputConnections = {}
    self._lastInputTime = 0
    
    -- Performance tracking
    self._revealCount = 0
    self._averageRevealTime = 0
    self._skipRate = 0
    
    -- Device detection
    self._deviceType = self:_detectDeviceType()
    self._layoutConfig = self:_getLayoutConfig()
    
    return self
end

function CardRevealController:Initialize()
    self:_log("CardRevealController initializing...")
    
    -- Initialize UI elements
    self:_initializeUI()
    
    -- Setup input handlers
    self:_setupInputHandlers()
    
    -- Setup remote event handlers
    self:_setupRemoteHandlers()
    
    self:_log("CardRevealController initialized successfully")
end

function CardRevealController:Start()
    self:_log("CardRevealController starting...")
    
    -- Start reveal processing
    self._revealProcessingConnection = RunService.Heartbeat:Connect(function()
        self:_processRevealQueue()
    end)
    
    self:_log("CardRevealController started successfully")
end

function CardRevealController:Stop()
    self:_log("CardRevealController stopping...")
    
    -- Clean up connections
    if self._revealProcessingConnection then
        self._revealProcessingConnection:Disconnect()
    end
    
    self:_cleanupInputHandlers()
    
    -- Clear UI
    if self._uiElements then
        self._uiElements.MainFrame:Destroy()
    end
    
    self:_log("CardRevealController stopped")
end

-- Public Methods

-- Simple method for revealing a single card
function CardRevealController:RevealSingleCard(cardResult: RollTypes.CardRollResult)
	-- Create a simple request for a single card
	local request: CardRevealRequest = {
		Cards = {cardResult},
		PlayerId = game.Players.LocalPlayer.UserId,
		SessionId = "single_card_" .. os.time(),
		RequestTime = os.time(),
		Source = "TestScene",
		Priority = "Normal",
		RevealType = "Single"
	}
	
	return self:RevealCards(request)
end

function CardRevealController:RevealCards(request: CardRevealRequest): CardRevealResult
    self:_log("Revealing " .. #request.Cards .. " cards with type: " .. request.RevealType)
    
    -- Validate request
    if not self:_validateRevealRequest(request) then
        return {
            Success = false,
            CardsRevealed = 0,
            TotalDuration = 0,
            UserSkipped = false,
            ErrorMessage = "Invalid reveal request"
        }
    end
    
    -- Add to queue if currently revealing
    if self._currentState ~= REVEAL_STATES.IDLE then
        table.insert(self._revealQueue, request)
        return {
            Success = true,
            CardsRevealed = 0,
            TotalDuration = 0,
            UserSkipped = false,
            ErrorMessage = "Added to reveal queue"
        }
    end
    
    -- Start reveal process
    return self:_startRevealProcess(request)
end

function CardRevealController:SkipCurrentReveal(): boolean
    if self._currentState ~= REVEAL_STATES.REVEALING then
        return false
    end
    
    if not self._revealState or not self._revealState.CanSkip then
        return false
    end
    
    self:_log("Skipping current reveal")
    
    -- Update state
    self._currentState = REVEAL_STATES.SKIPPED
    self._revealState.IsPaused = true
    
    -- Complete all pending animations instantly
    self:_skipAllAnimations()
    
    -- Show final state
    self:_showFinalRevealState()
    
    -- Update statistics
    self._skipRate = (self._skipRate + 1) / 2
    
    return true
end

function CardRevealController:PauseReveal(): boolean
    if self._currentState ~= REVEAL_STATES.REVEALING then
        return false
    end
    
    if not self._revealState then
        return false
    end
    
    self._revealState.IsPaused = true
    self:_log("Reveal paused")
    
    return true
end

function CardRevealController:ResumeReveal(): boolean
    if self._currentState ~= REVEAL_STATES.REVEALING then
        return false
    end
    
    if not self._revealState then
        return false
    end
    
    self._revealState.IsPaused = false
    self:_log("Reveal resumed")
    
    return true
end

function CardRevealController:GetCurrentRevealState(): CardRevealState?
    return self._revealState
end

function CardRevealController:IsRevealing(): boolean
    return self._currentState == REVEAL_STATES.REVEALING
end

function CardRevealController:GetRevealStatistics(): {[string]: any}
    return {
        RevealCount = self._revealCount,
        AverageRevealTime = self._averageRevealTime,
        SkipRate = self._skipRate,
        DeviceType = self._deviceType,
        QueueSize = #self._revealQueue
    }
end

-- Private Methods

function CardRevealController:_initializeUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main UI structure
    local mainFrame = Instance.new("ScreenGui")
    mainFrame.Name = "CardRevealUI"
    mainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainFrame.ResetOnSpawn = false
    mainFrame.Parent = playerGui
    
    -- Create reveal container
    local revealContainer = Instance.new("Frame")
    revealContainer.Name = "RevealContainer"
    revealContainer.Size = UDim2.new(1, 0, 1, 0)
    revealContainer.Position = UDim2.new(0, 0, 0, 0)
    revealContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    revealContainer.BackgroundTransparency = 0.8
    revealContainer.Visible = false
    revealContainer.ZIndex = 100
    revealContainer.Parent = mainFrame
    
    -- Create background overlay
    local backgroundOverlay = Instance.new("Frame")
    backgroundOverlay.Name = "BackgroundOverlay"
    backgroundOverlay.Size = UDim2.new(1, 0, 1, 0)
    backgroundOverlay.Position = UDim2.new(0, 0, 0, 0)
    backgroundOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    backgroundOverlay.BackgroundTransparency = 0.5
    backgroundOverlay.ZIndex = 10
    backgroundOverlay.Parent = revealContainer
    
    -- Create effects layer
    local effectsLayer = Instance.new("Frame")
    effectsLayer.Name = "EffectsLayer"
    effectsLayer.Size = UDim2.new(1, 0, 1, 0)
    effectsLayer.Position = UDim2.new(0, 0, 0, 0)
    effectsLayer.BackgroundTransparency = 1
    effectsLayer.ZIndex = 200
    effectsLayer.Parent = revealContainer
    
    -- Create progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0.8, 0, 0, 4)
    progressBar.Position = UDim2.new(0.1, 0, 0.95, 0)
    progressBar.BackgroundColor3 = Color3.new(1, 1, 1)
    progressBar.BackgroundTransparency = 0.3
    progressBar.ZIndex = 150
    progressBar.Parent = revealContainer
    
    -- Progress fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.new(0.3, 0.8, 1)
    progressFill.BackgroundTransparency = 0
    progressFill.ZIndex = 151
    progressFill.Parent = progressBar
    
    -- Create skip button
    local skipButton = Instance.new("TextButton")
    skipButton.Name = "SkipButton"
    skipButton.Size = UDim2.new(0, 100, 0, 40)
    skipButton.Position = UDim2.new(1, -120, 0, 20)
    skipButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    skipButton.BackgroundTransparency = 0.2
    skipButton.Text = "Skip"
    skipButton.TextColor3 = Color3.new(1, 1, 1)
    skipButton.TextScaled = true
    skipButton.ZIndex = 150
    skipButton.Parent = revealContainer
    
    -- Skip button corner
    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = UDim.new(0, 8)
    skipCorner.Parent = skipButton
    
    -- Create continue button
    local continueButton = Instance.new("TextButton")
    continueButton.Name = "ContinueButton"
    continueButton.Size = UDim2.new(0, 120, 0, 40)
    continueButton.Position = UDim2.new(0.5, -60, 0.9, 0)
    continueButton.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3)
    continueButton.BackgroundTransparency = 0.2
    continueButton.Text = "Continue"
    continueButton.TextColor3 = Color3.new(1, 1, 1)
    continueButton.TextScaled = true
    continueButton.Visible = false
    continueButton.ZIndex = 150
    continueButton.Parent = revealContainer
    
    -- Continue button corner
    local continueCorner = Instance.new("UICorner")
    continueCorner.CornerRadius = UDim.new(0, 8)
    continueCorner.Parent = continueButton
    
    -- Store UI elements
    self._uiElements = {
        MainFrame = mainFrame,
        RevealContainer = revealContainer,
        CardDisplays = {},
        ProgressBar = progressBar,
        SkipButton = skipButton,
        ContinueButton = continueButton,
        BackgroundOverlay = backgroundOverlay,
        EffectsLayer = effectsLayer
    }
    
    self:_log("UI elements initialized")
end

function CardRevealController:_setupInputHandlers()
    -- Skip button handler
    self._inputConnections.SkipButton = self._uiElements.SkipButton.MouseButton1Click:Connect(function()
        self:SkipCurrentReveal()
    end)
    
    -- Continue button handler
    self._inputConnections.ContinueButton = self._uiElements.ContinueButton.MouseButton1Click:Connect(function()
        self:_completeReveal()
    end)
    
    -- Keyboard input
    self._inputConnections.KeyboardInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            if self._currentState == REVEAL_STATES.REVEALING then
                self:SkipCurrentReveal()
            end
        elseif input.KeyCode == Enum.KeyCode.Return then
            if self._currentState == REVEAL_STATES.COMPLETED then
                self:_completeReveal()
            end
        end
    end)
    
    -- Touch input for mobile
    if self._deviceType == "Mobile" then
        self._inputConnections.TouchInput = UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
            if gameProcessed then return end
            
            local currentTime = os.clock()
            if currentTime - self._lastInputTime < 0.5 then
                -- Double tap to skip
                self:SkipCurrentReveal()
            end
            self._lastInputTime = currentTime
        end)
    end
end

function CardRevealController:_setupRemoteHandlers()
	-- Setup remote event handlers for server communication
	-- TODO: Create CardRevealRequest remote event in appropriate service
	-- RemoteEventHandler:ConnectRemoteEventClient("CardRevealRequest", function(revealData)
	--     local request = {
	--         Cards = revealData.Cards,
	--         PlayerID = revealData.PlayerID,
	--         RevealSettings = revealData.RevealSettings or {}
	--     }
	--     
	--     self:RevealCards(request)
	-- end)
end

function CardRevealController:_startRevealProcess(request: CardRevealRequest): CardRevealResult
    local startTime = os.clock()
    
    -- Update state
    self._currentState = REVEAL_STATES.PREPARING
    self._currentReveal = request
    
    -- Initialize reveal state
    self._revealState = {
        CurrentCard = 0,
        TotalCards = #request.Cards,
        RevealStartTime = startTime,
        IsRevealing = true,
        IsPaused = false,
        CanSkip = true,
        RevealProgress = 0
    }
    
    -- Show UI
    self._uiElements.RevealContainer.Visible = true
    
    -- Create card displays
    self:_createCardDisplays(request.Cards)
    
    -- Start reveal sequence
    self:_startRevealSequence(request)
    
    return {
        Success = true,
        CardsRevealed = #request.Cards,
        TotalDuration = request.TotalDuration,
        UserSkipped = false
    }
end

function CardRevealController:_createCardDisplays(cards: {RollTypes.CardRollResult})
    -- Clear existing displays
    for _, display in ipairs(self._cardDisplays) do
        display.Frame:Destroy()
    end
    self._cardDisplays = {}
    
    -- Calculate layout
    local layout = self:_calculateCardLayout(#cards)
    
    -- Create card displays
    for i, cardResult in ipairs(cards) do
        local cardDisplay = self:_createCardDisplay(cardResult, i, layout)
        table.insert(self._cardDisplays, cardDisplay)
    end
end

function CardRevealController:_createCardDisplay(cardResult: RollTypes.CardRollResult, index: number, layout: CardLayoutConfig): CardDisplayElement
    local card = cardResult.Card
    local rarity = cardResult.Rarity
    
    -- Calculate position
    local row = math.floor((index - 1) / layout.MaxCardsPerRow)
    local col = (index - 1) % layout.MaxCardsPerRow
    local totalRows = math.ceil(self._revealState.TotalCards / layout.MaxCardsPerRow)
    
    -- Center the layout
    local startX = (1 - (math.min(layout.MaxCardsPerRow, self._revealState.TotalCards) * layout.CardSize.X.Scale + (layout.MaxCardsPerRow - 1) * layout.CardSpacing / 1000)) / 2
    local startY = (1 - (totalRows * layout.CardSize.Y.Scale + (totalRows - 1) * layout.CardSpacing / 1000)) / 2
    
    local position = UDim2.new(
        startX + col * (layout.CardSize.X.Scale + layout.CardSpacing / 1000),
        0,
        startY + row * (layout.CardSize.Y.Scale + layout.CardSpacing / 1000),
        0
    )
    
    -- Create card frame
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "CardDisplay_" .. index
    cardFrame.Size = layout.CardSize
    cardFrame.Position = position
    cardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    cardFrame.BackgroundTransparency = 0.1
    cardFrame.ZIndex = 50
    cardFrame.Parent = self._uiElements.RevealContainer
    
    -- Add corner radius
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = cardFrame
    
    -- Create card image
    local cardImage = Instance.new("ImageLabel")
    cardImage.Name = "CardImage"
    cardImage.Size = UDim2.new(1, -20, 0.7, -20)
    cardImage.Position = UDim2.new(0, 10, 0, 10)
    cardImage.BackgroundTransparency = 1
    cardImage.Image = card.Image or ""
    cardImage.ImageTransparency = 1 -- Start hidden
    cardImage.ZIndex = 51
    cardImage.Parent = cardFrame
    
    -- Create rarity border
    local rarityBorder = Instance.new("Frame")
    rarityBorder.Name = "RarityBorder"
    rarityBorder.Size = UDim2.new(1, 4, 1, 4)
    rarityBorder.Position = UDim2.new(0, -2, 0, -2)
    rarityBorder.BackgroundColor3 = GameConstants.RarityColors[rarity] or Color3.new(0.7, 0.7, 0.7)
    rarityBorder.BackgroundTransparency = 0.3
    rarityBorder.ZIndex = 49
    rarityBorder.Parent = cardFrame
    
    -- Border corner
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 14)
    borderCorner.Parent = rarityBorder
    
    -- Create name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -20, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 10, 0.75, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = card.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextTransparency = 1 -- Start hidden
    nameLabel.ZIndex = 52
    nameLabel.Parent = cardFrame
    
    -- Create stats frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -20, 0.1, 0)
    statsFrame.Position = UDim2.new(0, 10, 0.85, 0)
    statsFrame.BackgroundTransparency = 1
    statsFrame.ZIndex = 52
    statsFrame.Parent = cardFrame
    
    -- Attack stat
    local attackLabel = Instance.new("TextLabel")
    attackLabel.Name = "AttackLabel"
    attackLabel.Size = UDim2.new(0.5, -5, 1, 0)
    attackLabel.Position = UDim2.new(0, 0, 0, 0)
    attackLabel.BackgroundTransparency = 1
    attackLabel.Text = "ATK: " .. card.Attack
    attackLabel.TextColor3 = Color3.new(1, 0.8, 0.8)
    attackLabel.TextScaled = true
    attackLabel.Font = Enum.Font.SourceSans
    attackLabel.TextTransparency = 1 -- Start hidden
    attackLabel.ZIndex = 53
    attackLabel.Parent = statsFrame
    
    -- Defense stat
    local defenseLabel = Instance.new("TextLabel")
    defenseLabel.Name = "DefenseLabel"
    defenseLabel.Size = UDim2.new(0.5, -5, 1, 0)
    defenseLabel.Position = UDim2.new(0.5, 5, 0, 0)
    defenseLabel.BackgroundTransparency = 1
    defenseLabel.Text = "DEF: " .. card.Defense
    defenseLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    defenseLabel.TextScaled = true
    defenseLabel.Font = Enum.Font.SourceSans
    defenseLabel.TextTransparency = 1 -- Start hidden
    defenseLabel.ZIndex = 53
    defenseLabel.Parent = statsFrame
    
    -- Create effect container
    local effectContainer = Instance.new("Frame")
    effectContainer.Name = "EffectContainer"
    effectContainer.Size = UDim2.new(1, 0, 1, 0)
    effectContainer.Position = UDim2.new(0, 0, 0, 0)
    effectContainer.BackgroundTransparency = 1
    effectContainer.ZIndex = 60
    effectContainer.Parent = cardFrame
    
    -- Set initial scale (hidden)
    cardFrame.Size = UDim2.new(0, 0, 0, 0)
    cardFrame.Position = UDim2.new(position.X.Scale + layout.CardSize.X.Scale / 2, 0, position.Y.Scale + layout.CardSize.Y.Scale / 2, 0)
    
    return {
        Frame = cardFrame,
        CardImage = cardImage,
        RarityBorder = rarityBorder,
        NameLabel = nameLabel,
        StatsFrame = statsFrame,
        EffectContainer = effectContainer,
        IsVisible = false,
        CurrentCard = card
    }
end

function CardRevealController:_startRevealSequence(request: CardRevealRequest)
    self._currentState = REVEAL_STATES.REVEALING
    
    -- Calculate timing for reveals
    local totalDuration = request.TotalDuration
    local cardDelay = totalDuration / #request.Cards
    
    -- Skip animations if requested
    if request.SkipAnimations then
        self:_skipAllAnimations()
        return
    end
    
    -- Reveal cards with staggered timing
    for i, cardResult in ipairs(request.Cards) do
        spawn(function()
            local delay = cardResult.AnimationDelay / 1000 -- Convert to seconds
            wait(delay)
            
            if self._currentState == REVEAL_STATES.REVEALING and not self._revealState.IsPaused then
                self:_revealCard(cardResult, self._cardDisplays[i])
            end
        end)
    end
    
    -- Start progress tracking
    self:_startProgressTracking(totalDuration)
end

function CardRevealController:_revealCard(cardResult: RollTypes.CardRollResult, cardDisplay: CardDisplayElement)
	self:_log("Revealing card: " .. cardResult.Card.Name .. " (" .. cardResult.Rarity .. ")")
	
	-- Update card display
	if cardDisplay.CardImage then
		cardDisplay.CardImage.Image = cardResult.Card.Image
	end
	
	-- Play all effects
	local effectsController = self:_getService("EffectsController")
	local polishEffectsController = self:_getService("PolishEffectsController")
	
	if effectsController and polishEffectsController then
		-- Play the card reveal effect with enhanced particle system
		effectsController:PlayCardRevealEffects(cardResult, cardDisplay.EffectContainer)
		
		-- Add advanced screen effects for high rarities
		if cardResult.Rarity == "Legendary" or cardResult.Rarity == "Ultimate" then
			polishEffectsController:PlayScreenEffect("Bloom", 0.8, 1.5)
			polishEffectsController:PlayScreenEffect("ChromaticAberration", 0.6, 1.0)
		elseif cardResult.Rarity == "Epic" then
			polishEffectsController:PlayScreenEffect("Bloom", 0.5, 1.0)
		end
		
		-- Add rarity-specific particle effects
		local cardPosition = polishEffectsController:_getWorldPositionFromGui(cardDisplay.Frame)
		
		if cardResult.Rarity == "Ultimate" then
			polishEffectsController:SpawnParticleEffect("RainbowCosmos", cardPosition, cardDisplay.Frame)
			-- Add multiple layered effects for ultimate rarity
			spawn(function()
				wait(0.5)
				polishEffectsController:SpawnParticleEffect("GoldenNova", cardPosition, cardDisplay.Frame)
			end)
		elseif cardResult.Rarity == "Legendary" then
			polishEffectsController:SpawnParticleEffect("GoldenNova", cardPosition, cardDisplay.Frame)
			-- Add secondary sparkle layer
			spawn(function()
				wait(0.3)
				polishEffectsController:SpawnParticleEffect("CardSparkle", cardPosition, cardDisplay.Frame)
			end)
		elseif cardResult.Rarity == "Epic" then
			polishEffectsController:SpawnParticleEffect("EpicSpark", cardPosition, cardDisplay.Frame)
		elseif cardResult.Rarity == "Rare" then
			polishEffectsController:SpawnParticleEffect("RareGlow", cardPosition, cardDisplay.Frame)
		elseif cardResult.Rarity == "Uncommon" then
			polishEffectsController:SpawnParticleEffect("UncommonShimmer", cardPosition, cardDisplay.Frame)
		else
			-- Common cards get subtle sparkle
			polishEffectsController:SpawnParticleEffect("CardSparkle", cardPosition, cardDisplay.Frame)
		end
	end
	
	-- Update reveal state
	self._revealState.CurrentCard = index
	self._revealState.RevealProgress = index / self._revealState.TotalCards
	
	-- Mark as visible
	cardDisplay.IsVisible = true
	
	-- Check if this is the last card
	if index == self._revealState.TotalCards then
		spawn(function()
			wait(1.0) -- Wait for effects to finish
			self:_onRevealComplete()
		end)
	end
end

function CardRevealController:_skipAllAnimations()
    -- Instantly show all cards
    for i, cardDisplay in ipairs(self._cardDisplays) do
        cardDisplay.Frame.Size = self._layoutConfig.CardSize
        cardDisplay.Frame.Position = UDim2.new(
            cardDisplay.Frame.Position.X.Scale - self._layoutConfig.CardSize.X.Scale / 2,
            0,
            cardDisplay.Frame.Position.Y.Scale - self._layoutConfig.CardSize.Y.Scale / 2,
            0
        )
        
        cardDisplay.CardImage.ImageTransparency = 0
        cardDisplay.NameLabel.TextTransparency = 0
        
        -- Show stats
        local attackLabel = cardDisplay.StatsFrame:FindFirstChild("AttackLabel")
        local defenseLabel = cardDisplay.StatsFrame:FindFirstChild("DefenseLabel")
        
        if attackLabel then attackLabel.TextTransparency = 0 end
        if defenseLabel then defenseLabel.TextTransparency = 0 end
        
        cardDisplay.IsVisible = true
    end
    
    -- Update progress
    self._revealState.RevealProgress = 1.0
    self._revealState.CurrentCard = self._revealState.TotalCards
    
    -- Complete immediately
    self:_onRevealComplete()
end

function CardRevealController:_onRevealComplete()
    self._currentState = REVEAL_STATES.COMPLETED
    
    -- Show continue button
    self._uiElements.ContinueButton.Visible = true
    self._uiElements.SkipButton.Visible = false
    
    -- Update statistics
    local revealTime = os.clock() - self._revealState.RevealStartTime
    self._averageRevealTime = (self._averageRevealTime + revealTime) / 2
    self._revealCount += 1
    
    self:_log("Reveal completed in " .. string.format("%.2f", revealTime) .. " seconds")
end

function CardRevealController:_completeReveal()
    -- Hide UI
    self._uiElements.RevealContainer.Visible = false
    
    -- Clear effects
    local effectsController = self.ServiceRegistry:GetService("EffectsController")
    if effectsController then
        effectsController:ClearAllEffects()
    end
    
    -- Reset state
    self._currentState = REVEAL_STATES.IDLE
    self._currentReveal = nil
    self._revealState = nil
    
    -- Process next in queue
    if #self._revealQueue > 0 then
        local nextReveal = table.remove(self._revealQueue, 1)
        self:RevealCards(nextReveal)
    end
end

function CardRevealController:_startProgressTracking(duration: number)
    spawn(function()
        local startTime = os.clock()
        
        while self._currentState == REVEAL_STATES.REVEALING do
            local elapsed = os.clock() - startTime
            local progress = math.min(elapsed / duration, 1.0)
            
            -- Update progress bar
            local progressFill = self._uiElements.ProgressBar:FindFirstChild("ProgressFill")
            if progressFill then
                progressFill.Size = UDim2.new(progress, 0, 1, 0)
            end
            
            wait(0.1)
        end
    end)
end

function CardRevealController:_processRevealQueue()
    if self._currentState == REVEAL_STATES.IDLE and #self._revealQueue > 0 then
        local nextReveal = table.remove(self._revealQueue, 1)
        self:RevealCards(nextReveal)
    end
end

function CardRevealController:_validateRevealRequest(request: CardRevealRequest): boolean
    return request.Cards and #request.Cards > 0 and #request.Cards <= 10
end

function CardRevealController:_calculateCardLayout(cardCount: number): CardLayoutConfig
    local config = self._layoutConfig
    
    -- Adjust for card count
    if cardCount == 1 then
        config.CardSize = UDim2.new(0, 240, 0, 320)
    elseif cardCount <= 3 then
        config.CardSize = UDim2.new(0, 200, 0, 280)
    else
        config.CardSize = UDim2.new(0, 160, 0, 224)
    end
    
    return config
end

function CardRevealController:_detectDeviceType(): string
    local screenSize = workspace.CurrentCamera.ViewportSize
    local guiInset = GuiService:GetGuiInset()
    local screenWidth = screenSize.X
    
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif screenWidth < UI_CONFIG.ResponsiveBreakpoints.Tablet then
        return "Tablet"
    else
        return "Desktop"
    end
end

function CardRevealController:_getLayoutConfig(): CardLayoutConfig
    local deviceType = self._deviceType
    
    if deviceType == "Mobile" then
        return {
            CardSize = UDim2.new(0, 140, 0, 196),
            CardSpacing = 10,
            MaxCardsPerRow = 3,
            AnimationStartPosition = UDim2.new(0.5, 0, 1.2, 0),
            AnimationEndPosition = UDim2.new(0.5, 0, 0.5, 0),
            ScaleMultiplier = 0.8
        }
    elseif deviceType == "Tablet" then
        return {
            CardSize = UDim2.new(0, 180, 0, 252),
            CardSpacing = 15,
            MaxCardsPerRow = 4,
            AnimationStartPosition = UDim2.new(0.5, 0, 1.2, 0),
            AnimationEndPosition = UDim2.new(0.5, 0, 0.5, 0),
            ScaleMultiplier = 0.9
        }
    else
        return {
            CardSize = UDim2.new(0, 200, 0, 280),
            CardSpacing = 20,
            MaxCardsPerRow = 5,
            AnimationStartPosition = UDim2.new(0.5, 0, 1.2, 0),
            AnimationEndPosition = UDim2.new(0.5, 0, 0.5, 0),
            ScaleMultiplier = 1.0
        }
    end
end

function CardRevealController:_showFinalRevealState()
    -- Show final state of all cards
    for _, cardDisplay in ipairs(self._cardDisplays) do
        if not cardDisplay.IsVisible then
            cardDisplay.Frame.Size = self._layoutConfig.CardSize
            cardDisplay.CardImage.ImageTransparency = 0
            cardDisplay.NameLabel.TextTransparency = 0
            cardDisplay.IsVisible = true
        end
    end
    
    -- Show continue button
    self._uiElements.ContinueButton.Visible = true
    self._uiElements.SkipButton.Visible = false
end

function CardRevealController:_cleanupInputHandlers()
    for _, connection in pairs(self._inputConnections) do
        connection:Disconnect()
    end
    self._inputConnections = {}
end

return CardRevealController.new() 