--!strict
-- UIUtils.luau
-- Professional UI creation utilities following research guidelines

local TweenService = game:GetService("TweenService")
local UIConstants = require(script.Parent.Parent.Constants.UIConstants)

local UIUtils = {}

-- Create a responsive button with proper sizing and styling
function UIUtils.CreateButton(config: {
	Text: string,
	Size: Vector2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	TextColor: Color3?,
	Font: Enum.Font?,
	TextSize: number?,
	Parent: GuiObject?
}): TextButton
	
	local button = Instance.new("TextButton")
	
	-- Set responsive size
	local targetSize = config.Size or Vector2.new(180, UIConstants:GetTouchTargetSize())
	button.Size = UDim2.new(0, targetSize.X, 0, targetSize.Y)
	
	-- Position and anchoring
	button.Position = config.Position or UDim2.new(0.5, 0, 0.5, 0)
	button.AnchorPoint = config.AnchorPoint or Vector2.new(0.5, 0.5)
	
	-- Styling
	button.BackgroundColor3 = config.BackgroundColor or UIConstants.RarityColors.Primary
	button.BorderSizePixel = 0
	button.Text = config.Text
	button.TextColor3 = config.TextColor or UIConstants.RarityColors.Text
	button.TextSize = config.TextSize or UIConstants.Typography.UI
	button.Font = config.Font or Enum.Font.GothamBold
	button.TextStrokeTransparency = 0.5
	
	-- Add size constraints for mobile optimization
	local sizeConstraint = Instance.new("UISizeConstraint")
	local minSize = UIConstants:GetTouchTargetSize()
	sizeConstraint.MinSize = Vector2.new(minSize, minSize)
	sizeConstraint.MaxSize = Vector2.new(targetSize.X * 2, targetSize.Y * 1.5)
	sizeConstraint.Parent = button
	
	-- Add modern corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	-- Add gradient for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.1)),
		ColorSequenceKeypoint.new(1, button.BackgroundColor3:Lerp(Color3.new(0, 0, 0), 0.1))
	})
	gradient.Rotation = 90
	gradient.Parent = button
	
	if config.Parent then
		button.Parent = config.Parent
	end
	
	return button
end

-- Create a professional card frame with proper aspect ratio
function UIUtils.CreateCardFrame(config: {
	Size: Vector2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	Rarity: string?,
	Parent: GuiObject?
}): Frame
	
	local cardFrame = Instance.new("Frame")
	
	-- Set card size based on device
	local cardSize = config.Size or UIConstants:GetCardSize()
	cardFrame.Size = UDim2.new(0, cardSize.X, 0, cardSize.Y)
	
	-- Position and anchoring
	cardFrame.Position = config.Position or UDim2.new(0.5, 0, 0.5, 0)
	cardFrame.AnchorPoint = config.AnchorPoint or Vector2.new(0.5, 0.5)
	
	-- Background color based on rarity
	local rarity = config.Rarity or "Common"
	cardFrame.BackgroundColor3 = config.BackgroundColor or UIConstants.RarityColors[rarity]
	cardFrame.BorderSizePixel = 0
	
	-- Add aspect ratio constraint
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = UIConstants.Card.AspectRatio
	aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectRatio.Parent = cardFrame
	
	-- Add size constraints
	local sizeConstraint = Instance.new("UISizeConstraint")
	if UIConstants:IsMobile() then
		sizeConstraint.MinSize = Vector2.new(UIConstants.Card.Mobile.MinWidth, UIConstants.Card.Mobile.MinHeight)
		sizeConstraint.MaxSize = Vector2.new(UIConstants.Card.Mobile.MaxWidth, UIConstants.Card.Mobile.MaxHeight)
	else
		sizeConstraint.MinSize = Vector2.new(UIConstants.Card.Desktop.MinWidth, UIConstants.Card.Desktop.MinHeight)
		sizeConstraint.MaxSize = Vector2.new(UIConstants.Card.Desktop.MaxWidth, UIConstants.Card.Desktop.MaxHeight)
	end
	sizeConstraint.Parent = cardFrame
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = cardFrame
	
	-- Add subtle stroke for definition
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = cardFrame
	
	if config.Parent then
		cardFrame.Parent = config.Parent
	end
	
	return cardFrame
end

