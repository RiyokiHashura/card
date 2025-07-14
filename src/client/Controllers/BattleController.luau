--!strict
-- BattleController.luau
-- Client-side battle controller for elevated 2D combat with visual juice

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local BattleTypes = require(ReplicatedStorage.Shared.Types.BattleTypes)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)

type BattleSession = BattleTypes.BattleSession
type BattleCard = BattleTypes.BattleCard
type BattleUIState = BattleTypes.BattleUIState
type BattleUIElements = BattleTypes.BattleUIElements
type CardUIData = BattleTypes.CardUIData
type BattleAnimation = BattleTypes.BattleAnimation

local BattleController = {}
BattleController.__index = BattleController
setmetatable(BattleController, {__index = BaseController})

-- UI Configuration
local UI_CONFIG = {
    CardSize = UDim2.new(0, 120, 0, 168),
    HandSpacing = 10,
    BattlefieldHeight = 200,
    AnimationDuration = 0.8,
    ImpactFrameDelay = 0.3,
    ScreenShakeIntensity = 0.5,
    HealthBarHeight = 20,
    EnergyBarHeight = 15,
    TurnTimerSize = UDim2.new(0, 200, 0, 30)
}

-- Battle States
local BATTLE_STATES = {
    INACTIVE = "Inactive",
    CONNECTING = "Connecting",
    ACTIVE = "Active",
    WAITING = "Waiting",
    FINISHED = "Finished"
}

function BattleController.new()
    local self = BaseController.new("BattleController", {"EffectsController"})
    setmetatable(self, BattleController)
    
    -- Battle state
    self._battleState = BATTLE_STATES.INACTIVE
    self._currentBattle = nil :: BattleSession?
    self._uiState = nil :: BattleUIState?
    self._uiElements = nil :: BattleUIElements?
    
    -- Card UI tracking
    self._cardUIElements = {} :: {[string]: CardUIData}
    self._handCards = {} :: {CardUIData}
    self._activeAnimations = {} :: {[string]: BattleAnimation}
    
    -- Input handling
    self._selectedCard = nil :: CardUIData?
    self._validTargets = {} :: {CardUIData}
    self._inputConnections = {}
    
    -- Turn management
    self._turnTimeRemaining = 0
    self._isMyTurn = false
    self._canPerformActions = false
    
    -- Performance tracking
    self._frameTime = 0
    self._animationCount = 0
    
    return self
end

function BattleController:Initialize()
    self:_log("BattleController initializing...")
    
    -- Initialize UI
    self:_initializeBattleUI()
    
    -- Setup input handlers
    self:_setupInputHandlers()
    
    -- Setup remote event handlers
    self:_setupRemoteHandlers()
    
    self:_log("BattleController initialized successfully")
end

function BattleController:Start()
    self:_log("BattleController starting...")
    
    -- Start battle update loop
    self._battleUpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:_updateBattle(deltaTime)
    end)
    
    self:_log("BattleController started successfully")
end

function BattleController:Stop()
    self:_log("BattleController stopping...")
    
    -- Clean up battle
    if self._battleState ~= BATTLE_STATES.INACTIVE then
        self:LeaveBattle()
    end
    
    -- Clean up connections
    if self._battleUpdateConnection then
        self._battleUpdateConnection:Disconnect()
    end
    
    self:_cleanupInputHandlers()
    
    -- Destroy UI
    if self._uiElements then
        self._uiElements.MainFrame:Destroy()
    end
    
    self:_log("BattleController stopped")
end

-- Public Methods

function BattleController:StartBattle(request: BattleTypes.StartBattleRequest)
	self:_log("Starting battle...")
	
	-- Fire server to create battle session
	local result = RemoteEventHandler:InvokeServer("StartBattle", request)
	
	if result and result.Success then
		self:_log("Battle started successfully: " .. result.Data.BattleID)
		self._currentBattleSession = result.Data
		self:_renderBattleState(self._currentBattleSession)
		self:Show() -- Make the battle UI visible
	else
		self:_logError("Failed to start battle: " .. (result and result.ErrorMessage or "Unknown error"))
	end
end

function BattleController:PlayCard(cardUIData: CardUIData, targetPosition: Vector2?)
    if not self:_canPerformAction() then
        return
    end
    
    if not cardUIData or not cardUIData.Frame then
        return
    end
    
    self:_log("Playing card: " .. cardUIData.CardID)
    
    -- Send action to server
    local actionData = {
        ActionType = "PlayCard",
        ActionData = {
            SourceCardID = cardUIData.CardID,
            Position = "Active"
        }
    }
    
    RemoteEventHandler:InvokeServer("BattleAction", actionData)
    
    -- Start play animation
    self:_animateCardPlay(cardUIData, targetPosition)
