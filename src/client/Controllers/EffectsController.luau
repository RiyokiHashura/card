--!strict
-- EffectsController.luau
-- Advanced visual effects system for card reveals with rarity-based intensity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BaseController = require(ReplicatedStorage.Shared.Core.BaseController)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)
local RollTypes = require(ReplicatedStorage.Shared.Types.RollTypes)

type VisualEffect = UITypes.VisualEffect
type ScreenEffect = UITypes.ScreenEffect
type ScreenShakeData = UITypes.ScreenShakeData
type AudioCue = UITypes.AudioCue
type RarityVisualConfig = UITypes.RarityVisualConfig

local EffectsController = {}
EffectsController.__index = EffectsController
setmetatable(EffectsController, {__index = BaseController})

-- Rarity Visual Configurations (Research-based)
local RARITY_CONFIGS = {
    Common = {
        BorderColor = Color3.new(0.7, 0.7, 0.7),
        GlowColor = Color3.new(0.8, 0.8, 0.8),
        ParticleColor = Color3.new(0.9, 0.9, 0.9),
        EffectIntensity = 0.1,
        AnimationDuration = 0.5,
        AudioFrequency = 440,
        ScreenShakeIntensity = 0.0,
        FlashIntensity = 0.1
    },
    Rare = {
        BorderColor = Color3.new(0.2, 0.8, 0.2),
        GlowColor = Color3.new(0.3, 1.0, 0.3),
        ParticleColor = Color3.new(0.4, 0.9, 0.4),
        EffectIntensity = 0.3,
        AnimationDuration = 0.8,
        AudioFrequency = 523,
        ScreenShakeIntensity = 0.1,
        FlashIntensity = 0.2
    },
    Epic = {
        BorderColor = Color3.new(0.5, 0.2, 0.8),
        GlowColor = Color3.new(0.6, 0.3, 1.0),
        ParticleColor = Color3.new(0.7, 0.4, 0.9),
        EffectIntensity = 0.5,
        AnimationDuration = 1.2,
        AudioFrequency = 659,
        ScreenShakeIntensity = 0.2,
        FlashIntensity = 0.4
    },
    Legendary = {
        BorderColor = Color3.new(1.0, 0.5, 0.0),
        GlowColor = Color3.new(1.0, 0.6, 0.1),
        ParticleColor = Color3.new(1.0, 0.7, 0.2),
        EffectIntensity = 0.8,
        AnimationDuration = 1.8,
        AudioFrequency = 784,
        ScreenShakeIntensity = 0.4,
        FlashIntensity = 0.6
    },
    Mythical = {
        BorderColor = Color3.new(0.8, 0.2, 0.8),
        GlowColor = Color3.new(1.0, 0.3, 1.0),
        ParticleColor = Color3.new(0.9, 0.4, 0.9),
        EffectIntensity = 0.9,
        AnimationDuration = 2.2,
        AudioFrequency = 880,
        ScreenShakeIntensity = 0.6,
        FlashIntensity = 0.8
    },
    Ultimate = {
        BorderColor = Color3.new(1.0, 0.8, 0.0),
        GlowColor = Color3.new(1.0, 0.9, 0.1),
        ParticleColor = Color3.new(1.0, 1.0, 0.2),
        EffectIntensity = 1.0,
        AnimationDuration = 3.0,
        AudioFrequency = 1047,
        ScreenShakeIntensity = 0.8,
        FlashIntensity = 1.0
    }
}

-- Screen Shake Configuration
local SCREEN_SHAKE_CONFIG = {
    TraumaPower = 2.0,
    DecayRate = 0.8,
    MaxOffset = 20,
    MaxRotation = 2,
    NoiseScale = 100,
    UpdateFrequency = 0.016 -- 60 FPS
}

function EffectsController.new()
    	local self = BaseController.new("EffectsController", {})
    setmetatable(self, EffectsController)
    
    -- Effect tracking
    self._activeEffects = {} :: {[string]: VisualEffect}
    self._screenEffects = {} :: {[string]: ScreenEffect}
    self._audioSequences = {} :: {[string]: UITypes.AudioSequence}
    
    -- Screen shake system
    self._screenShakeData = {
        Intensity = 0,
        Duration = 0,
        Frequency = 0,
        Decay = 0,
        Trauma = 0,
        StartTime = 0
    }
    
    -- Camera reference
    self._camera = workspace.CurrentCamera
    self._originalCFrame = self._camera.CFrame
    
    -- Performance tracking
    self._effectCount = 0
    self._particleCount = 0
    self._audioCount = 0
    
    -- Effect pools for performance
    self._particlePool = {}
    self._effectPool = {}
    
    return self
