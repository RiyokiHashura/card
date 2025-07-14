--!strict
-- PlayerDataService.luau
-- Comprehensive player data management with persistence, validation, and progression tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local CardTypes = require(ReplicatedStorage.Shared.Types.CardTypes)
local TableUtils = require(ReplicatedStorage.Shared.Utils.TableUtils)

type PlayerData = PlayerTypes.PlayerData
type PlayerSession = PlayerTypes.PlayerSession
type DataServiceResponse<T> = PlayerTypes.DataServiceResponse<T>
type SaveResult = PlayerTypes.SaveResult

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService
setmetatable(PlayerDataService, {__index = BaseService})

-- Constants
local DATA_STORE_NAME = "PlayerData_v1"
local BACKUP_STORE_NAME = "PlayerBackup_v1"
local SESSION_STORE_NAME = "PlayerSessions_v1"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes
local MAX_SAVE_RETRIES = 3
local CACHE_EXPIRE_TIME = 1800 -- 30 minutes

function PlayerDataService.new()
    local self = BaseService.new("PlayerDataService", {})
    setmetatable(self, PlayerDataService)
    
    -- Data stores
    self._dataStore = nil
    self._backupStore = nil
    self._sessionStore = nil
    
    -- Player data cache
    self._playerDataCache = {} :: {[number]: PlayerData}
    self._playerSessions = {} :: {[number]: PlayerSession}
    self._saveQueue = {} :: {[number]: boolean}
    self._savingPlayers = {} :: {[number]: boolean}
    
    -- Performance tracking
    self._lastSaveTime = os.time()
    self._saveOperations = 0
    self._loadOperations = 0
    
    return self
end

function PlayerDataService:Initialize()
    self:_log("PlayerDataService initializing...")
    
    -- Initialize data stores
    self:_initializeDataStores()
    
    if not self._dataStore then
        self:_logError("Failed to initialize data stores - running in offline mode")
        return
    end
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        self:_onPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:_onPlayerRemoving(player)
    end)
    
    -- Auto-save timer
    self._autoSaveConnection = RunService.Heartbeat:Connect(function()
        self:_processAutoSave()
    end)
    
    self:_log("PlayerDataService initialized successfully")
end

function PlayerDataService:Start()
    self:_log("PlayerDataService starting...")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:_onPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:_onPlayerRemoving(player)
    end)

    -- Start the auto-save loop
    self:_startAutoSaveLoop()
    
    self:_log("PlayerDataService started successfully")
end

function PlayerDataService:Stop()
    self:_log("PlayerDataService stopping...")
    
    -- Save all player data
    for userID, _ in pairs(self._playerDataCache) do
        local player = Players:GetPlayerByUserId(userID)
        if player then
            self:SavePlayerData(player):await()
        end
    end
    
    -- Clean up connections
    if self._autoSaveConnection then
        self._autoSaveConnection:Disconnect()
    end
    
    self:_log("PlayerDataService stopped")
end

-- Public Methods

function PlayerDataService:GetPlayerData(player: Player): PlayerData?
    local userID = player.UserId
    return self._playerDataCache[userID]
end

function PlayerDataService:GetPlayerSession(player: Player): PlayerSession?
    local userID = player.UserId
    return self._playerSessions[userID]
end

function PlayerDataService:LoadPlayerData(player: Player): DataServiceResponse<PlayerData>
    local userID = player.UserId
    
    -- Check cache first
    if self._playerDataCache[userID] then
        return {
            Success = true,
            Data = self._playerDataCache[userID]
        }
    end
    
    self._loadOperations += 1
    self:_log("Loading player data for " .. player.Name)
    
    local success, result = pcall(function()
        if not self._dataStore then
            error("Data store not available")
        end
        
        local data = self._dataStore:GetAsync(tostring(userID))
        return data
    end)
    
    if not success then
        self:_logError("Failed to load player data: " .. tostring(result))
        return {
            Success = false,
            ErrorMessage = "Failed to load player data"
        }
    end
    
    local playerData: PlayerData
    if result then
        -- Validate and migrate existing data
        playerData = self:_validatePlayerData(result, player)
    else
        -- Create new player data
        playerData = self:_createDefaultPlayerData(player)
    end
    
    -- Cache the data
    self._playerDataCache[userID] = playerData
    
    return {
        Success = true,
        Data = playerData
    }