end

function BattleController:AttackWithCard(attackerCardUIData: CardUIData, targetCardUIData: CardUIData?)
    if not self:_canPerformAction() then
        return
    end
    
    if not attackerCardUIData then
        return
    end
    
    self:_log("Attacking with card: " .. attackerCardUIData.CardID)
    
    -- Send action to server
    local actionData = {
        ActionType = "Attack",
        ActionData = {
            SourceCardID = attackerCardUIData.CardID,
            TargetCardID = targetCardUIData and targetCardUIData.CardID or nil
        }
    }
    
    RemoteEventHandler:InvokeServer("BattleAction", actionData)
    
    -- Start attack animation
    self:_animateAttack(attackerCardUIData, targetCardUIData)
end

function BattleController:EndTurn()
    if not self:_canPerformAction() then
        return
    end
    
    self:_log("Ending turn")
    
    -- Send action to server
    local actionData = {
        ActionType = "EndTurn",
        ActionData = {}
    }
    
    RemoteEventHandler:InvokeServer("BattleAction", actionData)
    
    -- Update UI state
    self._isMyTurn = false
    self._canPerformActions = false
    self:_updateActionButtons()
end

function BattleController:LeaveBattle()
    if self._battleState == BATTLE_STATES.INACTIVE then
        return
    end
    
    self:_log("Leaving battle")
    
    -- Send surrender action if in active battle
    if self._battleState == BATTLE_STATES.ACTIVE then
        local actionData = {
            ActionType = "Surrender",
            ActionData = {}
        }
        
        RemoteEventHandler:InvokeServer("BattleAction", actionData)
    end
    
    -- Reset battle state
    self:_resetBattleState()
end

function BattleController:SelectCard(cardUIData: CardUIData)
    if not self:_canPerformAction() then
        return
    end
    
    -- Clear previous selection
    if self._selectedCard then
        self:_updateCardSelection(self._selectedCard, false)
    end
    
    -- Select new card
    self._selectedCard = cardUIData
    self:_updateCardSelection(cardUIData, true)
    
    -- Update valid targets
    self:_updateValidTargets(cardUIData)
    
    self:_log("Selected card: " .. cardUIData.CardID)
end

function BattleController:GetBattleState(): BattleSession?
    return self._currentBattle
end

function BattleController:IsInBattle(): boolean
    return self._battleState == BATTLE_STATES.ACTIVE
end

-- Private Methods

