--!strict
-- UIConstants.luau
-- Research-based UI constants for professional card game design

local UIConstants = {}

-- Card Dimensions (Research-based 2:3 aspect ratio)
UIConstants.Card = {
	-- Base dimensions
	BaseWidth = 120,
	BaseHeight = 168,
	AspectRatio = 0.666, -- 2:3 ratio
	
	-- Size constraints
	Mobile = {
		MinWidth = 100,
		MinHeight = 140,
		MaxWidth = 160,
		MaxHeight = 224
	},
	Desktop = {
		MinWidth = 120,
		MinHeight = 168,
		MaxWidth = 240,
		MaxHeight = 336
	}
}

-- Touch Targets (Industry Standard)
UIConstants.TouchTarget = {
	MinSize = 44, -- 10mm x 10mm physical
	Recommended = 48,
	Comfortable = 56
}

-- Spacing (Research-based)
UIConstants.Spacing = {
	Micro = 4,
	Small = 8,
	Medium = 16,
	Large = 24,
	XLarge = 32,
	
	-- Card-specific spacing
	CardGrid = 16, -- Mobile
	CardGridDesktop = 24,
	CardPadding = 8
}

-- Typography
UIConstants.Typography = {
	-- Minimum readable sizes
	BodyMin = 16,
	UIMin = 14,
	CaptionMin = 12,
	
	-- Recommended sizes
	Heading1 = 32,
	Heading2 = 24,
	Heading3 = 20,
	Body = 18,
	UI = 16,
	Caption = 14
}

-- Colors (Industry Standard Rarity Colors)
UIConstants.RarityColors = {
	Common = Color3.fromRGB(157, 157, 157), -- #9d9d9d Gray
	Uncommon = Color3.fromRGB(30, 255, 0), -- #1eff00 Green
	Rare = Color3.fromRGB(0, 112, 221), -- #0070dd Blue
	Epic = Color3.fromRGB(163, 53, 238), -- #a335ee Purple
	Legendary = Color3.fromRGB(255, 128, 0), -- #ff8000 Orange
	Ultimate = Color3.fromRGB(255, 0, 255), -- #ff00ff Magenta
	
	-- UI Colors
	Background = Color3.fromRGB(25, 25, 35),
	Surface = Color3.fromRGB(35, 35, 45),
	Primary = Color3.fromRGB(255, 215, 0), -- Gold
	Success = Color3.fromRGB(76, 175, 80),
	Warning = Color3.fromRGB(255, 193, 7),
	Error = Color3.fromRGB(244, 67, 54),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 180)
}

-- Animation Timings (Dopamine-optimized)
UIConstants.Animation = {
	-- Micro-interactions
	Instant = 0.1,
	Fast = 0.2,
	Normal = 0.3,
	Slow = 0.5,
	
	-- Card reveal sequence (dopamine-optimized)
	Anticipation = 1.2, -- Builds tension
	Reveal = 0.4, -- Peak excitement
	Confirmation = 0.15, -- Settle
	
	-- Easing styles
	EaseIn = Enum.EasingStyle.Quad,
	EaseOut = Enum.EasingStyle.Quad,
	EaseInOut = Enum.EasingStyle.Quad,
	Bounce = Enum.EasingStyle.Back,
	Elastic = Enum.EasingStyle.Elastic
}

-- Performance Targets
UIConstants.Performance = {
	-- Mobile constraints
	MaxParticles = 150,
	MaxEmitters = 5,
	MaxConcurrentTweens = 10,
	
	-- Memory targets
	MaxMemoryMB = 200,
	MaxDrawCalls = 1000
}

-- Screen Detection
function UIConstants:GetDeviceType()
	local camera = workspace.CurrentCamera
	if not camera then return "Desktop" end
	
	local viewportSize = camera.ViewportSize
	local screenArea = viewportSize.X * viewportSize.Y
	
	-- Under 1MP = Mobile
	if screenArea < 1000000 then
		return "Mobile"
	else
		return "Desktop"
	end
end

function UIConstants:IsMobile()
	return self:GetDeviceType() == "Mobile"
end

-- Responsive sizing helpers
function UIConstants:GetCardSize()
	local deviceType = self:GetDeviceType()
	if deviceType == "Mobile" then
		return Vector2.new(self.Card.Mobile.MinWidth, self.Card.Mobile.MinHeight)
	else
		return Vector2.new(self.Card.BaseWidth, self.Card.BaseHeight)
	end
end

function UIConstants:GetTouchTargetSize()
	return self:IsMobile() and self.TouchTarget.MinSize or self.TouchTarget.Recommended
end

return UIConstants 