end

function PlayerDataService:SavePlayerData(player: Player): SaveResult
    local userID = player.UserId
    local playerData = self._playerDataCache[userID]
    
    if not playerData then
        return {
            Success = false,
            ErrorMessage = "No player data to save"
        }
    end
    
    -- Skip if already saving
    if self._savingPlayers[userID] then
        return {
            Success = false,
            ErrorMessage = "Save already in progress"
        }
    end
    
    self._savingPlayers[userID] = true
    self._saveOperations += 1
    
    -- Update save metadata
    playerData.LastSaveTime = os.time()
    playerData.IsDirty = false
    
    local success, errorMessage = pcall(function()
        if not self._dataStore then
            error("Data store not available")
        end
        
        -- Create backup first
        local backupKey = tostring(userID) .. "_backup"
        pcall(function()
            self._backupStore:SetAsync(backupKey, playerData)
        end)
        
        -- Save main data
        self._dataStore:SetAsync(tostring(userID), playerData)
    end)
    
    self._savingPlayers[userID] = nil
    
    if not success then
        self:_logError("Failed to save player data: " .. tostring(errorMessage))
        return {
            Success = false,
            SaveTime = os.time(),
            ErrorMessage = "Failed to save player data"
        }
    end
    
    self:_log("Saved player data for " .. player.Name)
    return {
        Success = true,
        SaveTime = os.time()
    }
end

function PlayerDataService:UpdatePlayerStats(player: Player, statUpdates: {[string]: any}): boolean
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    if not playerData.Stats then
        self:_logError("No stats found for " .. player.Name .. ", creating new stats")
        playerData.Stats = {
            Level = 1,
            Experience = 0,
            ExperienceToNext = 100,
            TotalRolls = 0,
            RollsToNextPity = 0,
            BattlesWon = 0,
            BattlesLost = 0,
            WinRate = 0,
            HighestWinStreak = 0,
            CurrentWinStreak = 0,
            TotalDamageDealt = 0,
            TotalDamageReceived = 0,
            FavoriteCard = nil,
            PlayTime = 0,
            FirstLoginTime = os.time(),
            LastLoginTime = os.time(),
            LoginStreak = 1,
            DailyRollsUsed = 0,
            DailyRollsResetTime = os.time() + 86400
        }
    end
    
    for statName, value in pairs(statUpdates) do
        if playerData.Stats[statName] ~= nil then
            playerData.Stats[statName] = value
        end
    end
    
    -- Calculate derived stats
    self:_calculateDerivedStats(playerData)
    
    playerData.IsDirty = true
    return true
end

function PlayerDataService:AddCardToCollection(player: Player, cardID: string): boolean
    local playerData = self:GetPlayerData(player)
    if not playerData then
        self:_logError("No player data found for " .. player.Name)
        return false
    end
    
    local collection = playerData.Collection
    if not collection then
        self:_logError("No collection found for " .. player.Name .. ", creating new collection")
        playerData.Collection = {
            OwnedCards = {},
            CardCounts = {},
            TotalCardsOwned = 0,
            UniqueCardsOwned = 0,
            FavoriteCards = {},
            RecentlyObtained = {},
            CollectionValue = 0
        }
        collection = playerData.Collection
    end
    local currentTime = os.time()
    
    -- Create card instance
    local cardInstance = {
        ID = self:_generateCardInstanceID(),
        CardID = cardID,
        ObtainedTime = currentTime,
        TimesUsed = 0,
        WinsWithCard = 0,
        LossesWithCard = 0,
        DamageDealt = 0,
        IsNew = true,
        IsFavorite = false
    }
    
    -- Add to collection
    collection.OwnedCards[cardInstance.ID] = cardInstance
    collection.CardCounts[cardID] = (collection.CardCounts[cardID] or 0) + 1
    collection.TotalCardsOwned += 1
    
    -- Check if new unique card
    if collection.CardCounts[cardID] == 1 then
        collection.UniqueCardsOwned += 1
    end
    
    -- Add to recently obtained
    table.insert(collection.RecentlyObtained, cardInstance.ID)
    if #collection.RecentlyObtained > 10 then
        table.remove(collection.RecentlyObtained, 1)
    end
    
    -- Update collection value
    self:_updateCollectionValue(playerData)
    
    playerData.IsDirty = true
    return true