end

function EffectsController:Initialize()
    self:_log("EffectsController initializing...")
    
    -- Initialize screen shake system
    self._screenShakeConnection = RunService.Heartbeat:Connect(function()
        self:_updateScreenShake()
    end)
    
    -- Initialize particle pools
    self:_initializeParticlePools()
    
    -- Initialize audio system
    self:_initializeAudioSystem()
    
    self:_log("EffectsController initialized successfully")
end

function EffectsController:Start()
    self:_log("EffectsController starting...")
    
    -- Start performance monitoring
    self:_startPerformanceMonitoring()
    
    self:_log("EffectsController started successfully")
end

function EffectsController:Stop()
    self:_log("EffectsController stopping...")
    
    -- Clear all effects
    self:ClearAllEffects()
    
    -- Clean up connections
    if self._screenShakeConnection then
        self._screenShakeConnection:Disconnect()
    end
    
    if self._performanceConnection then
        self._performanceConnection:Disconnect()
    end
    
    self:_log("EffectsController stopped")
end

-- Public Methods

function EffectsController:PlayCardRevealEffects(cardResult: RollTypes.CardRollResult, targetElement: GuiObject): string
    local effectID = self:_generateEffectID()
    local rarity = cardResult.Rarity
    local config = RARITY_CONFIGS[rarity] or RARITY_CONFIGS.Common
    
    self:_log("Playing card reveal effects for " .. rarity .. " card")
    
    -- Create visual effect sequence
    local effectSequence = self:_createCardEffectSequence(cardResult, targetElement, config)
    
    -- Play particle effects
    if cardResult.EffectIntensity > 0.3 then
        self:_playParticleEffects(targetElement, config, cardResult.EffectIntensity)
    end
    
    -- Play screen effects
    if cardResult.EffectIntensity > 0.5 then
        self:_playScreenEffects(config, cardResult.EffectIntensity)
    end
    
    -- Play audio effects
    self:_playAudioEffects(rarity, config, cardResult.IsPityResult)
    
    -- Trigger screen shake for high rarity cards
    if cardResult.EffectIntensity > 0.6 then
        self:TriggerScreenShake(config.ScreenShakeIntensity * cardResult.EffectIntensity, 0.5)
    end
    
    -- Store effect for tracking
    self._activeEffects[effectID] = {
        EffectID = effectID,
        EffectType = "CardReveal",
        Duration = config.AnimationDuration * 1000,
        StartTime = os.clock(),
        EndTime = os.clock() + config.AnimationDuration,
        Properties = {
            Rarity = rarity,
            Intensity = cardResult.EffectIntensity,
            IsPityResult = cardResult.IsPityResult
        },
        Target = targetElement,
        IsActive = true
    }
    
    return effectID
end

function EffectsController:TriggerScreenShake(intensity: number, duration: number)
    local currentTime = os.clock()
    
    -- Apply trauma-based screen shake
    local trauma = math.min(1.0, intensity)
    
    self._screenShakeData = {
        Intensity = intensity,
        Duration = duration,
        Frequency = 30, -- 30 Hz frequency
        Decay = SCREEN_SHAKE_CONFIG.DecayRate,
        Trauma = trauma,
        StartTime = currentTime
    }
    
    self:_log("Screen shake triggered: intensity=" .. intensity .. ", duration=" .. duration)
end