function BattleController:_initializeBattleUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main battle UI
    local mainFrame = Instance.new("ScreenGui")
    mainFrame.Name = "BattleUI"
    mainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainFrame.ResetOnSpawn = false
    mainFrame.Enabled = false
    mainFrame.Parent = playerGui
    
    -- Create battlefield container
    local battleField = Instance.new("Frame")
    battleField.Name = "BattleField"
    battleField.Size = UDim2.new(1, 0, 1, 0)
    battleField.Position = UDim2.new(0, 0, 0, 0)
    battleField.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    battleField.BackgroundTransparency = 0
    battleField.ZIndex = 1
    battleField.Parent = mainFrame
    
    -- Create opponent area (top)
    local player2Area = Instance.new("Frame")
    player2Area.Name = "Player2Area"
    player2Area.Size = UDim2.new(1, -40, 0.4, -20)
    player2Area.Position = UDim2.new(0, 20, 0, 20)
    player2Area.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    player2Area.BackgroundTransparency = 0.8
    player2Area.ZIndex = 10
    player2Area.Parent = battleField
    
    -- Create player area (bottom)
    local player1Area = Instance.new("Frame")
    player1Area.Name = "Player1Area"
    player1Area.Size = UDim2.new(1, -40, 0.4, -20)
    player1Area.Position = UDim2.new(0, 20, 0.6, 0)
    player1Area.BackgroundColor3 = Color3.new(0.3, 0.3, 0.8)
    player1Area.BackgroundTransparency = 0.8
    player1Area.ZIndex = 10
    player1Area.Parent = battleField
    
    -- Create hand container
    local handContainer = Instance.new("Frame")
    handContainer.Name = "HandContainer"
    handContainer.Size = UDim2.new(1, -20, 0, 200)
    handContainer.Position = UDim2.new(0, 10, 1, -210)
    handContainer.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    handContainer.BackgroundTransparency = 0.5
    handContainer.ZIndex = 20
    handContainer.Parent = mainFrame
    
    -- Create action buttons
    local actionButtons = Instance.new("Frame")
    actionButtons.Name = "ActionButtons"
    actionButtons.Size = UDim2.new(0, 200, 0, 60)
    actionButtons.Position = UDim2.new(1, -220, 1, -270)
    actionButtons.BackgroundTransparency = 1
    actionButtons.ZIndex = 30
    actionButtons.Parent = mainFrame
    
    -- End Turn button
    local endTurnButton = Instance.new("TextButton")
    endTurnButton.Name = "EndTurnButton"
    endTurnButton.Size = UDim2.new(1, 0, 0.5, -5)
    endTurnButton.Position = UDim2.new(0, 0, 0, 0)
    endTurnButton.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3)
    endTurnButton.Text = "End Turn"
    endTurnButton.TextColor3 = Color3.new(1, 1, 1)
    endTurnButton.TextScaled = true
    endTurnButton.Font = Enum.Font.SourceSansBold
    endTurnButton.ZIndex = 31
    endTurnButton.Parent = actionButtons
    
    -- Leave Battle button
    local leaveBattleButton = Instance.new("TextButton")
    leaveBattleButton.Name = "LeaveBattleButton"
    leaveBattleButton.Size = UDim2.new(1, 0, 0.5, -5)
    leaveBattleButton.Position = UDim2.new(0, 0, 0.5, 5)
    leaveBattleButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    leaveBattleButton.Text = "Leave Battle"
    leaveBattleButton.TextColor3 = Color3.new(1, 1, 1)
    leaveBattleButton.TextScaled = true
    leaveBattleButton.Font = Enum.Font.SourceSansBold
    leaveBattleButton.ZIndex = 31
    leaveBattleButton.Parent = actionButtons
    
    -- Create status display
    local statusDisplay = Instance.new("Frame")
    statusDisplay.Name = "StatusDisplay"
    statusDisplay.Size = UDim2.new(0, 300, 0, 100)
    statusDisplay.Position = UDim2.new(0, 20, 0, 20)
    statusDisplay.BackgroundColor3 = Color3.new(0, 0, 0)
    statusDisplay.BackgroundTransparency = 0.3
    statusDisplay.ZIndex = 40
    statusDisplay.Parent = mainFrame
    
    -- Create timer display
    local timerDisplay = Instance.new("Frame")
    timerDisplay.Name = "TimerDisplay"
    timerDisplay.Size = UI_CONFIG.TurnTimerSize
    timerDisplay.Position = UDim2.new(0.5, -100, 0, 20)
    timerDisplay.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    timerDisplay.BackgroundTransparency = 0.2
    timerDisplay.ZIndex = 50
    timerDisplay.Parent = mainFrame
    
    -- Timer text
    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.Size = UDim2.new(1, 0, 1, 0)
    timerText.Position = UDim2.new(0, 0, 0, 0)
    timerText.BackgroundTransparency = 1
    timerText.Text = "30"
    timerText.TextColor3 = Color3.new(1, 1, 1)
    timerText.TextScaled = true
    timerText.Font = Enum.Font.SourceSansBold
    timerText.ZIndex = 51
    timerText.Parent = timerDisplay
    
    -- Create effects layer
    local effectsLayer = Instance.new("Frame")
    effectsLayer.Name = "EffectsLayer"
    effectsLayer.Size = UDim2.new(1, 0, 1, 0)
    effectsLayer.Position = UDim2.new(0, 0, 0, 0)
    effectsLayer.BackgroundTransparency = 1
    effectsLayer.ZIndex = 100
    effectsLayer.Parent = mainFrame
    
    -- Store UI elements
    self._uiElements = {
        MainFrame = mainFrame,
        BattleField = battleField,
        Player1Area = player1Area,
        Player2Area = player2Area,
        HandContainer = handContainer,
        ActionButtons = actionButtons,
        StatusDisplay = statusDisplay,
        TimerDisplay = timerDisplay,
        EffectsLayer = effectsLayer
    }
    
    self:_log("Battle UI initialized")
end

function BattleController:_setupInputHandlers()
    -- End Turn button
    self._inputConnections.EndTurnButton = self._uiElements.ActionButtons.EndTurnButton.MouseButton1Click:Connect(function()
        self:EndTurn()
    end)
    
    -- Leave Battle button
    self._inputConnections.LeaveBattleButton = self._uiElements.ActionButtons.LeaveBattleButton.MouseButton1Click:Connect(function()
        self:LeaveBattle()
    end)
    
    -- Keyboard shortcuts
    self._inputConnections.KeyboardInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            self:EndTurn()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:LeaveBattle()
        end
    end)
end

function BattleController:_setupRemoteHandlers()
    RemoteEventHandler:ConnectRemoteEventClient("BattleUpdate", function(updateData)
        self:_handleBattleUpdate(updateData)
    end)
end