end

function PlayerDataService:UpdatePityData(player: Player, rarity: string, wasPityRoll: boolean)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end
	
	if wasPityRoll then
		-- Reset pity for this rarity and all lower rarities
		playerData.Pity[rarity] = 0
		
		-- Example: if Legendary pity is used, reset Epic and Rare too
		local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Ultimate"}
		local rarityIndex = table.find(rarityOrder, rarity)
		if rarityIndex then
			for i = 1, rarityIndex - 1 do
				playerData.Pity[rarityOrder[i]] = 0
			end
		end
		
	else
		-- Increment pity for all rarities that weren't won
		for r, _ in pairs(playerData.Pity) do
			if r ~= rarity then
				playerData.Pity[r] = (playerData.Pity[r] or 0) + 1
			end
		end
	end
	
	self:_log(string.format("Pity data updated for %s: %s", player.Name, HttpService:JSONEncode(playerData.Pity)))
end

function PlayerDataService:UpdatePlayerEconomy(player: Player, currency: string, amount: number): boolean
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    local economy = playerData.Economy
    if not economy then
        self:_logError("No economy found for " .. player.Name .. ", creating new economy")
        playerData.Economy = {
            Coins = GameConstants.Balance.StartingCoins,
            Gems = 0,
            DailyRolls = 3,
            EarnedTotal = 0,
            SpentTotal = 0,
            PurchaseHistory = {}
        }
        economy = playerData.Economy
    end
    
    if economy[currency] then
        economy[currency] = math.max(0, economy[currency] + amount)
        
        -- Track earnings/spending
        if amount > 0 then
            economy.EarnedTotal += amount
        else
            economy.SpentTotal += math.abs(amount)
        end
        
        playerData.IsDirty = true
        return true
    end
    
    return false
end

function PlayerDataService:GetPlayerLevel(player: Player): number
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return 1
    end
    
    return playerData.Stats.Level
end

function PlayerDataService:AddExperience(player: Player, amount: number): boolean
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    local stats = playerData.Stats
    stats.Experience += amount
    
    -- Check for level up
    while stats.Experience >= stats.ExperienceToNext do
        stats.Experience -= stats.ExperienceToNext
        stats.Level += 1
        stats.ExperienceToNext = self:_calculateExperienceToNext(stats.Level)
        
        -- Level up rewards
        self:_processLevelUpRewards(player, stats.Level)
    end
    
    playerData.IsDirty = true
    return true
end

-- Private Methods

function PlayerDataService:_initializeDataStores()
	if not RunService:IsStudio() then
		-- In a live server, try to get DataStoreService
		local success, result = pcall(function()
			return game:GetService("DataStoreService")
		end)
		
		if success and result then
			self._dataStore = result:GetDataStore("PlayerData_v1")
			self:_log("Successfully connected to DataStore.")
		else
			self:_logError("Failed to get DataStoreService. Running in offline mode.")
			self._dataStore = nil
		end
	else
		-- In Studio, we are always in offline mode for testing
		self:_log("Running in Roblox Studio. DataStore is disabled. Using offline mode.")
		self._dataStore = nil
	end
end

