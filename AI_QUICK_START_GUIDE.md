# 🚀 AI Quick Start Guide - Anime Card Clash

## ⚡ 30-Second Overview

**What is this?**: Anime card collection game for Roblox targeting 30-50k concurrent players

**Current Status**: Core architecture complete, ready for card system implementation

**Next Task**: Implement Card Database System (see FEATURE_ROADMAP.md)

**Architecture**: Service-based modular system with dependency injection

## 🎯 **CRITICAL** - Read These First

1. **ARCHITECTURE.md** - Understand the system flow
2. **AI_DEVELOPMENT_RULES.md** - Follow these rules religiously
3. **FEATURE_ROADMAP.md** - See what needs to be built

## 📁 Project Structure

```
src/
├── client/
│   ├── init.client.luau         # ✅ Client bootstrap (DONE)
│   └── Controllers/             # 🔄 Add controllers here
├── server/
│   ├── init.server.luau         # ✅ Server bootstrap (DONE)
│   └── Services/                # 🔄 Add services here
└── shared/
    ├── Core/                    # ✅ Framework (DONE)
    ├── Constants/               # ✅ Game constants (DONE)
    ├── Utils/                   # ✅ Utilities (DONE)
    ├── Data/                    # 🔄 Add card data here
    └── Types/                   # 🔄 Add type definitions here
```

## 🔥 **NEXT STEPS** (In Order)

### 1. Card Database System
**Files to Create**:
- `src/shared/Types/CardTypes.luau`
- `src/shared/Data/CardDatabase.luau`
- `src/shared/Data/AnimeCharacters.luau`

**Template**:
```lua
--!strict
-- CardTypes.luau
export type CardData = {
    ID: string,
    Name: string,
    Rarity: string,
    Attack: number,
    Defense: number,
    Special: string,
    Series: string,
    Image: string
}
```

### 2. Player Data Service
**Files to Create**:
- `src/shared/Types/PlayerTypes.luau`
- `src/server/Services/PlayerDataService.luau`

### 3. Card Roll System
**Files to Create**:
- `src/server/Services/CardRollService.luau`

## 💡 **QUICK TIPS**

### Creating a New Service
1. Extend `BaseService` (see AI_DEVELOPMENT_RULES.md)
2. Return `ServiceName.new()` at the end
3. Auto-loaded by framework

### Creating a New Controller
1. Extend `BaseController` (see AI_DEVELOPMENT_RULES.md)
2. Return `ControllerName.new()` at the end
3. Auto-loaded by framework

### Testing
```lua
-- In Studio Command Bar
_G.ServiceRegistry:GetAllServices()
_G.Services.ServiceName:MethodName()
```

## 🚨 **COMMON MISTAKES TO AVOID**

1. ❌ Don't modify Core/ files
2. ❌ Don't bypass ServiceRegistry
3. ❌ Don't forget --!strict
4. ❌ Don't skip type annotations
5. ❌ Don't use RemoteEvents directly

## 📊 **RESEARCH DATA AVAILABLE**

We have extensive research on:
- ✅ Animation timings (GameConstants.AnimationTiming)
- ✅ Screen shake formulas (GameConstants.ScreenShake)
- ✅ Audio frequencies (GameConstants.Audio)
- ✅ Performance limits (GameConstants.Performance)
- ✅ Rarity colors (GameConstants.RarityColors)
- ✅ Drop rates (GameConstants.Balance.BaseDropRates)

## 🎮 **GAME VISION**

- **Target**: 30-50k concurrent players
- **Revenue**: Ethical monetization, no pay-to-win
- **Polish**: AAA-quality visuals within Roblox limits
- **Performance**: 60fps on mid-range devices
- **Retention**: >50% Day 7 retention

## 🔧 **DEVELOPMENT FLOW**

1. **Read Documentation** (ARCHITECTURE.md, AI_DEVELOPMENT_RULES.md)
2. **Check Roadmap** (FEATURE_ROADMAP.md)
3. **Create Files** (Follow templates)
4. **Test in Studio** (Use debug commands)
5. **Update Documentation** (Keep roadmap current)

## 📝 **REMEMBER**

- Every service/controller extends base classes
- Use GameConstants for all configuration
- Follow the established patterns
- Test everything in Studio
- Document your changes

**SUCCESS = Architecture intact + Rules followed + Feature works**

---

## 🎯 **CURRENT PRIORITY**

**IMPLEMENT**: Card Database System

**WHY**: Foundation for all other features

**START HERE**: Create `src/shared/Types/CardTypes.luau`

---

**Last Updated**: Initial Version 