function BattleController:_renderBattleState(session: BattleTypes.BattleSession)
	if not self._uiElements then return end
	
	-- Player stats
	local player = session.Player1
	self._uiElements.PlayerHealth.Text = "❤️ " .. player.Health .. "/" .. player.MaxHealth
	self._uiElements.PlayerEnergy.Text = "⚡ " .. player.Energy .. "/" .. player.MaxEnergy
	self._uiElements.PlayerDeck.Text = "🃏 " .. #player.Deck
	
	-- Opponent stats
	local opponent = session.Player2
	self._uiElements.OpponentHealth.Text = "❤️ " .. opponent.Health .. "/" .. opponent.MaxHealth
	self._uiElements.OpponentEnergy.Text = "⚡ " .. opponent.Energy .. "/" .. opponent.MaxEnergy
	self._uiElements.OpponentDeck.Text = "🃏 " .. #opponent.Deck
	
	-- Render hand
	self:_renderHand(player.Hand)
end

function BattleController:_handleBattleUpdate(updateData: any)
    self:_log("Received battle update: " .. updateData.Type)
    if updateData.Type == "BattleStarted" then
        self:_onBattleStarted(updateData.BattleState)
    elseif updateData.Type == "ActionExecuted" then
        self:_onActionExecuted(updateData.Action, updateData.BattleState)
    elseif updateData.Type == "BattleEnded" then
        self:_onBattleEnded(updateData.Result, updateData.Reason)
    end
end

function BattleController:_onBattleStarted(battleState: BattleSession)
    self:_log("Battle started: " .. battleState.BattleID)
    
    self._currentBattle = battleState
    self._battleState = BATTLE_STATES.ACTIVE
    
    -- Update UI with battle data
    self:_updateBattleUI(battleState)
    
    -- Initialize cards
    self:_initializePlayerCards(battleState)
    
    -- Check if it's our turn
    local player = Players.LocalPlayer
    local isPlayer1 = battleState.Player1.UserID == player.UserId
    self._isMyTurn = (isPlayer1 and battleState.ActivePlayer == 1) or (not isPlayer1 and battleState.ActivePlayer == 2)
    self._canPerformActions = self._isMyTurn
    
    self:_updateActionButtons()
end

function BattleController:_onActionExecuted(action: BattleTypes.BattleAction, battleState: BattleSession)
    self._currentBattle = battleState
    
    -- Play action animation
    if action.ActionType == "PlayCard" then
        self:_handlePlayCardAction(action)
    elseif action.ActionType == "Attack" then
        self:_handleAttackAction(action)
    elseif action.ActionType == "EndTurn" then
        self:_handleEndTurnAction(action, battleState)
    end
    
    -- Update UI
    self:_updateBattleUI(battleState)
end

function BattleController:_onBattleEnded(result: BattleTypes.BattleResult, reason: string)
    self:_log("Battle ended: " .. reason)
    
    -- Show battle results
    self:_showBattleResults(result)
    
    -- Schedule cleanup
    spawn(function()
        wait(5) -- Show results for 5 seconds
        self:_resetBattleState()
    end)
end

function BattleController:_updateBattle(deltaTime: number)
    self._frameTime += deltaTime
    
    if self._battleState ~= BATTLE_STATES.ACTIVE then
        return
    end
    
    -- Update turn timer
    if self._isMyTurn then
        self._turnTimeRemaining -= deltaTime
        if self._turnTimeRemaining <= 0 then
            self._turnTimeRemaining = 0
            -- Auto end turn
            self:EndTurn()
        end
        
        -- Update timer display
        local timerText = self._uiElements.TimerDisplay:FindFirstChild("TimerText")
        if timerText then
            timerText.Text = tostring(math.ceil(self._turnTimeRemaining))
            
            -- Change color based on time remaining
            if self._turnTimeRemaining <= 5 then
                timerText.TextColor3 = Color3.new(1, 0.3, 0.3) -- Red
            elseif self._turnTimeRemaining <= 10 then
                timerText.TextColor3 = Color3.new(1, 1, 0.3) -- Yellow
            else
                timerText.TextColor3 = Color3.new(1, 1, 1) -- White
            end
        end
    end
    
    -- Update animations
    self:_updateActiveAnimations(deltaTime)
end

function BattleController:_updateBattleUI(battleState: BattleSession)
    if not self._uiElements then
        return
    end
    
    local player = Players.LocalPlayer
    local isPlayer1 = battleState.Player1.UserID == player.UserId
    local playerData = isPlayer1 and battleState.Player1 or battleState.Player2
    local opponentData = isPlayer1 and battleState.Player2 or battleState.Player1
    
    -- Update status display
    self:_updateStatusDisplay(playerData, opponentData)
    
    -- Update hand cards
    self:_updateHandCards(playerData.Hand)
    
    -- Update active cards
    self:_updateActiveCards(playerData, opponentData)