function EffectsController:PlayScreenFlash(color: Color3, intensity: number, duration: number): string
    local effectID = self:_generateEffectID()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create flash effect
    local flashFrame = Instance.new("Frame")
    flashFrame.Name = "ScreenFlash_" .. effectID
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.Position = UDim2.new(0, 0, 0, 0)
    flashFrame.BackgroundColor3 = color
    flashFrame.BackgroundTransparency = 1
    flashFrame.ZIndex = 1000
    flashFrame.Parent = playerGui
    
    -- Animate flash
    local flashIn = TweenService:Create(flashFrame, TweenInfo.new(duration * 0.1), {
        BackgroundTransparency = 1 - intensity
    })
    
    local flashOut = TweenService:Create(flashFrame, TweenInfo.new(duration * 0.9), {
        BackgroundTransparency = 1
    })
    
    flashIn:Play()
    flashIn.Completed:Connect(function()
        flashOut:Play()
        flashOut.Completed:Connect(function()
            flashFrame:Destroy()
        end)
    end)
    
    -- Track effect
    self._screenEffects[effectID] = {
        EffectName = "ScreenFlash",
        Duration = duration,
        Intensity = intensity,
        Color = color,
        StartTime = os.clock(),
        FadeInTime = duration * 0.1,
        FadeOutTime = duration * 0.9,
        Properties = {
            Frame = flashFrame
        }
    }
    
    return effectID
end