function PlayerDataService:_onPlayerAdded(player: Player)
	local playerID = player.UserId
	self:_log("Player joined: " .. player.Name .. " (ID: " .. playerID .. ")")
	
	if self._dataStore then
		-- Load data from DataStore
		-- (Implementation for live server)
	else
		-- Offline mode: create default data for testing
		self:_log("Creating default data for " .. player.Name .. " in offline mode.")
		local defaultData: PlayerTypes.PlayerData = {
			PlayerId = playerID,
			Name = player.Name,
			Level = 1,
			Experience = 0,
			Gems = 1000,
			Cards = {},
			Pity = {
				Rare = 0,
				Epic = 0,
				Legendary = 0,
			},
			LastLogin = os.time(),
			Settings = {
				Volume = 1,
				AutoSkip = false,
			},
		}
		self._playerDataCache[playerID] = defaultData
		self:_log("Default data created for " .. player.Name)
	end
end

function PlayerDataService:_onPlayerRemoving(player: Player)
	local playerID = player.UserId
	self:_log("Player left: " .. player.Name .. " (ID: " .. playerID .. ")")

	-- Save their data one last time
	if self._playerDataCache[playerID] then
		self:_savePlayerData(playerID, self._playerDataCache[playerID])
	end

	-- Clear from cache
	self._playerDataCache[playerID] = nil
	self:_log("Cleared data cache for " .. player.Name)
end

function PlayerDataService:_startAutoSaveLoop()
	-- This will periodically save data for all online players
	spawn(function()
		while true do
			wait(GameConstants.Settings.AutoSaveInterval or 300) -- Default to 5 minutes
			
			if not self._dataStore then return end -- Don't run in offline mode
			
			self:_log("Performing periodic auto-save...")
			for playerID, data in pairs(self._playerDataCache) do
				self:_savePlayerData(playerID, data)
			end
		end
	end)
end

function PlayerDataService:_savePlayerData(playerID: number, data: PlayerTypes.PlayerData)
	if not self._dataStore then return end -- No saving in offline mode

	local success, err = pcall(function()
		self._dataStore:SetAsync(tostring(playerID), data)
	end)

	if not success then
		self:_logError("Failed to save data for player " .. tostring(playerID) .. ": " .. err)
	else
		self:_log("Successfully saved data for player " .. tostring(playerID))
	end
end

function PlayerDataService:_createDefaultPlayerData(player: Player): PlayerData
    local currentTime = os.time()
    
    return {
        UserID = player.UserId,
        Username = player.Name,
        Stats = {
            Level = 1,
            Experience = 0,
            ExperienceToNext = 100,
            TotalRolls = 0,
            RollsToNextPity = 0,
            BattlesWon = 0,
            BattlesLost = 0,
            WinRate = 0,
            HighestWinStreak = 0,
            CurrentWinStreak = 0,
            TotalDamageDealt = 0,
            TotalDamageReceived = 0,
            FavoriteCard = nil,
            PlayTime = 0,
            FirstLoginTime = currentTime,
            LastLoginTime = currentTime,
            LoginStreak = 1,
            DailyRollsUsed = 0,
            DailyRollsResetTime = currentTime + 86400
        },
        Collection = {
            OwnedCards = {},
            CardCounts = {},
            TotalCardsOwned = 0,
            UniqueCardsOwned = 0,
            FavoriteCards = {},
            RecentlyObtained = {},
            CollectionValue = 0
        },
        Progression = {
            CurrentDeck = {},
            UnlockedFeatures = {"basic_battle", "card_collection"},
            Achievements = {},
            QuestProgress = {},
            CompletedQuests = {},
            TutorialProgress = {},
            LastSeenNews = nil,
            Settings = self:_getDefaultSettings()
        },
        PityData = {
            CommonPity = 0,
            UncommonPity = 0,
            RarePity = 0,
            EpicPity = 0,
            LegendaryPity = 0,
            MythicalPity = 0,
            UltimatePity = 0,
            LastLegendaryRoll = 0,
            LastMythicalRoll = 0,
            LastUltimateRoll = 0,
            GuaranteedNext = nil,
            RollHistory = {}
        },
        Pity = {
            Common = 0,
            Uncommon = 0,
            Rare = 0,
            Epic = 0,
            Legendary = 0,
            Mythical = 0,
            Ultimate = 0
        },
        Economy = {
            Coins = GameConstants.Balance.StartingCoins,
            Gems = GameConstants.Balance.StartingGems,
            DailyRolls = GameConstants.Balance.DailyRolls,
            PremiumRolls = 0,
            BattleTokens = 0,
            LastDailyReward = 0,
            LastWeeklyReward = 0,
            PurchaseHistory = {},
            SpentTotal = 0,
            EarnedTotal = 0
        },
        Social = {
            Friends = {},
            BlockedUsers = {},
            GuildID = nil,
            GuildRank = nil,
            RecentOpponents = {},
            Reputation = 100,
            ReportsMade = 0,
            ReportsReceived = 0,
            LastReportTime = 0
        },
        DataVersion = 1,
        LastSaveTime = currentTime,
        IsDirty = false
    }