end

function BattleController:_updateStatusDisplay(playerData: BattleTypes.BattlePlayer, opponentData: BattleTypes.BattlePlayer)
    local statusDisplay = self._uiElements.StatusDisplay
    
    -- Clear existing elements
    for _, child in ipairs(statusDisplay:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Player health
    local playerHealthLabel = Instance.new("TextLabel")
    playerHealthLabel.Name = "PlayerHealth"
    playerHealthLabel.Size = UDim2.new(1, 0, 0.25, 0)
    playerHealthLabel.Position = UDim2.new(0, 0, 0, 0)
    playerHealthLabel.BackgroundTransparency = 1
    playerHealthLabel.Text = "Your Health: " .. playerData.Health .. "/" .. playerData.MaxHealth
    playerHealthLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
    playerHealthLabel.TextScaled = true
    playerHealthLabel.Font = Enum.Font.SourceSansBold
    playerHealthLabel.Parent = statusDisplay
    
    -- Opponent health
    local opponentHealthLabel = Instance.new("TextLabel")
    opponentHealthLabel.Name = "OpponentHealth"
    opponentHealthLabel.Size = UDim2.new(1, 0, 0.25, 0)
    opponentHealthLabel.Position = UDim2.new(0, 0, 0.25, 0)
    opponentHealthLabel.BackgroundTransparency = 1
    opponentHealthLabel.Text = "Opponent Health: " .. opponentData.Health .. "/" .. opponentData.MaxHealth
    opponentHealthLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
    opponentHealthLabel.TextScaled = true
    opponentHealthLabel.Font = Enum.Font.SourceSansBold
    opponentHealthLabel.Parent = statusDisplay
    
    -- Player energy
    local playerEnergyLabel = Instance.new("TextLabel")
    playerEnergyLabel.Name = "PlayerEnergy"
    playerEnergyLabel.Size = UDim2.new(1, 0, 0.25, 0)
    playerEnergyLabel.Position = UDim2.new(0, 0, 0.5, 0)
    playerEnergyLabel.BackgroundTransparency = 1
    playerEnergyLabel.Text = "Energy: " .. playerData.Energy .. "/" .. playerData.MaxEnergy
    playerEnergyLabel.TextColor3 = Color3.new(0.3, 0.3, 1)
    playerEnergyLabel.TextScaled = true
    playerEnergyLabel.Font = Enum.Font.SourceSansBold
    playerEnergyLabel.Parent = statusDisplay
    
    -- Turn indicator
    local turnLabel = Instance.new("TextLabel")
    turnLabel.Name = "TurnIndicator"
    turnLabel.Size = UDim2.new(1, 0, 0.25, 0)
    turnLabel.Position = UDim2.new(0, 0, 0.75, 0)
    turnLabel.BackgroundTransparency = 1
    turnLabel.Text = self._isMyTurn and "Your Turn" or "Opponent's Turn"
    turnLabel.TextColor3 = self._isMyTurn and Color3.new(1, 1, 0.3) or Color3.new(0.7, 0.7, 0.7)
    turnLabel.TextScaled = true
    turnLabel.Font = Enum.Font.SourceSansBold
    turnLabel.Parent = statusDisplay
end

function BattleController:_updateHandCards(handCards: {BattleTypes.BattleCard})
    -- Clear existing hand cards
    for _, cardUIData in ipairs(self._handCards) do
        cardUIData.Frame:Destroy()
    end
    self._handCards = {}
    
    -- Create new hand cards
    for i, battleCard in ipairs(handCards) do
        local cardUIData = self:_createCardUI(battleCard, i, "Hand")
        table.insert(self._handCards, cardUIData)
        self._cardUIElements[battleCard.InstanceID] = cardUIData
    end
end

function BattleController:_updateActiveCards(playerData: BattleTypes.BattlePlayer, opponentData: BattleTypes.BattlePlayer)
    -- Update player's active card
    if playerData.ActiveCard then
        local existingUI = self._cardUIElements[playerData.ActiveCard.InstanceID]
        if not existingUI then
            local cardUIData = self:_createCardUI(playerData.ActiveCard, 1, "PlayerActive")
            self._cardUIElements[playerData.ActiveCard.InstanceID] = cardUIData
        end
    end
    
    -- Update opponent's active card
    if opponentData.ActiveCard then
        local existingUI = self._cardUIElements[opponentData.ActiveCard.InstanceID]
        if not existingUI then
            local cardUIData = self:_createCardUI(opponentData.ActiveCard, 1, "OpponentActive")
            self._cardUIElements[opponentData.ActiveCard.InstanceID] = cardUIData
        end
    end
end

function BattleController:_createCardUI(battleCard: BattleTypes.BattleCard, index: number, position: string): CardUIData
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "Card_" .. battleCard.InstanceID
    cardFrame.Size = UI_CONFIG.CardSize
    cardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    cardFrame.BorderSizePixel = 2
    cardFrame.BorderColor3 = GameConstants.RarityColors[battleCard.CardData.Rarity] or Color3.new(0.7, 0.7, 0.7)
    cardFrame.ZIndex = 25
    
    -- Position based on location
    if position == "Hand" then
        local spacing = UI_CONFIG.HandSpacing
        local totalWidth = #self._handCards * (UI_CONFIG.CardSize.X.Offset + spacing) - spacing
        local startX = (self._uiElements.HandContainer.AbsoluteSize.X - totalWidth) / 2
        
        cardFrame.Position = UDim2.new(0, startX + (index - 1) * (UI_CONFIG.CardSize.X.Offset + spacing), 0, 10)
        cardFrame.Parent = self._uiElements.HandContainer
    elseif position == "PlayerActive" then
        cardFrame.Position = UDim2.new(0.5, -UI_CONFIG.CardSize.X.Offset / 2, 0.5, -UI_CONFIG.CardSize.Y.Offset / 2)
        cardFrame.Parent = self._uiElements.Player1Area
    elseif position == "OpponentActive" then
        cardFrame.Position = UDim2.new(0.5, -UI_CONFIG.CardSize.X.Offset / 2, 0.5, -UI_CONFIG.CardSize.Y.Offset / 2)
        cardFrame.Parent = self._uiElements.Player2Area
    end
    
    -- Card image
    local cardImage = Instance.new("ImageLabel")
    cardImage.Name = "CardImage"
    cardImage.Size = UDim2.new(1, -10, 0.6, -10)
    cardImage.Position = UDim2.new(0, 5, 0, 5)
    cardImage.BackgroundTransparency = 1
    cardImage.Image = battleCard.CardData.Image or ""
    cardImage.ZIndex = 26
    cardImage.Parent = cardFrame
    
    -- Card name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 5, 0.6, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = battleCard.CardData.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.ZIndex = 27
    nameLabel.Parent = cardFrame
    
    -- Stats display
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -10, 0.25, -5)
    statsFrame.Position = UDim2.new(0, 5, 0.75, 0)
    statsFrame.BackgroundTransparency = 1
    statsFrame.ZIndex = 27
    statsFrame.Parent = cardFrame
    
    -- Attack stat
    local attackLabel = Instance.new("TextLabel")
    attackLabel.Name = "AttackLabel"
    attackLabel.Size = UDim2.new(0.33, 0, 1, 0)
    attackLabel.Position = UDim2.new(0, 0, 0, 0)
    attackLabel.BackgroundTransparency = 1
    attackLabel.Text = tostring(battleCard.Attack)
    attackLabel.TextColor3 = Color3.new(1, 0.6, 0.6)
    attackLabel.TextScaled = true
    attackLabel.Font = Enum.Font.SourceSans
    attackLabel.ZIndex = 28
    attackLabel.Parent = statsFrame
    
    -- Health stat
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(0.33, 0, 1, 0)
    healthLabel.Position = UDim2.new(0.33, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = tostring(battleCard.CurrentHealth)
    healthLabel.TextColor3 = Color3.new(0.6, 1, 0.6)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.ZIndex = 28
    healthLabel.Parent = statsFrame
    
    -- Energy cost
    local energyLabel = Instance.new("TextLabel")
    energyLabel.Name = "EnergyLabel"
    energyLabel.Size = UDim2.new(0.33, 0, 1, 0)
    energyLabel.Position = UDim2.new(0.66, 0, 0, 0)
    energyLabel.BackgroundTransparency = 1
    energyLabel.Text = tostring(battleCard.Energy)
    energyLabel.TextColor3 = Color3.new(0.6, 0.6, 1)
    energyLabel.TextScaled = true
    energyLabel.Font = Enum.Font.SourceSans
    energyLabel.ZIndex = 28
    energyLabel.Parent = statsFrame
    
    -- Click handler for hand cards
    if position == "Hand" then
        local clickDetector = Instance.new("TextButton")
        clickDetector.Name = "ClickDetector"
        clickDetector.Size = UDim2.new(1, 0, 1, 0)
        clickDetector.Position = UDim2.new(0, 0, 0, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text = ""
        clickDetector.ZIndex = 30
        clickDetector.Parent = cardFrame
        
        clickDetector.MouseButton1Click:Connect(function()
            self:SelectCard({
                Frame = cardFrame,
                CardID = battleCard.InstanceID,
                Position = Vector2.new(cardFrame.AbsolutePosition.X, cardFrame.AbsolutePosition.Y),
                IsAnimating = false,
                IsSelected = false,
                IsValidTarget = false,
                EffectContainer = cardFrame
            })
        end)
    end
    
    return {
        Frame = cardFrame,
        CardID = battleCard.InstanceID,
        Position = Vector2.new(cardFrame.AbsolutePosition.X, cardFrame.AbsolutePosition.Y),
        IsAnimating = false,
        IsSelected = false,
        IsValidTarget = false,
        EffectContainer = cardFrame
    }
end

function BattleController:_animateCardPlay(cardUIData: CardUIData, targetPosition: Vector2?)
    local effectsController = self.ServiceRegistry:GetService("EffectsController")
    
    -- Play card animation
    local playAnimation = TweenService:Create(cardUIData.Frame, TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -UI_CONFIG.CardSize.X.Offset / 2, 0.5, -UI_CONFIG.CardSize.Y.Offset / 2)
    })
    
    playAnimation:Play()
    
    -- Play effects
    if effectsController then
        effectsController:PlayCardRevealEffects({
            Card = { Name = "Card Play" },
            Rarity = "Common",
            EffectIntensity = 0.6,
            IsPityResult = false
        }, cardUIData.EffectContainer)
    end
    
    playAnimation.Completed:Connect(function()
        cardUIData.IsAnimating = false
    end)
    
    cardUIData.IsAnimating = true