function EffectsController:CreateParticleEffect(target: GuiObject, config: RarityVisualConfig, duration: number): string
    local effectID = self:_generateEffectID()
    
    -- Create particle container
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleContainer_" .. effectID
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.Position = UDim2.new(0, 0, 0, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = 50
    particleContainer.Parent = target
    
    -- Create multiple particle systems
    local particleCount = math.floor(config.EffectIntensity * 20) + 5
    
    for i = 1, particleCount do
        spawn(function()
            self:_createParticle(particleContainer, config, duration)
        end)
    end
    
    -- Schedule cleanup
    Debris:AddItem(particleContainer, duration)
    
    return effectID
end

function EffectsController:CreateGlowEffect(target: GuiObject, config: RarityVisualConfig, duration: number): string
    local effectID = self:_generateEffectID()
    
    -- Create glow effect
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowEffect_" .. effectID
    glowFrame.Size = UDim2.new(1, 20, 1, 20)
    glowFrame.Position = UDim2.new(0, -10, 0, -10)
    glowFrame.BackgroundColor3 = config.GlowColor
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = target.ZIndex - 1
    glowFrame.Parent = target.Parent
    
    -- Add corner radius if target has one
    if target:FindFirstChild("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = target.UICorner.CornerRadius
        corner.Parent = glowFrame
    end
    
    -- Animate glow
    local glowIn = TweenService:Create(glowFrame, TweenInfo.new(duration * 0.2), {
        BackgroundTransparency = 0.3
    })
    
    local glowPulse = TweenService:Create(glowFrame, TweenInfo.new(duration * 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.1
    })
    
    local glowOut = TweenService:Create(glowFrame, TweenInfo.new(duration * 0.2), {
        BackgroundTransparency = 1
    })
    
    glowIn:Play()
    glowIn.Completed:Connect(function()
        glowPulse:Play()
        
        spawn(function()
            wait(duration * 0.6)
            glowPulse:Cancel()
            glowOut:Play()
            glowOut.Completed:Connect(function()
                glowFrame:Destroy()
            end)
        end)
    end)
    
    return effectID
end

function EffectsController:PlayAudioSequence(rarity: string, isPityResult: boolean): string
    local sequenceID = self:_generateEffectID()
    local config = RARITY_CONFIGS[rarity] or RARITY_CONFIGS.Common
    
    -- Create audio sequence
    local audioSequence = {
        SequenceID = sequenceID,
        AudioCues = {},
        TotalDuration = 0,
        IsPlaying = true,
        CurrentCue = 1
    }
    
    -- Add base reveal sound
    table.insert(audioSequence.AudioCues, {
        SoundID = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.3,
        Pitch = config.AudioFrequency / 440,
        PlayTime = 0,
        Duration = 0.5,
        FadeIn = 0.1,
        FadeOut = 0.1,
        Loop = false,
        Rarity = rarity
    })
    
    -- Add pity result sound
    if isPityResult then
        table.insert(audioSequence.AudioCues, {
            SoundID = "rbxasset://sounds/button_rollover.wav",
            Volume = 0.5,
            Pitch = 1.2,
            PlayTime = 0.3,
            Duration = 0.8,
            FadeIn = 0.2,
            FadeOut = 0.2,
            Loop = false,
            Rarity = rarity
        })
    end
    
    -- Add rarity-specific sound
    if config.EffectIntensity > 0.5 then
        table.insert(audioSequence.AudioCues, {
            SoundID = "rbxasset://sounds/impact_generic.mp3",
            Volume = config.EffectIntensity * 0.4,
            Pitch = 0.8 + (config.EffectIntensity * 0.4),
            PlayTime = 0.5,
            Duration = 1.0,
            FadeIn = 0.1,
            FadeOut = 0.3,
            Loop = false,
            Rarity = rarity
        })
    end
    
    -- Calculate total duration
    local totalDuration = 0
    for _, cue in ipairs(audioSequence.AudioCues) do
        totalDuration = math.max(totalDuration, cue.PlayTime + cue.Duration)
    end
    audioSequence.TotalDuration = totalDuration
    
    -- Play sequence
    self:_playAudioSequence(audioSequence)
    
    -- Store sequence
    self._audioSequences[sequenceID] = audioSequence
    
    return sequenceID
end

function EffectsController:ClearAllEffects()
    -- Clear visual effects
    for effectID, effect in pairs(self._activeEffects) do
        if effect.Target and effect.Target.Parent then
            -- Clean up effect elements
            local effectElements = effect.Target:GetChildren()
            for _, element in ipairs(effectElements) do
                if string.find(element.Name, "Effect") or string.find(element.Name, "Particle") then
                    element:Destroy()
                end
            end
        end
    end
    
    -- Clear screen effects
    for effectID, effect in pairs(self._screenEffects) do
        if effect.Properties.Frame then
            effect.Properties.Frame:Destroy()
        end
    end
    
    -- Clear audio sequences
    for sequenceID, sequence in pairs(self._audioSequences) do
        -- Stop audio playback
        sequence.IsPlaying = false
    end
    
    -- Reset screen shake
    self._screenShakeData.Trauma = 0
    self._screenShakeData.Intensity = 0
    
    -- Clear tracking tables
    self._activeEffects = {}
    self._screenEffects = {}
    self._audioSequences = {}
    
    self:_log("All effects cleared")
end

function EffectsController:GetActiveEffectCount(): number
    return self._effectCount
end

function EffectsController:GetPerformanceMetrics(): UITypes.PerformanceMetrics
    return {
        FrameRate = 1 / RunService.Heartbeat:Wait(),
        MemoryUsage = collectgarbage("count"),
        ActiveAnimations = #TweenService:GetPlayingTweens(),
        ActiveEffects = self._effectCount,
        RenderTime = RunService.Heartbeat:Wait() * 1000,
        LastUpdateTime = os.clock()
    }
end

-- Private Methods

function EffectsController:_createCardEffectSequence(cardResult: RollTypes.CardRollResult, targetElement: GuiObject, config: RarityVisualConfig): UITypes.CardAnimationSequence
    local sequence = {
        CardID = cardResult.Card.ID,
        Rarity = cardResult.Rarity,
        Animations = {},
        TotalDuration = config.AnimationDuration,
        EffectIntensity = cardResult.EffectIntensity
    }
    
    -- Scale animation
    table.insert(sequence.Animations, {
        StepName = "ScaleUp",
        StartTime = 0,
        Duration = config.AnimationDuration * 0.3,
        AnimationType = "Size",
        Properties = {
            Size = UDim2.new(1.1, 0, 1.1, 0)
        },
        EasingData = {
            Duration = config.AnimationDuration * 0.3,
            EasingStyle = Enum.EasingStyle.Back,
            EasingDirection = Enum.EasingDirection.Out,
            RepeatCount = 0,
            Reverses = false,
            DelayTime = 0
        },
        AudioCue = "scale_up"
    })
    
    -- Scale back
    table.insert(sequence.Animations, {
        StepName = "ScaleDown",
        StartTime = config.AnimationDuration * 0.3,
        Duration = config.AnimationDuration * 0.2,
        AnimationType = "Size",
        Properties = {
            Size = UDim2.new(1, 0, 1, 0)
        },
        EasingData = {
            Duration = config.AnimationDuration * 0.2,
            EasingStyle = Enum.EasingStyle.Back,
            EasingDirection = Enum.EasingDirection.Out,
            RepeatCount = 0,
            Reverses = false,
            DelayTime = 0
        }
    })
    
    -- Play animation sequence
    self:_playAnimationSequence(sequence, targetElement)
    
    return sequence
end

function EffectsController:_playAnimationSequence(sequence: UITypes.CardAnimationSequence, targetElement: GuiObject)
    for _, animation in ipairs(sequence.Animations) do
        spawn(function()
            wait(animation.StartTime)
            
            local tween = TweenService:Create(
                targetElement,
                TweenInfo.new(
                    animation.Duration,
                    animation.EasingData.EasingStyle,
                    animation.EasingData.EasingDirection,
                    animation.EasingData.RepeatCount,
                    animation.EasingData.Reverses,
                    animation.EasingData.DelayTime
                ),
                animation.Properties
            )
            
            tween:Play()
            
            if animation.AudioCue then
                -- Play audio cue
                self:_playAudioCue(animation.AudioCue)
            end
        end)
    end
end

function EffectsController:_playParticleEffects(target: GuiObject, config: RarityVisualConfig, intensity: number)
    -- Create sparkle particles
    self:CreateParticleEffect(target, config, config.AnimationDuration * 0.8)
    
    -- Create glow effect
    self:CreateGlowEffect(target, config, config.AnimationDuration)
    
    -- Create additional effects for high-rarity cards
    if intensity > 0.7 then
        -- Create burst effect
        spawn(function()
            wait(config.AnimationDuration * 0.2)
            self:_createBurstEffect(target, config)
        end)
    end
end

function EffectsController:_playScreenEffects(config: RarityVisualConfig, intensity: number)
    -- Screen flash for high-intensity effects
    if intensity > 0.6 then
        self:PlayScreenFlash(config.GlowColor, config.FlashIntensity * intensity, 0.3)
    end
    
    -- Screen distortion for ultimate rarity
    if intensity >= 1.0 then
        self:_createScreenDistortion(config, 0.5)
    end
end

function EffectsController:_playAudioEffects(rarity: string, config: RarityVisualConfig, isPityResult: boolean)
    self:PlayAudioSequence(rarity, isPityResult)
end

function EffectsController:_createParticle(container: Frame, config: RarityVisualConfig, duration: number)
    local particle = Instance.new("Frame")
    particle.Name = "Particle"
    particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
    particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
    particle.BackgroundColor3 = config.ParticleColor
    particle.BackgroundTransparency = 0.3
    particle.ZIndex = 100
    particle.Parent = container
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = particle
    
    -- Animate particle
    local endPosition = UDim2.new(
        math.random(),
        math.random(-50, 50),
        math.random(),
        math.random(-50, 50)
    )
    
    local moveTween = TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
        Position = endPosition,
        BackgroundTransparency = 1
    })
    
    moveTween:Play()
    moveTween.Completed:Connect(function()
        particle:Destroy()
    end)
