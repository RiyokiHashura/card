# 🏗️ Anime Card Clash - Architecture Documentation

## 📋 Overview
This document explains the complete architecture of Anime Card Clash, a modular card collection game built for Roblox. The system is designed to handle 30-50k concurrent players with a service-based architecture.

## 🎯 Core Principles

### 1. **Modular Design**
- Every feature is a separate service/controller
- Services can be added/removed without breaking the system
- Clean separation of concerns

### 2. **Dependency Injection**
- Services declare their dependencies
- ServiceRegistry handles initialization order
- No circular dependencies allowed

### 3. **Lifecycle Management**
- All services follow: Initialize → Start → Stop → Cleanup
- Proper connection cleanup prevents memory leaks
- Error handling at every stage

### 4. **Client-Server Architecture**
- Server: Services manage game logic and data
- Client: Controllers handle UI and input
- Shared: Common utilities and constants

## 🔄 System Flow

### Server Initialization
```
1. Server starts (init.server.luau)
2. Load all services from Services/ folder
3. Register services with ServiceRegistry
4. Initialize services (with dependency resolution)
5. Start all services
6. Server ready for players
```

### Client Initialization
```
1. Client starts (init.client.luau)
2. Load all controllers from Controllers/ folder
3. Register controllers with ServiceRegistry
4. Initialize controllers (with dependency resolution)
5. Start all controllers
6. Client ready for gameplay
```

### Service Communication
```
Server Service → RemoteEventHandler → Client Controller
     ↓                                        ↓
Data Processing                         UI Updates
     ↓                                        ↓
Database/Storage                    Visual Effects
```

## 📁 Directory Structure

```
src/
├── client/
│   ├── init.client.luau         # Client bootstrap
│   └── Controllers/             # Client-side controllers
│       ├── UIController.luau
│       ├── InputController.luau
│       └── EffectsController.luau
├── server/
│   ├── init.server.luau         # Server bootstrap
│   └── Services/                # Server-side services
│       ├── PlayerDataService.luau
│       ├── CardRollService.luau
│       └── BattleService.luau
└── shared/
    ├── init.luau                # Shared module index
    ├── Core/                    # Framework foundation
    │   ├── ServiceRegistry.luau
    │   ├── BaseService.luau
    │   ├── BaseController.luau
    │   └── RemoteEventHandler.luau
    ├── Constants/               # Game constants
    │   └── GameConstants.luau
    ├── Utils/                   # Utility functions
    │   └── TableUtils.luau
    └── Types/                   # Type definitions
        └── GameTypes.luau
```

## 🔧 Core Components

### ServiceRegistry
**Purpose**: Manages all services and controllers with proper lifecycle management

**Key Features**:
- Dependency resolution
- Initialization order management
- State tracking
- Debug logging
- Error handling

**Usage**:
```lua
-- Register a service
ServiceRegistry:RegisterService("PlayerDataService", playerDataService)

-- Get a service
local playerData = ServiceRegistry:GetService("PlayerDataService")

-- Initialize and start all services
ServiceRegistry:InitializeAll()
ServiceRegistry:StartAll()
```

### BaseService (Server-Side)
**Purpose**: Foundation for all server services

**Key Features**:
- Lifecycle hooks (Initialize, Start, Stop, Cleanup)
- Connection management
- Debug logging
- Error handling

**Usage**:
```lua
local MyService = {}
MyService.__index = MyService
setmetatable(MyService, {__index = BaseService})

function MyService.new()
    local self = BaseService.new("MyService", {"DependencyService"})
    setmetatable(self, MyService)
    return self
end

function MyService:Initialize()
    self:_log("MyService initializing...")
    -- Initialize logic here
end

function MyService:Start()
    self:_log("MyService starting...")
    -- Start logic here
end

return MyService
```

### BaseController (Client-Side)
**Purpose**: Foundation for all client controllers

**Key Features**:
- Lifecycle hooks (Initialize, Start, Stop, Cleanup)
- Input handling utilities
- Connection management
- Debug logging

**Usage**:
```lua
local MyController = {}
MyController.__index = MyController
setmetatable(MyController, {__index = BaseController})

function MyController.new()
    local self = BaseController.new("MyController", {"UIController"})
    setmetatable(self, MyController)
    return self
end

function MyController:Initialize()
    self:_log("MyController initializing...")
    -- Initialize UI elements
end

function MyController:Start()
    self:_log("MyController starting...")
    -- Connect input handlers
    self:_connectInput(Enum.KeyCode.Space, function()
        self:handleSpacePress()
    end)
end

return MyController
```