end

function BattleController:_animateAttack(attackerCardUIData: CardUIData, targetCardUIData: CardUIData?)
    local effectsController = self.ServiceRegistry:GetService("EffectsController")
    
    -- Attack animation with impact frames
    local originalPosition = attackerCardUIData.Frame.Position
    local targetPosition = targetCardUIData and targetCardUIData.Frame.Position or UDim2.new(0.5, 0, 0.3, 0)
    
    -- Move toward target
    local attackMove = TweenService:Create(attackerCardUIData.Frame, TweenInfo.new(UI_CONFIG.ImpactFrameDelay, Enum.EasingStyle.Quad), {
        Position = UDim2.new(targetPosition.X.Scale * 0.8, targetPosition.X.Offset * 0.8, targetPosition.Y.Scale * 0.8, targetPosition.Y.Offset * 0.8)
    })
    
    attackMove:Play()
    
    attackMove.Completed:Connect(function()
        -- Impact frame pause
        wait(UI_CONFIG.ImpactFrameDelay / 3)
        
        -- Screen shake and effects
        if effectsController then
            effectsController:TriggerScreenShake(UI_CONFIG.ScreenShakeIntensity, 0.3)
            
            -- Play impact effects
            effectsController:PlayScreenFlash(Color3.new(1, 1, 0.8), 0.5, 0.2)
        end
        
        -- Return to original position
        local returnMove = TweenService:Create(attackerCardUIData.Frame, TweenInfo.new(UI_CONFIG.AnimationDuration / 2, Enum.EasingStyle.Quad), {
            Position = originalPosition
        })
        
        returnMove:Play()
        returnMove.Completed:Connect(function()
            attackerCardUIData.IsAnimating = false
        end)
    end)
    
    attackerCardUIData.IsAnimating = true