end

function EffectsController:_createBurstEffect(target: GuiObject, config: RarityVisualConfig)
    local burstCount = math.floor(config.EffectIntensity * 8) + 4
    
    for i = 1, burstCount do
        local burst = Instance.new("Frame")
        burst.Name = "BurstEffect"
        burst.Size = UDim2.new(0, 4, 0, 20)
        burst.Position = UDim2.new(0.5, -2, 0.5, -10)
        burst.BackgroundColor3 = config.GlowColor
        burst.BackgroundTransparency = 0.2
        burst.ZIndex = 75
        burst.Parent = target
        
        -- Rotate burst
        burst.Rotation = (360 / burstCount) * i
        
        -- Animate burst
        local scaleTween = TweenService:Create(burst, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 2, 0, 60),
            BackgroundTransparency = 1
        })
        
        scaleTween:Play()
        scaleTween.Completed:Connect(function()
            burst:Destroy()
        end)
    end
end

function EffectsController:_createScreenDistortion(config: RarityVisualConfig, duration: number)
    -- Create subtle screen distortion effect
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local distortionFrame = Instance.new("Frame")
    distortionFrame.Name = "ScreenDistortion"
    distortionFrame.Size = UDim2.new(1, 0, 1, 0)
    distortionFrame.Position = UDim2.new(0, 0, 0, 0)
    distortionFrame.BackgroundColor3 = config.GlowColor
    distortionFrame.BackgroundTransparency = 0.95
    distortionFrame.ZIndex = 999
    distortionFrame.Parent = playerGui
    
    -- Animate distortion
    local distortTween = TweenService:Create(distortionFrame, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true), {
        BackgroundTransparency = 0.9
    })
    
    distortTween:Play()
    distortTween.Completed:Connect(function()
        distortionFrame:Destroy()
    end)
