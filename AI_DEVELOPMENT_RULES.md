# 🤖 AI Development Rules for Anime Card Clash

## 📋 Overview
This document contains **CRITICAL RULES** that ALL AI interactions must follow when working on this project. These rules ensure consistency, maintainability, and prevent architectural degradation.

## 🚨 MANDATORY RULES - NEVER VIOLATE THESE

### 1. **ALWAYS Read Architecture First**
- **BEFORE** making any changes, read `ARCHITECTURE.md` completely
- **BEFORE** adding features, read `FEATURE_ROADMAP.md`
- **BEFORE** creating services, read `SERVICE_CREATION_GUIDE.md`
- **BEFORE** creating controllers, read `CONTROLLER_CREATION_GUIDE.md`

### 2. **NEVER Break the Service Architecture**
- **ALL** server logic MUST be in Services extending `BaseService`
- **ALL** client logic MUST be in Controllers extending `BaseController`
- **NO** direct game logic in init files
- **NO** bypassing the ServiceRegistry
- **NO** circular dependencies between services

### 3. **ALWAYS Use the Framework**
- **USE** `BaseService` for all server services
- **USE** `BaseController` for all client controllers
- **USE** `RemoteEventHandler` for all client-server communication
- **USE** `GameConstants` for all constants
- **USE** `TableUtils` for table operations

### 4. **FOLLOW Strict Code Organization**
```
src/
├── client/Controllers/     # ✅ Client-side controllers ONLY
├── server/Services/        # ✅ Server-side services ONLY
└── shared/                 # ✅ Shared utilities and constants ONLY
```

### 5. **MAINTAIN Type Safety**
- **ALL** files MUST start with `--!strict`
- **ALL** functions MUST have proper type annotations
- **ALL** variables MUST be properly typed
- **USE** export types for public interfaces

## 🔧 Development Workflow

### Step 1: Planning Phase
1. **Read** existing documentation
2. **Identify** which services/controllers need modification
3. **Check** for existing implementations
4. **Plan** the data flow
5. **Identify** dependencies

### Step 2: Implementation Phase
1. **Create** service/controller files in correct folders
2. **Extend** appropriate base classes
3. **Implement** lifecycle methods
4. **Add** to appropriate init files (auto-loaded)
5. **Test** in correct order

### Step 3: Documentation Phase
1. **Update** relevant documentation
2. **Add** code comments
3. **Update** FEATURE_ROADMAP.md
4. **Create** usage examples

## 📁 File Creation Rules

### New Service (Server)
```lua
--!strict
-- ServiceName.luau
-- Description of what this service does

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseService = require(ReplicatedStorage.Shared.Core.BaseService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local ServiceName = {}
ServiceName.__index = ServiceName
setmetatable(ServiceName, {__index = BaseService})

function ServiceName.new()
    local self = BaseService.new("ServiceName", {"DependencyService"})
    setmetatable(self, ServiceName)
    return self
end

function ServiceName:Initialize()
    self:_log("ServiceName initializing...")
    -- Initialize logic here
end

function ServiceName:Start()
    self:_log("ServiceName starting...")
    -- Start logic here
end

return ServiceName.new()
```

### New Controller (Client)
```lua
--!strict
-- ControllerName.luau
-- Description of what this controller does

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local ControllerName = {}
ControllerName.__index = ControllerName
setmetatable(ControllerName, {__index = BaseController})

function ControllerName.new()
    local self = BaseController.new("ControllerName", {"UIController"})
    setmetatable(self, ControllerName)
    return self
end

function ControllerName:Initialize()
    self:_log("ControllerName initializing...")
    -- Initialize UI elements
end

function ControllerName:Start()
    self:_log("ControllerName starting...")
    -- Connect input handlers
end

return ControllerName.new()
```

## 🎯 Feature Implementation Rules

### Adding New Features
1. **NEVER** modify existing architecture
2. **ALWAYS** add new services/controllers
3. **ALWAYS** use dependency injection
4. **ALWAYS** follow the established patterns

### Modifying Existing Features
1. **NEVER** change BaseService or BaseController
2. **NEVER** modify ServiceRegistry
3. **ALWAYS** extend existing services
4. **ALWAYS** maintain backward compatibility

### Communication Rules
1. **ALWAYS** use RemoteEventHandler for client-server communication
2. **NEVER** use RemoteEvents directly
3. **ALWAYS** validate data on server
4. **ALWAYS** use proper error handling

## 🔍 Code Quality Rules

### Naming Conventions
- **Services**: `ServiceName.luau` (PascalCase)
- **Controllers**: `ControllerName.luau` (PascalCase)
- **Functions**: `functionName()` (camelCase)
- **Variables**: `variableName` (camelCase)
- **Constants**: `CONSTANT_NAME` (UPPER_SNAKE_CASE)