end

function BattleController:_handlePlayCardAction(action: BattleTypes.BattleAction)
    local cardID = action.ActionData.SourceCardID
    local cardUIData = self._cardUIElements[cardID]
    
    if cardUIData then
        self:_animateCardPlay(cardUIData)
    end
end

function BattleController:_handleAttackAction(action: BattleTypes.BattleAction)
    local attackerID = action.ActionData.SourceCardID
    local targetID = action.ActionData.TargetCardID
    
    local attackerUI = self._cardUIElements[attackerID]
    local targetUI = targetID and self._cardUIElements[targetID] or nil
    
    if attackerUI then
        self:_animateAttack(attackerUI, targetUI)
    end
end

function BattleController:_handleEndTurnAction(action: BattleTypes.BattleAction, battleState: BattleSession)
    local player = Players.LocalPlayer
    local isPlayer1 = battleState.Player1.UserID == player.UserId
    self._isMyTurn = (isPlayer1 and battleState.ActivePlayer == 1) or (not isPlayer1 and battleState.ActivePlayer == 2)
    self._canPerformActions = self._isMyTurn
    
    -- Reset turn timer
    self._turnTimeRemaining = 30
    
    self:_updateActionButtons()
end

function BattleController:_updateActionButtons()
    local endTurnButton = self._uiElements.ActionButtons.EndTurnButton
    endTurnButton.BackgroundTransparency = self._canPerformActions and 0 or 0.5
    endTurnButton.TextTransparency = self._canPerformActions and 0 or 0.5
end