end

function EffectsController:_updateScreenShake()
    local currentTime = os.clock()
    local elapsed = currentTime - self._screenShakeData.StartTime
    
    if self._screenShakeData.Trauma <= 0 or elapsed > self._screenShakeData.Duration then
        -- Reset camera if shake is done
        if self._screenShakeData.Trauma > 0 then
            self._camera.CFrame = self._originalCFrame
            self._screenShakeData.Trauma = 0
        end
        return
    end
    
    -- Update trauma decay
    self._screenShakeData.Trauma = self._screenShakeData.Trauma * (1 - self._screenShakeData.Decay * RunService.Heartbeat:Wait())
    
    -- Calculate shake intensity
    local shakeIntensity = self._screenShakeData.Trauma ^ SCREEN_SHAKE_CONFIG.TraumaPower
    
    -- Generate noise-based shake
    local noise = math.noise(currentTime * self._screenShakeData.Frequency, 0, 0)
    local shakeX = noise * SCREEN_SHAKE_CONFIG.MaxOffset * shakeIntensity
    local shakeY = math.noise(0, currentTime * self._screenShakeData.Frequency, 0) * SCREEN_SHAKE_CONFIG.MaxOffset * shakeIntensity
    local shakeRot = math.noise(0, 0, currentTime * self._screenShakeData.Frequency) * SCREEN_SHAKE_CONFIG.MaxRotation * shakeIntensity
    
    -- Apply shake to camera
    self._camera.CFrame = self._originalCFrame * CFrame.new(shakeX, shakeY, 0) * CFrame.Angles(0, 0, math.rad(shakeRot))
    
    -- Update original CFrame reference
    self._originalCFrame = workspace.CurrentCamera.CFrame * CFrame.new(-shakeX, -shakeY, 0) * CFrame.Angles(0, 0, -math.rad(shakeRot))
end

function EffectsController:_playAudioSequence(sequence: UITypes.AudioSequence)
    for _, cue in ipairs(sequence.AudioCues) do
        spawn(function()
            wait(cue.PlayTime)
            
            if sequence.IsPlaying then
                local sound = Instance.new("Sound")
                sound.SoundId = cue.SoundID
                sound.Volume = cue.Volume
                sound.Pitch = cue.Pitch
                sound.Parent = SoundService
                
                sound:Play()
                
                -- Clean up sound after it finishes
                sound.Ended:Connect(function()
                    sound:Destroy()
                end)
            end
        end)
    end
end

function EffectsController:_playAudioCue(cueName: string)
    -- Play simple audio cue
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.2
    sound.Pitch = 1.0
    sound.Parent = SoundService
    
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function EffectsController:_initializeParticlePools()
    -- Initialize particle object pools for performance
    self._particlePool = {}
    self._effectPool = {}
    
    self:_log("Particle pools initialized")
end

function EffectsController:_initializeAudioSystem()
    -- Initialize audio system
    self._audioCount = 0
    self:_log("Audio system initialized")
end

function EffectsController:_startPerformanceMonitoring()
    self._performanceConnection = RunService.Heartbeat:Connect(function()
        -- Update effect counts
        self._effectCount = 0
        for _ in pairs(self._activeEffects) do
            self._effectCount += 1
        end
        
        -- Clean up expired effects
        local currentTime = os.clock()
        for effectID, effect in pairs(self._activeEffects) do
            if currentTime > effect.EndTime then
                self._activeEffects[effectID] = nil
            end
        end
        
        -- Clean up expired screen effects
        for effectID, effect in pairs(self._screenEffects) do
            if currentTime > effect.StartTime + effect.Duration then
                self._screenEffects[effectID] = nil
            end
        end
    end)
end

function EffectsController:_generateEffectID(): string
    return "effect_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

return EffectsController.new() 