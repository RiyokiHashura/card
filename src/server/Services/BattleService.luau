--!strict
-- BattleService.luau
-- Server-side battle system with elevated 2D combat mechanics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local BattleTypes = require(ReplicatedStorage.Shared.Types.BattleTypes)
local CardTypes = require(ReplicatedStorage.Shared.Types.CardTypes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local RemoteEventHandler = require(ReplicatedStorage.Shared.Core.RemoteEventHandler)
local CardDatabase = require(ReplicatedStorage.Shared.Data.CardDatabase)
local TableUtils = require(ReplicatedStorage.Shared.Utils.TableUtils)

type BattleSession = BattleTypes.BattleSession
type BattlePlayer = BattleTypes.BattlePlayer
type BattleCard = BattleTypes.BattleCard
type BattleAction = BattleTypes.BattleAction
type BattleServiceResponse<T> = BattleTypes.BattleServiceResponse<T>
type DamageCalculation = BattleTypes.DamageCalculation
type AIOpponent = BattleTypes.AIOpponent

local BattleService = {}
BattleService.__index = BattleService
setmetatable(BattleService, {__index = BaseService})

-- Battle Configuration
local BATTLE_CONFIG = {
    DefaultTurnTime = 30, -- seconds
    MaxBattleDuration = 1800, -- 30 minutes
    StartingHealth = 100,
    StartingEnergy = 3,
    MaxEnergy = 10,
    HandSize = 5,
    DeckSize = 20,
    ImpactFrameDuration = 6, -- frames
    CriticalChance = 0.1,
    CriticalMultiplier = 1.5
}

-- AI Personalities
local AI_PERSONALITIES = {
    Easy = {
        Aggression = 0.3,
        Defense = 0.7,
        RiskTaking = 0.2,
        Patience = 0.8,
        Adaptability = 0.3
    },
    Medium = {
        Aggression = 0.5,
        Defense = 0.5,
        RiskTaking = 0.4,
        Patience = 0.6,
        Adaptability = 0.5
    },
    Hard = {
        Aggression = 0.7,
        Defense = 0.4,
        RiskTaking = 0.6,
        Patience = 0.4,
        Adaptability = 0.7
    },
    Expert = {
        Aggression = 0.8,
        Defense = 0.6,
        RiskTaking = 0.7,
        Patience = 0.3,
        Adaptability = 0.9
    },
    Master = {
        Aggression = 0.9,
        Defense = 0.8,
        RiskTaking = 0.8,
        Patience = 0.2,
        Adaptability = 1.0
    }
}

function BattleService.new()
    	local self = BaseService.new("BattleService", {"PlayerDataService"})
    setmetatable(self, BattleService)
    
    -- Battle tracking
    self._activeBattles = {} :: {[string]: BattleSession}
    self._playerBattles = {} :: {[number]: string} -- UserID -> BattleID
    self._battleQueue = {} :: {BattleTypes.MatchmakingRequest}
    
    -- AI opponents
    self._aiOpponents = {} :: {[string]: AIOpponent}
    
    -- Performance tracking
    self._battlesCompleted = 0
    self._averageBattleDuration = 0
    self._activePlayerCount = 0
    
    -- Turn processing
    self._turnTimers = {} :: {[string]: number}
    
    return self
end

function BattleService:Initialize()
    self:_log("BattleService initializing...")
    
    -- Initialize AI opponents
    self:_initializeAIOpponents()
    
    -- Setup remote event handlers
    self:_setupRemoteHandlers()
    
    -- Start battle processing
    self._battleProcessingConnection = RunService.Heartbeat:Connect(function()
        self:_processBattleUpdates()
    end)
    
    self:_log("BattleService initialized successfully")
end

function BattleService:Start()
    self:_log("BattleService starting...")
    
    -- Start matchmaking processing
    self:_startMatchmakingProcessor()
    
    self:_log("BattleService started successfully")
end

function BattleService:Stop()
    self:_log("BattleService stopping...")
    
    -- End all active battles
    for battleID, battle in pairs(self._activeBattles) do
        self:EndBattle(battleID, "ServerShutdown")
    end
    
    -- Clean up connections
    if self._battleProcessingConnection then
        self._battleProcessingConnection:Disconnect()
    end
    
    self:_log("BattleService stopped")
end

-- Public Methods

function BattleService:StartBattle(player: Player, request: BattleTypes.StartBattleRequest): BattleServiceResponse<BattleSession>
    local startTime = os.clock()
    local battleID = self:_generateBattleID()
    
    self:_log("Creating battle: " .. battleID .. " for " .. player.Name)
    
    -- Get player data
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    local playerData = playerDataService:GetPlayerData(player)
    
    if not playerData then
        return {
            Success = false,
            ErrorMessage = "Player data not available",
            ProcessingTime = (os.clock() - startTime) * 1000,
            BattleID = battleID,
        }
    end
    
    -- Create battle players
    local battlePlayer1 = self:_createBattlePlayer(player, playerData)
    local battlePlayer2: BattlePlayer
    
    if request.BattleType == "PVE" then
        -- AI battle
        local opponentID = request.OpponentId or "AI_EASY_01"
        battlePlayer2 = self:_createAIBattlePlayer(opponentID)
    else
        -- PvP battle (not implemented)
        return {
            Success = false,
            ErrorMessage = "PvP battles are not yet implemented.",
            ProcessingTime = (os.clock() - startTime) * 1000,
            BattleID = battleID,
        }
    end
    
    -- Create battle session
    local battleSession: BattleSession = {
        BattleID = battleID,
        Player1 = battlePlayer1,
        Player2 = battlePlayer2,
        CurrentTurn = 1,
        ActivePlayer = 1,
        BattleState = "Starting",
        TurnTimer = BATTLE_CONFIG.DefaultTurnTime,
        BattleStartTime = os.time(),
        BattleEndTime = nil,
        Winner = nil,
        BattleType = request.BattleType,
        Spectators = {},
        BattleSettings = self:_getDefaultBattleSettings()
    }
    
    -- Store battle
    self._activeBattles[battleID] = battleSession
    self._playerBattles[player.UserId] = battleID
    
    -- Start battle
    self:_startBattle(battleSession)
    
    return {
        Success = true,
        Data = battleSession,
        ProcessingTime = (os.clock() - startTime) * 1000,
        BattleID = battleID,
    }
end

function BattleService:ProcessAction(player: Player, action: BattleAction): BattleServiceResponse<boolean>
    local startTime = os.clock()
    local battleID = self._playerBattles[player.UserId]
    
    if not battleID then
        return {
            Success = false,
            ErrorMessage = "Player not in battle",
            ProcessingTime = (os.clock() - startTime) * 1000
        }
    end
    
    local battle = self._activeBattles[battleID]
    if not battle then
        return {
            Success = false,
            ErrorMessage = "Battle not found",
            ProcessingTime = (os.clock() - startTime) * 1000,
            BattleID = battleID
        }
    end
    
    -- Validate action
    local validation = self:_validateAction(battle, player, action)
    if not validation.IsValid then
        return {
            Success = false,
            ErrorMessage = validation.ErrorReason or "Invalid action",
            ProcessingTime = (os.clock() - startTime) * 1000,
            BattleID = battleID
        }
    end
    
    -- Process action
    local success = self:_executeAction(battle, action)
    
    if success then
        -- Broadcast action to clients
        self:_broadcastBattleUpdate(battle, {
            Type = "ActionExecuted",
            Action = action,
            BattleState = battle
        })
        
        -- Check for battle end conditions
        self:_checkBattleEndConditions(battle)
    end
    
    return {
        Success = success,
        Data = success,
        ProcessingTime = (os.clock() - startTime) * 1000,
        BattleID = battleID
    }
end

function BattleService:GetBattleState(player: Player): BattleServiceResponse<BattleSession>
    local battleID = self._playerBattles[player.UserId]
    
    if not battleID then
        return {
            Success = false,
            ErrorMessage = "Player not in battle",
            ProcessingTime = 0
        }
    end
    
    local battle = self._activeBattles[battleID]
    if not battle then
        return {
            Success = false,
            ErrorMessage = "Battle not found",
            ProcessingTime = 0,
            BattleID = battleID
        }
    end
    
    return {
        Success = true,
        Data = battle,
        ProcessingTime = 0,
        BattleID = battleID
    }
end

function BattleService:EndBattle(battleID: string, reason: string): boolean
    local battle = self._activeBattles[battleID]
    if not battle then
        return false
    end
    
    self:_log("Ending battle: " .. battleID .. " - " .. reason)
    
    -- Calculate battle results
    local battleResult = self:_calculateBattleResult(battle)
    
    -- Update player statistics
    self:_updatePlayerBattleStats(battle, battleResult)
    
    -- Clean up battle
    battle.BattleState = "Finished"
    battle.BattleEndTime = os.time()
    
    -- Remove from tracking
    self._activeBattles[battleID] = nil
    self._playerBattles[battle.Player1.UserID] = nil
    if battle.Player2.UserID > 0 then -- Not AI
        self._playerBattles[battle.Player2.UserID] = nil
    end
    
    -- Broadcast battle end
    self:_broadcastBattleUpdate(battle, {
        Type = "BattleEnded",
        Result = battleResult,
        Reason = reason
    })
    
    self._battlesCompleted += 1
    return true
end

function BattleService:GetActiveBattleCount(): number
    local count = 0
    for _ in pairs(self._activeBattles) do
        count += 1
    end
    return count
end

function BattleService:GetBattleStatistics(): {[string]: any}
    return {
        ActiveBattles = self:GetActiveBattleCount(),
        BattlesCompleted = self._battlesCompleted,
        AverageBattleDuration = self._averageBattleDuration,
        ActivePlayerCount = self._activePlayerCount,
        QueueSize = #self._battleQueue
    }
end

-- Private Methods

function BattleService:_createBattlePlayer(player: Player, playerData: PlayerTypes.PlayerData): BattlePlayer
    -- Get player's deck from collection
    local deck = self:_buildDeckFromCollection(playerData)
    
    return {
        UserID = player.UserId,
        Username = player.Name,
        Deck = deck,
        Hand = {},
        ActiveCard = nil,
        Health = BATTLE_CONFIG.StartingHealth,
        MaxHealth = BATTLE_CONFIG.StartingHealth,
        Energy = BATTLE_CONFIG.StartingEnergy,
        MaxEnergy = BATTLE_CONFIG.MaxEnergy,
        Shield = 0,
        StatusEffects = {},
        IsReady = false,
        LastActionTime = os.time(),
        BattleStats = self:_createEmptyBattleStats()
    }
end

function BattleService:_createAIBattlePlayer(battleType: BattleTypes.BattleType): BattlePlayer
    local difficulty = battleType == "Practice" and "Easy" or "Medium"
    local aiOpponent = self._aiOpponents[difficulty] or self._aiOpponents["Easy"]
    
    local aiDeck = self:_buildAIDeck(aiOpponent)
    
    return {
        UserID = -1, -- AI identifier
        Username = aiOpponent.Name,
        Deck = aiDeck,
        Hand = {},
        ActiveCard = nil,
        Health = BATTLE_CONFIG.StartingHealth,
        MaxHealth = BATTLE_CONFIG.StartingHealth,
        Energy = BATTLE_CONFIG.StartingEnergy,
        MaxEnergy = BATTLE_CONFIG.MaxEnergy,
        Shield = 0,
        StatusEffects = {},
        IsReady = true,
        LastActionTime = os.time(),
        BattleStats = self:_createEmptyBattleStats()
    }
end

function BattleService:_buildDeckFromCollection(playerData: PlayerTypes.PlayerData): {BattleCard}
    local deck = {}
    local cardDatabase = CardDatabase
    
    -- Use player's current deck or create a basic deck
    local deckCardIDs = playerData.Progression.CurrentDeck
    if #deckCardIDs == 0 then
        -- Create basic deck from owned cards
        deckCardIDs = self:_createBasicDeck(playerData.Collection)
    end
    
    for i, cardID in ipairs(deckCardIDs) do
        if i <= BATTLE_CONFIG.DeckSize then
            local cardData = cardDatabase:GetCard(cardID)
            if cardData then
                table.insert(deck, self:_createBattleCard(cardData))
            end
        end
    end
    
    return deck
end

function BattleService:_buildAIDeck(aiOpponent: AIOpponent): {BattleCard}
    local deck = {}
    
    for _, cardData in ipairs(aiOpponent.Deck) do
        table.insert(deck, self:_createBattleCard(cardData))
    end
    
    return deck
end

function BattleService:_createBattleCard(cardData: CardTypes.CardData): BattleCard
    return {
        InstanceID = HttpService:GenerateGUID(false),
        CardData = cardData,
        CurrentHealth = cardData.Health,
        MaxHealth = cardData.Health,
        Attack = cardData.Attack,
        Defense = cardData.Defense,
        Energy = cardData.Cost,
        StatusEffects = {},
        Position = "Deck",
        CanAttack = false,
        TurnsOnField = 0,
        DamageDealt = 0,
        DamageTaken = 0
    }
end

function BattleService:_startBattle(battle: BattleSession)
    battle.BattleState = "InProgress"
    
    -- Draw initial hands
    self:_drawInitialHands(battle)
    
    -- Start first turn
    self:_startTurn(battle)
    
    -- Broadcast battle start
    self:_broadcastBattleUpdate(battle, {
        Type = "BattleStarted",
        BattleState = battle
    })
    
    self:_log("Battle started: " .. battle.BattleID)
end

function BattleService:_drawInitialHands(battle: BattleSession)
    -- Draw cards for both players
    self:_drawCards(battle.Player1, BATTLE_CONFIG.HandSize)
    self:_drawCards(battle.Player2, BATTLE_CONFIG.HandSize)
end

function BattleService:_drawCards(player: BattlePlayer, count: number)
    for i = 1, count do
        if #player.Deck > 0 then
            local card = table.remove(player.Deck, 1)
            card.Position = "Hand"
            table.insert(player.Hand, card)
        end
    end
end

function BattleService:_startTurn(battle: BattleSession)
    local activePlayer = battle.ActivePlayer == 1 and battle.Player1 or battle.Player2
    
    -- Reset energy
    activePlayer.Energy = math.min(activePlayer.MaxEnergy, activePlayer.Energy + 1)
    
    -- Draw a card
    self:_drawCards(activePlayer, 1)
    
    -- Reset card attack status
    for _, card in ipairs(activePlayer.Hand) do
        if card.Position == "Active" then
            card.CanAttack = true
        end
    end
    
    -- Update turn timer
    self._turnTimers[battle.BattleID] = os.time() + BATTLE_CONFIG.DefaultTurnTime
    
    -- Process AI turn if needed
    if activePlayer.UserID == -1 then
        spawn(function()
            wait(math.random(1, 3)) -- AI thinking time
            self:_processAITurn(battle, activePlayer)
        end)
    end
    
    self:_log("Turn " .. battle.CurrentTurn .. " started for player " .. battle.ActivePlayer)
end

function BattleService:_validateAction(battle: BattleSession, player: Player, action: BattleAction): BattleTypes.ActionValidationResult
    -- Check if it's player's turn
    local activePlayer = battle.ActivePlayer == 1 and battle.Player1 or battle.Player2
    if activePlayer.UserID ~= player.UserId then
        return {
            IsValid = false,
            ErrorReason = "Not your turn"
        }
    end
    
    -- Check battle state
    if battle.BattleState ~= "InProgress" then
        return {
            IsValid = false,
            ErrorReason = "Battle not in progress"
        }
    end
    
    -- Validate specific action types
    if action.ActionType == "PlayCard" then
        return self:_validatePlayCardAction(activePlayer, action)
    elseif action.ActionType == "Attack" then
        return self:_validateAttackAction(battle, activePlayer, action)
    elseif action.ActionType == "EndTurn" then
        return { IsValid = true }
    elseif action.ActionType == "Surrender" then
        return { IsValid = true }
    end
    
    return {
        IsValid = false,
        ErrorReason = "Unknown action type"
    }
end

function BattleService:_validatePlayCardAction(player: BattlePlayer, action: BattleAction): BattleTypes.ActionValidationResult
    local cardID = action.ActionData.SourceCardID
    if not cardID then
        return {
            IsValid = false,
            ErrorReason = "No card specified"
        }
    end
    
    -- Find card in hand
    local card = nil
    for _, handCard in ipairs(player.Hand) do
        if handCard.InstanceID == cardID then
            card = handCard
            break
        end
    end
    
    if not card then
        return {
            IsValid = false,
            ErrorReason = "Card not in hand"
        }
    end
    
    -- Check energy cost
    if player.Energy < card.Energy then
        return {
            IsValid = false,
            ErrorReason = "Not enough energy"
        }
    end
    
    return { IsValid = true }
end

function BattleService:_validateAttackAction(battle: BattleSession, attacker: BattlePlayer, action: BattleAction): BattleTypes.ActionValidationResult
    local sourceCardID = action.ActionData.SourceCardID
    local targetCardID = action.ActionData.TargetCardID
    
    if not sourceCardID then
        return {
            IsValid = false,
            ErrorReason = "No attacking card specified"
        }
    end
    
    -- Find attacking card
    local attackingCard = nil
    if attacker.ActiveCard and attacker.ActiveCard.InstanceID == sourceCardID then
        attackingCard = attacker.ActiveCard
    end
    
    if not attackingCard then
        return {
            IsValid = false,
            ErrorReason = "Attacking card not active"
        }
    end
    
    -- Check if card can attack
    if not attackingCard.CanAttack then
        return {
            IsValid = false,
            ErrorReason = "Card cannot attack this turn"
        }
    end
    
    return { IsValid = true }
end

function BattleService:_executeAction(battle: BattleSession, action: BattleAction): boolean
    local activePlayer = battle.ActivePlayer == 1 and battle.Player1 or battle.Player2
    
    if action.ActionType == "PlayCard" then
        return self:_executePlayCard(battle, activePlayer, action)
    elseif action.ActionType == "Attack" then
        return self:_executeAttack(battle, activePlayer, action)
    elseif action.ActionType == "EndTurn" then
        return self:_executeEndTurn(battle)
    elseif action.ActionType == "Surrender" then
        return self:_executeSurrender(battle, activePlayer)
    end
    
    return false
end

function BattleService:_executePlayCard(battle: BattleSession, player: BattlePlayer, action: BattleAction): boolean
    local cardID = action.ActionData.SourceCardID
    
    -- Find and remove card from hand
    local cardIndex = nil
    local card = nil
    for i, handCard in ipairs(player.Hand) do
        if handCard.InstanceID == cardID then
            card = handCard
            cardIndex = i
            break
        end
    end
    
    if not card or not cardIndex then
        return false
    end
    
    -- Remove from hand and pay energy cost
    table.remove(player.Hand, cardIndex)
    player.Energy -= card.Energy
    
    -- Place card in active position
    if player.ActiveCard then
        -- Move current active card to graveyard
        player.ActiveCard.Position = "Graveyard"
    end
    
    card.Position = "Active"
    card.CanAttack = false -- Can't attack on play turn
    player.ActiveCard = card
    
    -- Update stats
    player.BattleStats.CardsPlayed += 1
    
    self:_log("Player " .. player.Username .. " played card: " .. card.CardData.Name)
    return true
end

function BattleService:_executeAttack(battle: BattleSession, attacker: BattlePlayer, action: BattleAction): boolean
    local defender = battle.ActivePlayer == 1 and battle.Player2 or battle.Player1
    local attackingCard = attacker.ActiveCard
    
    if not attackingCard then
        return false
    end
    
    -- Calculate damage
    local damageCalc = self:_calculateDamage(attackingCard, defender.ActiveCard or nil, attacker, defender)
    
    -- Apply damage
    local target = action.ActionData.TargetCardID and defender.ActiveCard or defender
    local actualDamage = self:_applyDamage(target, damageCalc, attacker, defender)
    
    -- Update stats
    attacker.BattleStats.DamageDealt += actualDamage
    if damageCalc.IsCritical then
        attacker.BattleStats.CriticalHits += 1
    end
    
    if target == defender then
        defender.BattleStats.DamageTaken += actualDamage
    end
    
    -- Mark card as unable to attack
    attackingCard.CanAttack = false
    attackingCard.DamageDealt += actualDamage
    
    -- Generate visual effects data
    action.VisualEffects = self:_generateAttackEffects(attackingCard, target, damageCalc)
    
    self:_log("Attack: " .. attackingCard.CardData.Name .. " -> " .. actualDamage .. " damage")
    return true
end

function BattleService:_executeEndTurn(battle: BattleSession): boolean
    -- Switch active player
    battle.ActivePlayer = battle.ActivePlayer == 1 and 2 or 1
    battle.CurrentTurn += 1
    
    -- Start next turn
    self:_startTurn(battle)
    
    return true
end

function BattleService:_executeSurrender(battle: BattleSession, player: BattlePlayer): boolean
    battle.Winner = battle.ActivePlayer == 1 and 2 or 1
    self:EndBattle(battle.BattleID, "Surrender")
    return true
end

function BattleService:_calculateDamage(attackingCard: BattleCard, defendingCard: BattleCard?, attacker: BattlePlayer, defender: BattlePlayer): DamageCalculation
    local baseAttack = attackingCard.Attack
    local baseDamage = baseAttack
    
    -- Apply attack modifiers
    local attackModifiers = {}
    for _, effect in ipairs(attackingCard.StatusEffects) do
        if effect.StatModifiers then
            for _, modifier in ipairs(effect.StatModifiers) do
                if modifier.StatName == "Attack" then
                    table.insert(attackModifiers, {
                        ModifierType = "StatusEffect",
                        Value = modifier.Value,
                        Source = effect.EffectType,
                        Duration = effect.Duration
                    })
                end
            end
        end
    end
    
    -- Apply defense modifiers
    local defenseModifiers = {}
    local targetDefense = 0
    
    if defendingCard then
        targetDefense = defendingCard.Defense
        -- Add defending card's defense modifiers
    else
        targetDefense = defender.Shield
    end
    
    -- Calculate final damage
    local modifiedAttack = baseDamage
    for _, modifier in ipairs(attackModifiers) do
        if modifier.ModifierType == "StatusEffect" then
            modifiedAttack += modifier.Value
        end
    end
    
    local finalDamage = math.max(1, modifiedAttack - targetDefense)
    
    -- Check for critical hit
    local isCritical = math.random() < BATTLE_CONFIG.CriticalChance
    local criticalMultiplier = 1.0
    
    if isCritical then
        criticalMultiplier = BATTLE_CONFIG.CriticalMultiplier
        finalDamage = math.floor(finalDamage * criticalMultiplier)
    end
    
    return {
        BaseAttack = baseAttack,
        BaseDamage = baseDamage,
        AttackModifiers = attackModifiers,
        DefenseModifiers = defenseModifiers,
        FinalDamage = finalDamage,
        IsCritical = isCritical,
        CriticalMultiplier = criticalMultiplier,
        DamageType = "Physical",
        Penetration = 0,
        MitigatedDamage = math.max(0, modifiedAttack - finalDamage)
    }
end

function BattleService:_applyDamage(target: any, damageCalc: DamageCalculation, attacker: BattlePlayer, defender: BattlePlayer): number
    local damage = damageCalc.FinalDamage
    
    if target == defender then
        -- Damage to player
        defender.Health = math.max(0, defender.Health - damage)
    else
        -- Damage to card
        local card = target :: BattleCard
        card.CurrentHealth = math.max(0, card.CurrentHealth - damage)
        card.DamageTaken += damage
        
        -- Check if card is destroyed
        if card.CurrentHealth <= 0 then
            self:_destroyCard(defender, card)
        end
    end
    
    return damage
end

function BattleService:_destroyCard(player: BattlePlayer, card: BattleCard)
    if player.ActiveCard == card then
        player.ActiveCard = nil
    end
    
    card.Position = "Graveyard"
    self:_log("Card destroyed: " .. card.CardData.Name)
end

function BattleService:_generateAttackEffects(attackingCard: BattleCard, target: any, damageCalc: DamageCalculation): {BattleTypes.VisualActionEffect}
    local effects = {}
    
    -- Base attack effect
    table.insert(effects, {
        EffectType = "Attack",
        SourcePosition = Vector2.new(0, 0), -- Will be set by client
        TargetPosition = Vector2.new(0, 0), -- Will be set by client
        Duration = 0.8,
        Intensity = damageCalc.IsCritical and 1.0 or 0.6,
        Properties = {
            ImpactFrames = BATTLE_CONFIG.ImpactFrameDuration,
            ScreenShake = damageCalc.IsCritical and 0.5 or 0.2,
            CriticalHit = damageCalc.IsCritical,
            Damage = damageCalc.FinalDamage
        }
    })
    
    return effects
end

function BattleService:_checkBattleEndConditions(battle: BattleSession)
    -- Check for player defeat
    if battle.Player1.Health <= 0 then
        battle.Winner = 2
        self:EndBattle(battle.BattleID, "Player1Defeated")
    elseif battle.Player2.Health <= 0 then
        battle.Winner = 1
        self:EndBattle(battle.BattleID, "Player2Defeated")
    end
    
    -- Check for turn limit
    if battle.CurrentTurn > 50 then -- Max turns
        battle.Winner = battle.Player1.Health > battle.Player2.Health and 1 or 2
        self:EndBattle(battle.BattleID, "TurnLimit")
    end
end

function BattleService:_processAITurn(battle: BattleSession, aiPlayer: BattlePlayer)
    local aiOpponent = self._aiOpponents["Medium"] -- Default AI
    local actions = self:_generateAIActions(battle, aiPlayer, aiOpponent)
    
    for _, action in ipairs(actions) do
        wait(0.5) -- Delay between AI actions
        
        if battle.BattleState == "InProgress" then
            action.PlayerID = aiPlayer.UserID
            action.Timestamp = os.time()
            action.IsValid = true
            
            self:_executeAction(battle, action)
            
            -- Broadcast AI action
            self:_broadcastBattleUpdate(battle, {
                Type = "ActionExecuted",
                Action = action,
                BattleState = battle
            })
        end
    end
    
    -- End AI turn
    if battle.BattleState == "InProgress" then
        local endTurnAction = {
            ActionID = HttpService:GenerateGUID(false),
            PlayerID = aiPlayer.UserID,
            ActionType = "EndTurn",
            ActionData = {},
            Timestamp = os.time(),
            IsValid = true
        }
        
        self:_executeAction(battle, endTurnAction)
    end
end

function BattleService:_generateAIActions(battle: BattleSession, aiPlayer: BattlePlayer, aiOpponent: AIOpponent): {BattleAction}
    local actions = {}
    
    -- Simple AI logic: play a card if possible, then attack if possible
    if #aiPlayer.Hand > 0 and aiPlayer.Energy >= aiPlayer.Hand[1].Energy then
        -- Play first affordable card
        table.insert(actions, {
            ActionID = HttpService:GenerateGUID(false),
            PlayerID = aiPlayer.UserID,
            ActionType = "PlayCard",
            ActionData = {
                SourceCardID = aiPlayer.Hand[1].InstanceID
            },
            Timestamp = os.time(),
            IsValid = true
        })
    end
    
    -- Attack if we have an active card
    if aiPlayer.ActiveCard and aiPlayer.ActiveCard.CanAttack then
        table.insert(actions, {
            ActionID = HttpService:GenerateGUID(false),
            PlayerID = aiPlayer.UserID,
            ActionType = "Attack",
            ActionData = {
                SourceCardID = aiPlayer.ActiveCard.InstanceID
            },
            Timestamp = os.time(),
            IsValid = true
        })
    end
    
    return actions
end

function BattleService:_calculateBattleResult(battle: BattleSession): BattleTypes.BattleResult
    local duration = os.time() - battle.BattleStartTime
    
    return {
        BattleID = battle.BattleID,
        Winner = battle.Winner,
        Loser = battle.Winner and (battle.Winner == 1 and 2 or 1) or nil,
        BattleDuration = duration,
        TotalTurns = battle.CurrentTurn,
        Player1Stats = battle.Player1.BattleStats,
        Player2Stats = battle.Player2.BattleStats,
        ExperienceGained = {
            [battle.Player1.UserID] = battle.Winner == 1 and 100 or 50,
            [battle.Player2.UserID] = battle.Player2.UserID > 0 and (battle.Winner == 2 and 100 or 50) or 0
        },
        RewardsEarned = {
            [battle.Player1.UserID] = {
                Coins = battle.Winner == 1 and 200 or 50,
                Experience = battle.Winner == 1 and 100 or 50
            },
            [battle.Player2.UserID] = battle.Player2.UserID > 0 and {
                Coins = battle.Winner == 2 and 200 or 50,
                Experience = battle.Winner == 2 and 100 or 50
            } or nil
        }
    }
end

function BattleService:_updatePlayerBattleStats(battle: BattleSession, result: BattleTypes.BattleResult)
    local playerDataService = self.ServiceRegistry:GetService("PlayerDataService")
    
    -- Update Player 1
    if battle.Player1.UserID > 0 then
        local player1 = Players:GetPlayerByUserId(battle.Player1.UserID)
        if player1 then
            local statsUpdate = {
                BattlesWon = result.Winner == 1 and 1 or 0,
                BattlesLost = result.Winner ~= 1 and 1 or 0,
                TotalDamageDealt = battle.Player1.BattleStats.DamageDealt,
                TotalDamageReceived = battle.Player1.BattleStats.DamageTaken
            }
            
            playerDataService:UpdatePlayerStats(player1, statsUpdate)
            
            local rewards = result.RewardsEarned[battle.Player1.UserID]
            if rewards then
                playerDataService:UpdatePlayerEconomy(player1, "Coins", rewards.Coins)
                playerDataService:AddExperience(player1, rewards.Experience)
            end
        end
    end
    
    -- Update Player 2 (if not AI)
    if battle.Player2.UserID > 0 then
        local player2 = Players:GetPlayerByUserId(battle.Player2.UserID)
        if player2 then
            local statsUpdate = {
                BattlesWon = result.Winner == 2 and 1 or 0,
                BattlesLost = result.Winner ~= 2 and 1 or 0,
                TotalDamageDealt = battle.Player2.BattleStats.DamageDealt,
                TotalDamageReceived = battle.Player2.BattleStats.DamageTaken
            }
            
            playerDataService:UpdatePlayerStats(player2, statsUpdate)
            
            local rewards = result.RewardsEarned[battle.Player2.UserID]
            if rewards then
                playerDataService:UpdatePlayerEconomy(player2, "Coins", rewards.Coins)
                playerDataService:AddExperience(player2, rewards.Experience)
            end
        end
    end
end

function BattleService:_broadcastBattleUpdate(battle: BattleSession, updateData: any)
    -- Broadcast to Player 1
    if battle.Player1.UserID > 0 then
        local player1 = Players:GetPlayerByUserId(battle.Player1.UserID)
        if player1 then
            RemoteEventHandler:FireClient("BattleUpdate", player1, updateData)
        end
    end
    
    -- Broadcast to Player 2 (if not AI)
    if battle.Player2.UserID > 0 then
        local player2 = Players:GetPlayerByUserId(battle.Player2.UserID)
        if player2 then
            RemoteEventHandler:FireClient("BattleUpdate", player2, updateData)
        end
    end
    
    -- Broadcast to spectators
    for _, spectatorID in ipairs(battle.Spectators) do
        local spectator = Players:GetPlayerByUserId(spectatorID)
        if spectator then
            RemoteEventHandler:FireClient("BattleUpdate", spectator, updateData)
        end
    end
end

function BattleService:_processBattleUpdates()
    local currentTime = os.time()
    
    -- Process turn timers
    for battleID, timeLimit in pairs(self._turnTimers) do
        if currentTime >= timeLimit then
            local battle = self._activeBattles[battleID]
            if battle and battle.BattleState == "InProgress" then
                -- Force end turn
                self:_executeEndTurn(battle)
                self._turnTimers[battleID] = nil
            end
        end
    end
    
    -- Update battle statistics
    self._activePlayerCount = 0
    for _, battle in pairs(self._activeBattles) do
        if battle.Player1.UserID > 0 then
            self._activePlayerCount += 1
        end
        if battle.Player2.UserID > 0 then
            self._activePlayerCount += 1
        end
    end
end

function BattleService:_setupRemoteHandlers()
    -- Create remote events that this service will use
    RemoteEventHandler:GetRemoteEvent("BattleUpdate")
    
    -- Setup remote function handlers
    RemoteEventHandler:BindRemoteFunction("StartBattle", function(player, request: BattleTypes.StartBattleRequest)
        return self:StartBattle(player, request)
    end)
    
    RemoteEventHandler:BindRemoteFunction("GetBattleState", function(player)
        return self:GetBattleState(player)
    end)
    
    -- Setup remote event handlers
    RemoteEventHandler:ConnectRemoteEvent("BattleAction", function(player, actionData)
        local action: BattleAction = {
            ActionID = HttpService:GenerateGUID(false),
            PlayerID = player.UserId,
            ActionType = actionData.ActionType,
            ActionData = actionData.ActionData or {},
            Timestamp = os.time(),
            IsValid = false
        }
        
        self:ProcessAction(player, action)
    end)
end

function BattleService:_initializeAIOpponents()
    for difficulty, personality in pairs(AI_PERSONALITIES) do
        local cardDatabase = CardDatabase
        local aiDeck = {}
        
        -- Create AI deck with basic cards
        local basicCards = cardDatabase:GetCardsByRarity("Common")
        for i = 1, BATTLE_CONFIG.DeckSize do
            if basicCards[i] then
                table.insert(aiDeck, basicCards[i])
            end
        end
        
        self._aiOpponents[difficulty] = {
            AIID = "ai_" .. string.lower(difficulty),
            Name = "AI " .. difficulty,
            Difficulty = difficulty,
            Deck = aiDeck,
            Personality = personality,
            BehaviorSettings = {
                ThinkingTime = personality.Patience * 3 + 1,
                RandomnessFactor = 1 - personality.Adaptability,
                PredictiveDepth = math.floor(personality.Adaptability * 3) + 1,
                FavoriteStrategies = {"aggressive", "defensive"},
                CounterStrategies = {"adaptive"}
            }
        }
    end
    
    self:_log("AI opponents initialized: " .. TableUtils.getSize(self._aiOpponents))
end

function BattleService:_startMatchmakingProcessor()
    spawn(function()
        while true do
            wait(1)
            -- Process matchmaking queue
            if #self._battleQueue > 1 then
                local player1Request = table.remove(self._battleQueue, 1)
                local player2Request = table.remove(self._battleQueue, 1)
                
                local player1 = Players:GetPlayerByUserId(player1Request.PlayerID)
                local player2 = Players:GetPlayerByUserId(player2Request.PlayerID)
                
                if player1 and player2 then
                    self:CreateBattle(player1, player2, "Ranked")
                end
            end
        end
    end)
end

function BattleService:_createBasicDeck(collection: PlayerTypes.CardCollection): {string}
    local deckCards = {}
    
    -- Use owned cards or fallback to basic cards
    for cardID, count in pairs(collection.CardCounts) do
        if count > 0 and #deckCards < BATTLE_CONFIG.DeckSize then
            table.insert(deckCards, cardID)
        end
    end
    
    -- Fill with basic cards if needed
    while #deckCards < BATTLE_CONFIG.DeckSize do
        table.insert(deckCards, "naruto_001") -- Default card
    end
    
    return deckCards
end

function BattleService:_createEmptyBattleStats(): BattleTypes.PlayerBattleStats
    return {
        DamageDealt = 0,
        DamageTaken = 0,
        CardsPlayed = 0,
        SpecialAbilitiesUsed = 0,
        CriticalHits = 0,
        StatusEffectsApplied = 0,
        TurnsPlayed = 0,
        LongestCombo = 0,
        HighestSingleDamage = 0,
        CardsDestroyed = 0
    }
end

function BattleService:_getDefaultBattleSettings(): BattleTypes.BattleSettings
    return {
        TurnTimeLimit = BATTLE_CONFIG.DefaultTurnTime,
        MaxTurns = 50,
        StartingHealth = BATTLE_CONFIG.StartingHealth,
        StartingEnergy = BATTLE_CONFIG.StartingEnergy,
        DeckSize = BATTLE_CONFIG.DeckSize,
        HandSize = BATTLE_CONFIG.HandSize,
        AllowSpectators = false,
        RankedMatch = false
    }
end

function BattleService:_generateBattleID(): string
    return "battle_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

return BattleService.new() 