function BattleController:_updateCardSelection(cardUIData: CardUIData, isSelected: boolean)
    cardUIData.IsSelected = isSelected
    
    local selectionFrame = cardUIData.Frame:FindFirstChild("Selection")
    if isSelected then
        if not selectionFrame then
            selectionFrame = Instance.new("Frame")
            selectionFrame.Name = "Selection"
            selectionFrame.Size = UDim2.new(1, 6, 1, 6)
            selectionFrame.Position = UDim2.new(0, -3, 0, -3)
            selectionFrame.BackgroundColor3 = Color3.new(1, 1, 0)
            selectionFrame.BackgroundTransparency = 0.5
            selectionFrame.ZIndex = cardUIData.Frame.ZIndex - 1
            selectionFrame.Parent = cardUIData.Frame
        end
    else
        if selectionFrame then
            selectionFrame:Destroy()
        end
    end
end

function BattleController:_updateValidTargets(selectedCard: CardUIData)
    -- Clear previous valid targets
    for _, cardUIData in pairs(self._cardUIElements) do
        cardUIData.IsValidTarget = false
        local targetFrame = cardUIData.Frame:FindFirstChild("ValidTarget")
        if targetFrame then
            targetFrame:Destroy()
        end
    end
    
    -- Set new valid targets (simplified logic)
    self._validTargets = {}
    
    -- For now, all opponent cards are valid targets
    for _, cardUIData in pairs(self._cardUIElements) do
        if cardUIData.Frame.Parent == self._uiElements.Player2Area then
            cardUIData.IsValidTarget = true
            table.insert(self._validTargets, cardUIData)
            
            -- Add visual indicator
            local targetFrame = Instance.new("Frame")
            targetFrame.Name = "ValidTarget"
            targetFrame.Size = UDim2.new(1, 4, 1, 4)
            targetFrame.Position = UDim2.new(0, -2, 0, -2)
            targetFrame.BackgroundColor3 = Color3.new(0, 1, 0)
            targetFrame.BackgroundTransparency = 0.7
            targetFrame.ZIndex = cardUIData.Frame.ZIndex - 1
            targetFrame.Parent = cardUIData.Frame
        end
    end
end

function BattleController:_updateActiveAnimations(deltaTime: number)
    self._animationCount = 0
    
    for animationID, animation in pairs(self._activeAnimations) do
        animation.Duration -= deltaTime
        
        if animation.Duration <= 0 then
            -- Animation finished
            if animation.OnComplete then
                animation.OnComplete()
            end
            self._activeAnimations[animationID] = nil
        else
            self._animationCount += 1
        end
    end
end

function BattleController:_showBattleResults(result: BattleTypes.BattleResult)
    local player = Players.LocalPlayer
    local isWinner = (result.Winner == 1 and result.Player1Stats) or (result.Winner == 2 and result.Player2Stats)
    
    -- Create results UI
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "BattleResults"
    resultsFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
    resultsFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
    resultsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    resultsFrame.BackgroundTransparency = 0.2
    resultsFrame.ZIndex = 200
    resultsFrame.Parent = self._uiElements.MainFrame
    
    -- Results text
    local resultsText = Instance.new("TextLabel")
    resultsText.Name = "ResultsText"
    resultsText.Size = UDim2.new(1, 0, 0.5, 0)
    resultsText.Position = UDim2.new(0, 0, 0, 0)
    resultsText.BackgroundTransparency = 1
    resultsText.Text = result.Winner and (isWinner and "Victory!" or "Defeat!") or "Draw!"
    resultsText.TextColor3 = result.Winner and (isWinner and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)) or Color3.new(1, 1, 0)
    resultsText.TextScaled = true
    resultsText.Font = Enum.Font.SourceSansBold
    resultsText.ZIndex = 201
    resultsText.Parent = resultsFrame
    
    self._uiState.ShowingResults = true
end

function BattleController:_resetBattleState()
    self._battleState = BATTLE_STATES.INACTIVE
    self._currentBattle = nil
    self._uiState = nil
    
    -- Clear card UI
    for _, cardUIData in pairs(self._cardUIElements) do
        cardUIData.Frame:Destroy()
    end
    self._cardUIElements = {}
    self._handCards = {}
    
    -- Hide UI
    if self._uiElements then
        self._uiElements.MainFrame.Enabled = false
    end
    
    self:_log("Battle state reset")
end

function BattleController:_canPerformAction(): boolean
    return self._battleState == BATTLE_STATES.ACTIVE and 
           self._canPerformActions and 
           not self._uiState.UILocked and 
           self._uiState.AnimationsPlaying == 0
end

function BattleController:_cleanupInputHandlers()
    for _, connection in pairs(self._inputConnections) do
        connection:Disconnect()
    end
    self._inputConnections = {}
end

return BattleController.new() 