### RemoteEventHandler
**Purpose**: Type-safe client-server communication

**Key Features**:
- Automatic remote event creation
- Client/server method separation
- Caching for performance
- Debug logging

**Usage**:
```lua
-- Server side
RemoteEventHandler:ConnectRemoteEvent("RollCard", function(player, cardType)
    -- Handle card roll
end)

RemoteEventHandler:FireClient(player, "CardRolled", cardData)

-- Client side
RemoteEventHandler:FireServer("RollCard", "Common")

RemoteEventHandler:ConnectRemoteEventClient("CardRolled", function(cardData)
    -- Handle card reveal
end)
```

## 🔍 Debug System

### Debug Logging
All services and controllers have built-in debug logging:
- **Studio only**: Debug logs only show in Roblox Studio
- **Timestamps**: All logs include timestamps
- **Service identification**: Logs show which service generated them
- **Global access**: `_G.ServiceRegistry` and `_G.Services` available

### Debug Commands
```lua
-- In studio command bar
_G.ServiceRegistry:GetAllServices()  -- List all services
_G.ServiceRegistry:GetServiceState("PlayerDataService")  -- Check service state
_G.Services.PlayerDataService:SomeMethod()  -- Call service methods directly
```

## 🎮 Game Flow

### Player Joins
```
1. Client initializes controllers
2. Server creates PlayerDataService entry
3. Client requests player data
4. Server sends current stats/cards
5. Client displays main UI
```

### Card Rolling
```
1. Client: Player clicks "Roll" button
2. Client: UIController fires "RollCard" event
3. Server: CardRollService processes roll
4. Server: Updates player data
5. Server: Fires "CardRolled" event to client
6. Client: EffectsController shows reveal animation
7. Client: UIController updates card collection
```

### Battle System
```
1. Client: Player enters battle
2. Client: Fires "StartBattle" event
3. Server: BattleService creates battle instance
4. Server: Sends battle data to client
5. Client: BattleController displays battle UI
6. [Battle loop continues...]
```

## 🚀 Performance Considerations

### Memory Management
- All services use `_connections` table for tracking
- Automatic cleanup in `Stop()` method
- Object pooling for frequent operations
- Proper garbage collection

### Network Optimization
- RemoteEventHandler caches remote events
- Minimal data transfer
- Batch updates when possible
- Client-side prediction for UI

### Scalability
- Services can be horizontally scaled
- Database abstraction layer
- Caching strategies
- Load balancing ready

## 🔧 Adding New Features

### New Service (Server)
1. Create file in `src/server/Services/`
2. Extend `BaseService`
3. Implement lifecycle methods
4. Declare dependencies
5. Auto-loaded by framework

### New Controller (Client)
1. Create file in `src/client/Controllers/`
2. Extend `BaseController`
3. Implement lifecycle methods
4. Declare dependencies
5. Auto-loaded by framework

### New Shared Module
1. Create file in appropriate `src/shared/` folder
2. Export from `src/shared/init.luau`
3. Available to all services/controllers

## 🛠️ Troubleshooting

### Common Issues
1. **Service not found**: Check spelling and file location
2. **Circular dependency**: Review dependency declarations
3. **Initialization order**: Use Dependencies array
4. **Memory leaks**: Ensure proper cleanup in Stop() method
5. **Remote events not working**: Check RemoteEventHandler usage

### Debug Steps
1. Check service state: `_G.ServiceRegistry:GetServiceState("ServiceName")`
2. Verify service exists: `_G.ServiceRegistry:GetAllServices()`
3. Check debug logs in Studio output
4. Verify remote event creation in ReplicatedStorage

## 📈 Future Scalability

### Planned Enhancements
- Database abstraction layer
- Caching system
- Event sourcing
- Microservices architecture
- Load balancing
- Monitoring and metrics

### Architecture Evolution
The current architecture is designed to evolve:
- Services can be split into microservices
- Database can be swapped out
- Caching layers can be added
- Load balancing can be implemented
- Monitoring can be integrated

---

**Last Updated**: Initial Version
**Next Review**: After card system implementation 