-- Create dopamine-optimized card reveal animation
function UIUtils.PlayCardRevealAnimation(cardFrame: GuiObject, rarity: string)
	-- Phase 1: Anticipation (builds tension)
	local anticipationInfo = TweenInfo.new(
		UIConstants.Animation.Anticipation,
		UIConstants.Animation.EaseIn,
		Enum.EasingDirection.In
	)
	
	local shrinkTween = TweenService:Create(cardFrame, anticipationInfo, {
		Size = UDim2.new(0.8, 0, 0.8, 0),
		BackgroundTransparency = 0.3
	})
	
	shrinkTween:Play()
	
	-- Phase 2: Explosive reveal (dopamine trigger)
	shrinkTween.Completed:Connect(function()
		local revealInfo = TweenInfo.new(
			UIConstants.Animation.Reveal,
			UIConstants.Animation.Bounce,
			Enum.EasingDirection.Out
		)
		
		local targetSize = rarity == "Legendary" and 1.3 or 1.1
		local revealTween = TweenService:Create(cardFrame, revealInfo, {
			Size = UDim2.new(targetSize, 0, targetSize, 0),
			BackgroundTransparency = 0,
			Rotation = rarity == "Legendary" and 360 or 180
		})
		
		revealTween:Play()
		
		-- Phase 3: Settle (confirmation)
		revealTween.Completed:Connect(function()
			local settleInfo = TweenInfo.new(
				UIConstants.Animation.Confirmation,
				UIConstants.Animation.EaseOut,
				Enum.EasingDirection.Out
			)
			
			local settleTween = TweenService:Create(cardFrame, settleInfo, {
				Size = UDim2.new(1, 0, 1, 0),
				Rotation = 0
			})
			
			settleTween:Play()
		end)
	end)
end

-- Create particle effects for card rarity
function UIUtils.CreateRarityParticles(parent: GuiObject, rarity: string): ParticleEmitter?
	if UIConstants:IsMobile() then
		-- Reduced particles for mobile performance
		return nil
	end
	
	local emitter = Instance.new("ParticleEmitter")
	
	-- Configure based on rarity
	if rarity == "Legendary" then
		emitter.Rate = 25
		emitter.Color = ColorSequence.new(UIConstants.RarityColors.Legendary)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0)
		})
	elseif rarity == "Epic" then
		emitter.Rate = 15
		emitter.Color = ColorSequence.new(UIConstants.RarityColors.Epic)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 1.0),
			NumberSequenceKeypoint.new(1, 0)
		})
	else
		-- No particles for common/rare to maintain performance
		return nil
	end
	
	emitter.Lifetime = NumberRange.new(2, 5)
	emitter.LightEmission = 0.8
	emitter.Speed = NumberRange.new(2, 8)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	
	emitter.Parent = parent
	return emitter
end

-- Create responsive container with proper layout
function UIUtils.CreateResponsiveContainer(config: {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutType: string?, -- "List" or "Grid"
	Spacing: number?,
	Parent: GuiObject?
}): Frame
	
	local container = Instance.new("Frame")
	container.Size = config.Size or UDim2.new(1, 0, 1, 0)
	container.Position = config.Position or UDim2.new(0, 0, 0, 0)
	container.AnchorPoint = config.AnchorPoint or Vector2.new(0, 0)
	container.BackgroundTransparency = 1
	
	-- Add layout based on type
	local layoutType = config.LayoutType or "List"
	local spacing = config.Spacing or UIConstants.Spacing.Medium
	
	if layoutType == "List" then
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, spacing)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = container
	elseif layoutType == "Grid" then
		local layout = Instance.new("UIGridLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.CellPadding = UDim2.new(0, spacing, 0, spacing)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = container
	end
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, UIConstants.Spacing.Medium)
	padding.PaddingBottom = UDim.new(0, UIConstants.Spacing.Medium)
	padding.PaddingLeft = UDim.new(0, UIConstants.Spacing.Medium)
	padding.PaddingRight = UDim.new(0, UIConstants.Spacing.Medium)
	padding.Parent = container
	
	if config.Parent then
		container.Parent = config.Parent
	end
	
	return container
end

-- Add button press animation
function UIUtils.AddButtonAnimation(button: GuiButton)
	local function onPressed()
		local pressInfo = TweenInfo.new(UIConstants.Animation.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local pressTween = TweenService:Create(button, pressInfo, {
			Size = UDim2.new(0.95, 0, 0.95, 0)
		})
		pressTween:Play()
	end
	
	local function onReleased()
		local releaseInfo = TweenInfo.new(UIConstants.Animation.Fast, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local releaseTween = TweenService:Create(button, releaseInfo, {
			Size = UDim2.new(1, 0, 1, 0)
		})
		releaseTween:Play()
	end
	
	button.MouseButton1Down:Connect(onPressed)
	button.MouseButton1Up:Connect(onReleased)
	button.MouseLeave:Connect(onReleased)
end

return UIUtils 