### Code Structure
```lua
-- 1. Type declarations at top
-- 2. Constants
-- 3. Services/imports
-- 4. Class definition
-- 5. Constructor
-- 6. Lifecycle methods (Initialize, Start, Stop)
-- 7. Public methods
-- 8. Private methods
-- 9. Export
```

### Performance Rules
1. **ALWAYS** use object pooling for frequent operations
2. **ALWAYS** clean up connections in Stop() method
3. **NEVER** create memory leaks
4. **ALWAYS** use GameConstants for configuration
5. **ALWAYS** consider mobile performance

## 🚫 Common Mistakes to Avoid

### Architecture Violations
- ❌ Creating services outside the Services folder
- ❌ Putting game logic in init files
- ❌ Bypassing the ServiceRegistry
- ❌ Creating circular dependencies
- ❌ Not extending BaseService/BaseController

### Code Quality Issues
- ❌ Missing type annotations
- ❌ Not using --!strict
- ❌ Hardcoded values instead of constants
- ❌ Not handling errors properly
- ❌ Memory leaks from uncleaned connections

### Communication Problems
- ❌ Using RemoteEvents directly
- ❌ Not validating server data
- ❌ Excessive network traffic
- ❌ Not using proper error handling
- ❌ Client-side data validation only

## 📝 Documentation Requirements

### Every New Service/Controller Must Have:
1. **Purpose**: What does it do?
2. **Dependencies**: What does it depend on?
3. **Public Methods**: What can other services call?
4. **Events**: What events does it fire/listen to?
5. **Usage Examples**: How do you use it?

### Code Comments Requirements:
```lua
-- Public method that handles X functionality
-- @param player: Player - The player object
-- @param data: table - The data to process
-- @return boolean - Success status
function Service:PublicMethod(player: Player, data: table): boolean
    -- Implementation
end
```

## 🔄 Testing Rules

### Before Committing Code:
1. **Test** in Roblox Studio
2. **Verify** all services initialize correctly
3. **Check** for memory leaks
4. **Validate** performance impact
5. **Test** client-server communication

### Debug Commands:
```lua
-- Always test these in Studio
_G.ServiceRegistry:GetAllServices()
_G.ServiceRegistry:GetServiceState("ServiceName")
_G.Services.ServiceName:SomeMethod()
```

## 📚 Documentation Update Rules

### When Adding Features:
1. **Update** ARCHITECTURE.md if architecture changes
2. **Update** FEATURE_ROADMAP.md with new features
3. **Update** this document if new patterns emerge
4. **Create** usage examples
5. **Update** troubleshooting section

### When Modifying Existing Features:
1. **Update** relevant documentation
2. **Update** code comments
3. **Update** usage examples
4. **Add** migration notes if needed

## 🎮 Game-Specific Rules

### Card System Rules:
- **ALL** card logic MUST be in CardService
- **ALL** card data MUST use CardData type
- **ALL** card effects MUST be in EffectsController
- **ALL** card UI MUST be in UIController

### Battle System Rules:
- **ALL** battle logic MUST be in BattleService
- **ALL** battle state MUST be server-authoritative
- **ALL** battle UI MUST be in BattleController
- **ALL** battle effects MUST be in EffectsController

### Player Data Rules:
- **ALL** player data MUST go through PlayerDataService
- **ALL** data MUST be validated on server
- **ALL** data changes MUST be logged
- **ALL** data MUST be properly typed

## 🚀 Performance Rules

### Memory Management:
- **ALWAYS** use self._connections for tracking
- **ALWAYS** clean up in Stop() method
- **NEVER** create memory leaks
- **ALWAYS** use object pooling

### Network Optimization:
- **BATCH** updates when possible
- **MINIMIZE** remote event calls
- **USE** client-side prediction for UI
- **VALIDATE** everything on server

### Mobile Optimization:
- **LIMIT** concurrent animations
- **USE** texture streaming
- **OPTIMIZE** for 30fps minimum
- **CONSIDER** memory constraints

## 🔧 Emergency Procedures

### If Architecture is Broken:
1. **STOP** all development
2. **IDENTIFY** the violation
3. **FIX** the architecture first
4. **THEN** continue with features

### If Performance Degrades:
1. **PROFILE** the issue
2. **IDENTIFY** the bottleneck
3. **FIX** using established patterns
4. **TEST** performance again

### If Memory Leaks Occur:
1. **IDENTIFY** the leaking service
2. **CHECK** connection cleanup
3. **FIX** the Stop() method
4. **VERIFY** cleanup works

---

## 🎯 SUCCESS CRITERIA

An AI interaction is successful when:
- ✅ Architecture remains intact
- ✅ All rules are followed
- ✅ Code is properly documented
- ✅ Performance is maintained
- ✅ Type safety is preserved
- ✅ Tests pass in Studio

**REMEMBER**: These rules exist to maintain the quality and scalability of the codebase. Following them ensures the project can grow to support 30-50k concurrent players without technical debt.

---

**Last Updated**: Initial Version
**Next Review**: After first major feature implementation 