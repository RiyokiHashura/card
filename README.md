# 🎴 Anime Card Clash

A next-generation anime card collection game for Roblox, designed to support 30-50k concurrent players with AAA-quality visuals and psychological engagement systems.

## 🚀 **FOR AI DEVELOPERS - START HERE**

### 📋 **REQUIRED READING** (In Order)
1. **[AI_QUICK_START_GUIDE.md](AI_QUICK_START_GUIDE.md)** - 30-second overview and next steps
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system architecture
3. **[AI_DEVELOPMENT_RULES.md](AI_DEVELOPMENT_RULES.md)** - Mandatory development rules
4. **[FEATURE_ROADMAP.md](FEATURE_ROADMAP.md)** - Implementation roadmap

### 🎯 **CURRENT STATUS**
- ✅ **Core Architecture**: Complete and bulletproof
- 🔄 **Next Task**: Implement Card Database System
- 🎮 **Goal**: MVP ready for testing

## 🏗️ Architecture Overview

```
Service-Based Modular Architecture
├── ServiceRegistry (Dependency Injection)
├── BaseService (Server Foundation)
├── BaseController (Client Foundation)
├── RemoteEventHandler (Communication)
└── GameConstants (Research-Based Config)
```

## 📁 Project Structure

```
src/
├── client/
│   ├── init.client.luau         # ✅ Client bootstrap
│   └── Controllers/             # 🔄 Client-side controllers
├── server/
│   ├── init.server.luau         # ✅ Server bootstrap
│   └── Services/                # 🔄 Server-side services
└── shared/
    ├── Core/                    # ✅ Framework foundation
    ├── Constants/               # ✅ Game constants
    ├── Utils/                   # ✅ Utility functions
    ├── Data/                    # 🔄 Card database
    └── Types/                   # 🔄 Type definitions
```

## 🎮 Game Vision

### **Core Loop**
1. **Roll** for anime cards with psychological timing
2. **Collect** cards with pity system and progression
3. **Battle** with elevated 2D combat system
4. **Progress** through level-based improvements

### **Key Features**
- **Modular Architecture**: Scalable to 50k+ players
- **Psychological Engagement**: Research-based retention systems
- **Visual Polish**: AAA-quality effects within Roblox limits
- **Performance Optimized**: 60fps on mid-range devices
- **Ethical Monetization**: No pay-to-win, value-driven purchases

## 🔧 Development

### **Setup**
```bash
rojo serve
```
Then connect to localhost:8000 in Roblox Studio.

### **Testing**
```lua
-- In Studio Command Bar
_G.ServiceRegistry:GetAllServices()
_G.Services.ServiceName:MethodName()
```

### **Adding Features**
1. Read documentation first
2. Follow AI_DEVELOPMENT_RULES.md
3. Extend BaseService/BaseController
4. Update FEATURE_ROADMAP.md

## 📊 Research Foundation

This project is built on extensive research covering:
- **Animation Timing**: 50-100ms impact frames, 200-350ms card plays
- **Screen Shake**: Trauma-based system with 0.8 decay rate
- **Audio Design**: Frequency layering, 2ms sync precision
- **Color Psychology**: Industry-standard rarity colors
- **Performance**: 250 concurrent tweens, 50MB texture budget
- **Monetization**: 77% conversion in 14 days, 0.5% legendary rates

## 🎯 Success Metrics

### **Technical**
- 60fps on mid-range devices
- <100MB memory usage
- <5 second load times
- 99.9% uptime

### **Engagement**
- >50% Day 7 retention
- 22+ minute sessions
- 3+ rolls per session
- 80%+ battle completion

### **Revenue**
- >5% conversion rate
- $2+ ARPU
- Ethical monetization
- Long-term sustainability

## 🚨 **CRITICAL RULES**

1. **NEVER** modify Core/ architecture
2. **ALWAYS** extend BaseService/BaseController
3. **ALWAYS** use --!strict typing
4. **ALWAYS** follow ServiceRegistry pattern
5. **ALWAYS** read documentation first

## 📝 Contributing

This project is designed for AI-driven development. All contributions must:
- Follow AI_DEVELOPMENT_RULES.md
- Maintain architecture integrity
- Include proper documentation
- Pass Studio testing

## 🏆 Credits

- **Architecture**: Service-based modular design
- **Research**: Industry analysis and psychological optimization
- **Performance**: Mobile-first optimization strategies
- **Vision**: Next-generation Roblox gaming experience

---

## 🎯 **NEXT ACTIONS**

**For AI Developers**: Start with [AI_QUICK_START_GUIDE.md](AI_QUICK_START_GUIDE.md)

**Current Priority**: Implement Card Database System

**Goal**: Create the foundation for all card-related features

---

**Last Updated**: Initial Version
**License**: Proprietary# card