end

function PlayerDataService:_getDefaultSettings(): PlayerTypes.PlayerSettings
    return {
        SoundEnabled = true,
        MusicEnabled = true,
        SoundVolume = 0.8,
        MusicVolume = 0.6,
        ScreenShakeEnabled = true,
        ScreenShakeIntensity = 0.8,
        AutoPlay = false,
        SkipAnimations = false,
        ShowDamageNumbers = true,
        ShowCardTooltips = true,
        ChatEnabled = true,
        FriendRequestsEnabled = true,
        DataCollectionConsent = false
    }
end

function PlayerDataService:_validatePlayerData(data: any, player: Player): PlayerData
    -- Basic validation and migration logic
    if type(data) ~= "table" then
        return self:_createDefaultPlayerData(player)
    end
    
    -- Ensure all required fields exist
    local validData = TableUtils.DeepCopy(data)
    local defaultData = self:_createDefaultPlayerData(player)
    
    -- Merge missing fields
    validData = TableUtils.DeepMerge(defaultData, validData)
    
    -- Update username if changed
    validData.Username = player.Name
    
    -- Update login time
    validData.Stats.LastLoginTime = os.time()
    
    return validData
end

function PlayerDataService:_calculateDerivedStats(playerData: PlayerData)
    local stats = playerData.Stats
    
    -- Calculate win rate
    local totalBattles = stats.BattlesWon + stats.BattlesLost
    if totalBattles > 0 then
        stats.WinRate = stats.BattlesWon / totalBattles
    else
        stats.WinRate = 0
    end
end

function PlayerDataService:_calculateExperienceToNext(level: number): number
    return math.floor(100 * (level ^ 1.5))
end

function PlayerDataService:_processLevelUpRewards(player: Player, newLevel: number)
    -- Give level up rewards
    local coinsReward = newLevel * 50
    local gemsReward = math.floor(newLevel / 5)
    
    self:UpdatePlayerEconomy(player, "Coins", coinsReward)
    if gemsReward > 0 then
        self:UpdatePlayerEconomy(player, "Gems", gemsReward)
    end
    
    self:_log("Player " .. player.Name .. " reached level " .. newLevel)
end

function PlayerDataService:_updateCollectionValue(playerData: PlayerData)
    local totalValue = 0
    for cardID, count in pairs(playerData.Collection.CardCounts) do
        -- Calculate value based on rarity and count
        -- This would integrate with CardDatabase to get rarity
        totalValue += count * 10 -- Placeholder calculation
    end
    
    playerData.Collection.CollectionValue = totalValue
end

function PlayerDataService:_generateCardInstanceID(): string
    return "card_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

function PlayerDataService:_processAutoSave()
    local currentTime = os.time()
    
    -- Auto-save every 5 minutes
    if currentTime - self._lastSaveTime >= AUTO_SAVE_INTERVAL then
        for userID, isDirty in pairs(self._saveQueue) do
            if isDirty then
                local player = Players:GetPlayerByUserId(userID)
                if player then
                    spawn(function()
                        self:SavePlayerData(player)
                    end)
                end
            end
        end
        
        self._lastSaveTime = currentTime
    end
    
    -- Update save queue for dirty data
    for userID, playerData in pairs(self._playerDataCache) do
        if playerData.IsDirty then
            self._saveQueue[userID] = true
        end
    end
end

function PlayerDataService:_logError(message: string)
	warn("[PlayerDataService] ERROR: " .. message)
end

return PlayerDataService.new() 